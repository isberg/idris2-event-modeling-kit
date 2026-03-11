module BackendMain

import Control.Monad.Reader
import Data.Buffer.Ext
import Data.IORef as IORef
import Data.List
import Data.String
import EmKit.Backend.SSE
import EmKit.Backend.StoreApp
import Domain.Automation as Automation
import Domain.Event as Event
import Domain.JSON
import Domain.JSON.Simple
import Domain.Project as Project
import Domain.Task as Task
import Domain.Translation as Translation
import EmKit.Modeling.Pattern.Translation
import EmKit.Runtime.Execute
import EmKit.Runtime.Query
import EmKit.Sourcing.Decider
import EmKit.Store.Core
import EmKit.Stream.SSE
import EmKit.Wire.Contracts
import EmKit.Wire.JSON
import EmKit.Wire.JSON.Simple
import JSON as StdJSON
import JSON.Simple.FromJSON as SimpleFromJSON
import JSON.Simple.ToJSON as SimpleToJSON
import Promise
import System
import System.Directory
import TyTTP
import TyTTP.Adapter.Node.HTTP
import TyTTP.Adapter.Node.Static
import TyTTP.HTTP
import TyTTP.HTTP.Consumer.JSON
import TyTTP.URL

%default covering
%hide JSON.Parser.JSON

ProjectTaskApp : Type -> Type -> Type
ProjectTaskApp ev a = ReaderT (StoreAppEnv ev) IO a

isProjectStream : String -> Bool
isProjectStream streamId = isPrefixOf (unpack Event.projectPrefix) (unpack streamId)

isTaskStream : String -> Bool
isTaskStream streamId = isPrefixOf (unpack Event.taskPrefix) (unpack streamId)

isTaskForProject : String -> String -> Bool
isTaskForProject projectId streamId =
  isPrefixOf (unpack (Task.taskPrefixForProject projectId)) (unpack streamId)

findHeader : String -> List (String, String) -> Maybe String
findHeader _ [] = Nothing
findHeader wanted ((key, value) :: rest) =
  if key == wanted then Just value else findHeader wanted rest

parseEventIdHeader : String -> Maybe Nat
parseEventIdHeader raw =
  case parseInteger (trim raw) of
    Nothing => Nothing
    Just n => if n < 0 then Nothing else Just (cast n)

lastEventIdFromHeaders : List (String, String) -> Maybe Nat
lastEventIdFromHeaders headers =
  case findHeader "last-event-id" headers of
    Nothing => Nothing
    Just raw => parseEventIdHeader raw

renderLoadErr : LoadErr -> String
renderLoadErr NoStream = "Stream does not exist."
renderLoadErr Corrupt = "Stored events are corrupt."
renderLoadErr IOLoadError = "File error while loading stream."

renderAppendErr : AppendErr -> String
renderAppendErr Conflict = "Expected version conflict."
renderAppendErr IOAppendError = "File error while appending events."

renderListStreamsErr : ListStreamsErr -> String
renderListStreamsErr IOListStreamsError = "File error while listing streams."

renderProjectedSummaryErr : ProjectedSummaryError -> String
renderProjectedSummaryErr (ProjectedSummaryListFailed err) = renderListStreamsErr err
renderProjectedSummaryErr (ProjectedSummaryLoadFailed err) = renderLoadErr err

renderRuntimeErr : (rejection -> String) -> RuntimeExecuteError rejection -> String
renderRuntimeErr renderRejection (RuntimeRejected rejection) = renderRejection rejection
renderRuntimeErr _ RuntimeConflict = renderAppendErr Conflict
renderRuntimeErr _ (RuntimeLoadFailed err) = renderLoadErr err
renderRuntimeErr _ (RuntimeAppendFailed err) = renderAppendErr err

runtimeStatus : RuntimeExecuteError rejection -> Status
runtimeStatus RuntimeConflict = CONFLICT
runtimeStatus (RuntimeRejected _) = BAD_REQUEST
runtimeStatus (RuntimeLoadFailed _) = INTERNAL_SERVER_ERROR
runtimeStatus (RuntimeAppendFailed _) = INTERNAL_SERVER_ERROR

data TaskIntakeError
  = TaskIntakeViewLoadFailed String
  | TaskIntakeRejected Translation.TaskIntakeRejection
  | TaskIntakeExecuteFailed (RuntimeExecuteError Task.TaskRejection)

renderTaskIntakeErr : TaskIntakeError -> String
renderTaskIntakeErr (TaskIntakeViewLoadFailed err) = err
renderTaskIntakeErr (TaskIntakeRejected rejection) = Translation.renderTaskIntakeRejection rejection
renderTaskIntakeErr (TaskIntakeExecuteFailed err) = renderRuntimeErr Task.renderTaskRejection err

taskIntakeStatus : TaskIntakeError -> Status
taskIntakeStatus (TaskIntakeViewLoadFailed _) = INTERNAL_SERVER_ERROR
taskIntakeStatus (TaskIntakeRejected (Translation.IntakeProjectMissing _)) = NOT_FOUND
taskIntakeStatus (TaskIntakeRejected Translation.IntakeEmptyTaskTitle) = BAD_REQUEST
taskIntakeStatus (TaskIntakeExecuteFailed err) = runtimeStatus err

projectEventFromStored : Event.StoredEvent -> Either LoadErr Event.ProjectEvent
projectEventFromStored (Event.StoredProject event) = Right event
projectEventFromStored (Event.StoredTask _) = Left Corrupt

taskEventFromStored : Event.StoredEvent -> Either LoadErr Event.TaskEvent
taskEventFromStored (Event.StoredTask event) = Right event
taskEventFromStored (Event.StoredProject _) = Left Corrupt

wrapProjectEvent : Event.ProjectEvent -> Event.StoredEvent
wrapProjectEvent = Event.StoredProject

wrapTaskEvent : Event.TaskEvent -> Event.StoredEvent
wrapTaskEvent = Event.StoredTask

listProjectSummariesInStore : ProjectTaskApp Event.StoredEvent (Either String (List Project.ProjectSummary))
listProjectSummariesInStore = do
  listed <-
    listMappedProjectedSummaries
      {m=ReaderT (StoreAppEnv Event.StoredEvent) IO}
      {stream=String}
      {storedEvent=Event.StoredEvent}
      {localEvent=Event.ProjectEvent}
      {summary=Project.ProjectSummary}
      projectEventFromStored
      isProjectStream
      Project.summaryFromEvents
      exists
  pure $
    case listed of
      Left err => Left (renderProjectedSummaryErr err)
      Right summaries => Right summaries

findExistingProjectSummary : String -> List Project.ProjectSummary -> Maybe Project.ProjectSummary
findExistingProjectSummary targetId [] = Nothing
findExistingProjectSummary targetId (summary :: rest) =
  if projectId summary == targetId && exists summary
    then Just summary
    else findExistingProjectSummary targetId rest

projectResyncInStore : String -> ProjectTaskApp Event.StoredEvent (Either String (ResyncPayload Event.ProjectEvent))
projectResyncInStore streamId = do
  loaded <- loadMappedHistoryOrEmpty {m=ReaderT (StoreAppEnv Event.StoredEvent) IO} {stream=String} {storedEvent=Event.StoredEvent} {localEvent=Event.ProjectEvent} projectEventFromStored streamId
  pure $ case loaded of
    Left err => Left (renderLoadErr err)
    Right (version, events) => Right (MkResyncPayload version events)

tasksForProjectInStore : String -> ProjectTaskApp Event.StoredEvent (Either String (List Task.TaskSummary))
tasksForProjectInStore targetProjectId = do
  listed <-
    listMappedProjectedSummaries
      {m=ReaderT (StoreAppEnv Event.StoredEvent) IO}
      {stream=String}
      {storedEvent=Event.StoredEvent}
      {localEvent=Event.TaskEvent}
      {summary=Task.TaskSummary}
      taskEventFromStored
      (isTaskForProject targetProjectId)
      Task.summaryFromEvents
      exists
  pure $
    case listed of
      Left err => Left (renderProjectedSummaryErr err)
      Right summaries => Right summaries

taskIntakeViewInStore : Translation.TaskIntakeSignal -> ProjectTaskApp Event.StoredEvent (Either String Translation.TaskIntakeView)
taskIntakeViewInStore signal = do
  projects <- listProjectSummariesInStore
  tasks <- tasksForProjectInStore (projectRef signal)
  pure $
    case (projects, tasks) of
      (Left err, _) => Left err
      (_, Left err) => Left err
      (Right projectSummaries, Right taskSummaries) =>
        Right (Translation.MkTaskIntakeView (findExistingProjectSummary (projectRef signal) projectSummaries) taskSummaries)

taskResyncInStore : String -> ProjectTaskApp Event.StoredEvent (Either String (ResyncPayload Event.TaskEvent))
taskResyncInStore streamId = do
  loaded <- loadMappedHistoryOrEmpty {m=ReaderT (StoreAppEnv Event.StoredEvent) IO} {stream=String} {storedEvent=Event.StoredEvent} {localEvent=Event.TaskEvent} taskEventFromStored streamId
  pure $ case loaded of
    Left err => Left (renderLoadErr err)
    Right (version, events) => Right (MkResyncPayload version events)

runProjectAutomation : String -> ProjectTaskApp Event.StoredEvent ()
runProjectAutomation projectId = do
  projectLoaded <- loadMappedHistoryOrEmpty {m=ReaderT (StoreAppEnv Event.StoredEvent) IO} {stream=String} {storedEvent=Event.StoredEvent} {localEvent=Event.ProjectEvent} projectEventFromStored projectId
  tasksLoaded <- tasksForProjectInStore projectId
  case (projectLoaded, tasksLoaded) of
    (Right (projectVersion, projectEvents), Right taskSummaries) =>
      let detail = Project.detailFromEvents projectId projectVersion projectEvents
          policyView = Automation.projectCompletionView detail taskSummaries
      in case Automation.automatedProjectCommand policyView of
          Nothing => pure ()
          Just cmd => do
            _ <- executeMappedOnStreamExpected {m=ReaderT (StoreAppEnv Event.StoredEvent) IO} {stream=String} {command=Project.ProjectCommand} {rejection=Project.ProjectRejection} {storedEvent=Event.StoredEvent} {localEvent=Event.ProjectEvent} {state=Project.ProjectModel} projectEventFromStored wrapProjectEvent projectId projectVersion cmd
            pure ()
    _ => pure ()

executeProjectCommandInStore : String -> ExecutePayload Project.ProjectCommand -> ProjectTaskApp Event.StoredEvent (Either (RuntimeExecuteError Project.ProjectRejection) Nat)
executeProjectCommandInStore streamId payload = do
  result <- executeMappedOnStreamExpected {m=ReaderT (StoreAppEnv Event.StoredEvent) IO} {stream=String} {command=Project.ProjectCommand} {rejection=Project.ProjectRejection} {storedEvent=Event.StoredEvent} {localEvent=Event.ProjectEvent} {state=Project.ProjectModel} projectEventFromStored wrapProjectEvent streamId (expectedVersion payload) (command payload)
  pure (map newVersion result)

executeTaskCommandInStore : String -> ExecutePayload Task.TaskCommand -> ProjectTaskApp Event.StoredEvent (Either (RuntimeExecuteError Task.TaskRejection) Nat)
executeTaskCommandInStore streamId payload = do
  let MkExecutePayload expected cmd = payload
  result <- executeMappedOnStreamExpected {m=ReaderT (StoreAppEnv Event.StoredEvent) IO} {stream=String} {command=Task.TaskCommand} {rejection=Task.TaskRejection} {storedEvent=Event.StoredEvent} {localEvent=Event.TaskEvent} {state=Task.TaskModel} taskEventFromStored wrapTaskEvent streamId expected cmd
  case result of
    Left err => pure (Left err)
    Right success => do
      case emittedEvents success of
        [] => pure ()
        (Event.TaskCreated projectId _ :: _) => runProjectAutomation projectId
        (_ :: _) =>
          case resultingState success of
            Task.MkTaskModel True projectId _ _ => runProjectAutomation projectId
            _ => pure ()
      pure (Right (newVersion success))

executeTaskIntakeInStore : Translation.TaskIntakeSignal -> ProjectTaskApp Event.StoredEvent (Either TaskIntakeError Translation.TaskIntakeAccepted)
executeTaskIntakeInStore signal = do
  viewResult <- taskIntakeViewInStore signal
  case viewResult of
    Left err => pure (Left (TaskIntakeViewLoadFailed err))
    Right intakeView =>
      case translate (Translation.MkTaskIntakeInput signal intakeView) of
        Left rejection => pure (Left (TaskIntakeRejected rejection))
        Right translated => do
          let Translation.MkTranslatedTaskCommand targetTaskId targetCommand = translated
          result <- executeTaskCommandInStore targetTaskId (MkExecutePayload 0 targetCommand)
          pure $
            case result of
              Left err => Left (TaskIntakeExecuteFailed err)
              Right _ => Right (Translation.acceptedFromTranslation translated)

frameProjectDetailEvent : Nat -> Event.ProjectEvent -> Buffer
frameProjectDetailEvent version event =
  let payload = SimpleToJSON.encode (the (StreamEvent Event.ProjectEvent) (MkStreamEvent version event))
      frame = sseFrameText (Just (show version)) Nothing payload
  in fromString frame

frameTaskDetailEvent : Nat -> Event.TaskEvent -> Buffer
frameTaskDetailEvent version event =
  let payload = SimpleToJSON.encode (the (StreamEvent Event.TaskEvent) (MkStreamEvent version event))
      frame = sseFrameText (Just (show version)) Nothing payload
  in fromString frame

frameProjectOverviewEvent : String -> Nat -> Event.ProjectEvent -> Buffer
frameProjectOverviewEvent streamId version event =
  let payload = SimpleToJSON.encode (the (MultiplexedStreamEvent String Event.ProjectEvent) (MkMultiplexedStreamEvent streamId version event))
      frame = sseFrameText Nothing Nothing payload
  in fromString frame

frameProjectTaskEvent : String -> Nat -> Event.TaskEvent -> Buffer
frameProjectTaskEvent streamId version event =
  let payload = SimpleToJSON.encode (the (MultiplexedStreamEvent String Event.TaskEvent) (MkMultiplexedStreamEvent streamId version event))
      frame = sseFrameText Nothing Nothing payload
  in fromString frame

subscribeProjectOverview : StoreAppEnv Event.StoredEvent -> IORef.IORef ClientUnsubs -> String -> Publisher IO e Buffer
subscribeProjectOverview env unsubsRef clientId =
  subscribeMappedCategoryLive env unsubsRef "project-overview" frameProjectOverviewEvent projectEventFromStored isProjectStream clientId

subscribeProjectDetail : StoreAppEnv Event.StoredEvent -> IORef.IORef ClientUnsubs -> String -> String -> Maybe Nat -> Publisher IO e Buffer
subscribeProjectDetail env unsubsRef projectId clientId maybeLastEventId =
  subscribeMappedStream env unsubsRef projectEventFromStored frameProjectDetailEvent projectId clientId maybeLastEventId

subscribeProjectTasks : StoreAppEnv Event.StoredEvent -> IORef.IORef ClientUnsubs -> String -> String -> Publisher IO e Buffer
subscribeProjectTasks env unsubsRef projectId clientId =
  subscribeMappedCategoryLive env unsubsRef ("project-tasks:" ++ projectId) frameProjectTaskEvent taskEventFromStored (isTaskForProject projectId) clientId

subscribeTaskDetail : StoreAppEnv Event.StoredEvent -> IORef.IORef ClientUnsubs -> String -> String -> Maybe Nat -> Publisher IO e Buffer
subscribeTaskDetail env unsubsRef taskId clientId maybeLastEventId =
  subscribeMappedStream env unsubsRef taskEventFromStored frameTaskDetailEvent taskId clientId maybeLastEventId

readProjectSummariesP : StoreAppEnv Event.StoredEvent -> Promise Error IO (List Project.ProjectSummary)
readProjectSummariesP env = promise $ \resolve, _ => do
  result <- runReaderT env listProjectSummariesInStore
  case result of
    Left _ => resolve []
    Right summaries => resolve summaries

runProjectResyncP : StoreAppEnv Event.StoredEvent -> String -> Promise Error IO (Either String (ResyncPayload Event.ProjectEvent))
runProjectResyncP env streamId = promise $ \resolve, _ => do
  result <- runReaderT env (projectResyncInStore streamId)
  resolve result

readProjectTasksP : StoreAppEnv Event.StoredEvent -> String -> Promise Error IO (Either String (List Task.TaskSummary))
readProjectTasksP env projectId = promise $ \resolve, _ => do
  result <- runReaderT env (tasksForProjectInStore projectId)
  resolve result

runTaskResyncP : StoreAppEnv Event.StoredEvent -> String -> Promise Error IO (Either String (ResyncPayload Event.TaskEvent))
runTaskResyncP env streamId = promise $ \resolve, _ => do
  result <- runReaderT env (taskResyncInStore streamId)
  resolve result

runProjectExecuteP : StoreAppEnv Event.StoredEvent -> String -> ExecutePayload Project.ProjectCommand -> Promise Error IO (Either (RuntimeExecuteError Project.ProjectRejection) Nat)
runProjectExecuteP env streamId payload = promise $ \resolve, _ => do
  result <- runReaderT env (executeProjectCommandInStore streamId payload)
  resolve result

runTaskExecuteP : StoreAppEnv Event.StoredEvent -> String -> ExecutePayload Task.TaskCommand -> Promise Error IO (Either (RuntimeExecuteError Task.TaskRejection) Nat)
runTaskExecuteP env streamId payload = promise $ \resolve, _ => do
  result <- runReaderT env (executeTaskCommandInStore streamId payload)
  resolve result

runTaskIntakeP : StoreAppEnv Event.StoredEvent -> Translation.TaskIntakeSignal -> Promise Error IO (Either TaskIntakeError Translation.TaskIntakeAccepted)
runTaskIntakeP env signal = promise $ \resolve, _ => do
  result <- runReaderT env (executeTaskIntakeInStore signal)
  resolve result


covering
main : IO ()
main = do
  args <- getArgs
  serverPort <- case findPortArg args of
    Nothing => pure (the Int 3000)
    Just raw =>
      case parsePort raw of
        Nothing => do
          putStrLn ("Invalid --port value: " ++ raw ++ ". Expected integer in range 1..65535.")
          exitFailure
        Just port => pure port
  let storageMode = maybe MemoryMode id (findFileStorageArg args)
  http <- HTTP.require
  current <- currentDir
  folder <- pure (maybe "." id current)
  env <- initStoreAppEnv storageMode
  unsubsRef <- IORef.newIORef emptyClientUnsubs
  let options : TyTTP.Adapter.Node.HTTP.Options Error
      options = { listenOptions := { port := Just serverPort } Listen.defaultOptions } defaultOptions
  _ <- HTTP.listen http options
    $ parseUrl' (const $ sendText "URL has invalid format" >=> status BAD_REQUEST) {m = Promise Error IO}
    $ routes' (sendText "Not Found" >=> status NOT_FOUND)
      [ get $ pattern "/" $ \ctx => sendText "Use /static/index.html" ctx >>= status OK
      , get $ pattern "/health" $ \ctx =>
          sendText "OK" ctx >>= status OK
      , get $ pattern "/static/*" :> hStatic "\{folder}/static/" $ flip $ \ctx =>
          \case
            StatError _ =>
              sendText "File error while serving static content." ctx >>= status INTERNAL_SERVER_ERROR
            NotAFile path =>
              sendText ("Could not find file: " ++ path) ctx >>= status NOT_FOUND
      , get $ pattern "/api/projects" $ \ctx => do
          summaries <- liftPromise $ readProjectSummariesP env
          sendText (SimpleToJSON.encode summaries) ctx >>= status OK
      , get $ pattern "/api/projects/overview-events/{clientId}" $ \ctx =>
          case lookup "clientId" ctx.request.url.path.params of
            Nothing => sendText "Missing clientId." ctx >>= status BAD_REQUEST
            Just clientId => pure $ MkContext ctx.request (MkResponse OK sseHeaders (subscribeProjectOverview env unsubsRef clientId))
      , get $ pattern "/api/projects/resync/{projectId}" $ \ctx =>
          case lookup "projectId" ctx.request.url.path.params of
            Nothing => sendText "Missing projectId." ctx >>= status BAD_REQUEST
            Just projectId =>
              if isProjectStream projectId
                then do
                  result <- liftPromise $ runProjectResyncP env projectId
                  case result of
                    Left err => sendText err ctx >>= status INTERNAL_SERVER_ERROR
                    Right payload => sendText (SimpleToJSON.encode payload) ctx >>= status OK
                else sendText ("Unknown stream: " ++ projectId) ctx >>= status BAD_REQUEST
      , get $ pattern "/api/projects/events/{projectId}/{clientId}" $ \ctx =>
          case (lookup "projectId" ctx.request.url.path.params, lookup "clientId" ctx.request.url.path.params) of
            (Just projectId, Just clientId) =>
              if isProjectStream projectId
                then
                  let stream = subscribeProjectDetail env unsubsRef projectId clientId (lastEventIdFromHeaders ctx.request.headers)
                  in pure $ MkContext ctx.request (MkResponse OK sseHeaders stream)
                else sendText ("Unknown stream: " ++ projectId) ctx >>= status BAD_REQUEST
            _ => sendText "Missing projectId or clientId." ctx >>= status BAD_REQUEST
      , post
          $ pattern "/api/projects/execute/{projectId}"
          $ consumes' [JSON] {a = ExecutePayload Project.ProjectCommand}
              (\ctx => sendText "Content cannot be parsed." ctx >>= status BAD_REQUEST)
              (\ctx =>
                case lookup "projectId" ctx.request.url.path.params of
                  Nothing => sendText "Missing projectId." ctx >>= status BAD_REQUEST
                  Just projectId =>
                    if isProjectStream projectId
                      then do
                        result <- liftPromise $ runProjectExecuteP env projectId ctx.request.body
                        case result of
                          Left err => sendText (renderRuntimeErr Project.renderProjectRejection err) ctx >>= status (runtimeStatus err)
                          Right _ => sendText "OK" ctx >>= status OK
                      else sendText ("Unknown stream: " ++ projectId) ctx >>= status BAD_REQUEST)
      , get $ pattern "/api/projects/tasks/{projectId}" $ \ctx =>
          case lookup "projectId" ctx.request.url.path.params of
            Nothing => sendText "Missing projectId." ctx >>= status BAD_REQUEST
            Just projectId =>
              if isProjectStream projectId
                then do
                  result <- liftPromise $ readProjectTasksP env projectId
                  case result of
                    Left err => sendText err ctx >>= status INTERNAL_SERVER_ERROR
                    Right payload => sendText (SimpleToJSON.encode payload) ctx >>= status OK
                else sendText ("Unknown project stream: " ++ projectId) ctx >>= status BAD_REQUEST
      , get $ pattern "/api/projects/tasks-events/{projectId}/{clientId}" $ \ctx =>
          case (lookup "projectId" ctx.request.url.path.params, lookup "clientId" ctx.request.url.path.params) of
            (Just projectId, Just clientId) =>
              if isProjectStream projectId
                then pure $ MkContext ctx.request (MkResponse OK sseHeaders (subscribeProjectTasks env unsubsRef projectId clientId))
                else sendText ("Unknown project stream: " ++ projectId) ctx >>= status BAD_REQUEST
            _ => sendText "Missing projectId or clientId." ctx >>= status BAD_REQUEST
      , get $ pattern "/api/tasks/resync/{taskId}" $ \ctx =>
          case lookup "taskId" ctx.request.url.path.params of
            Nothing => sendText "Missing taskId." ctx >>= status BAD_REQUEST
            Just taskId =>
              if isTaskStream taskId
                then do
                  result <- liftPromise $ runTaskResyncP env taskId
                  case result of
                    Left err => sendText err ctx >>= status INTERNAL_SERVER_ERROR
                    Right payload => sendText (SimpleToJSON.encode payload) ctx >>= status OK
                else sendText ("Unknown stream: " ++ taskId) ctx >>= status BAD_REQUEST
      , get $ pattern "/api/tasks/events/{taskId}/{clientId}" $ \ctx =>
          case (lookup "taskId" ctx.request.url.path.params, lookup "clientId" ctx.request.url.path.params) of
            (Just taskId, Just clientId) =>
              if isTaskStream taskId
                then
                  let stream = subscribeTaskDetail env unsubsRef taskId clientId (lastEventIdFromHeaders ctx.request.headers)
                  in pure $ MkContext ctx.request (MkResponse OK sseHeaders stream)
                else sendText ("Unknown stream: " ++ taskId) ctx >>= status BAD_REQUEST
            _ => sendText "Missing taskId or clientId." ctx >>= status BAD_REQUEST
      , post
          $ pattern "/api/inbox/tasks"
          $ consumes' [JSON] {a = Translation.TaskIntakeSignal}
              (\ctx => sendText "Content cannot be parsed." ctx >>= status BAD_REQUEST)
              (\ctx => do
                result <- liftPromise $ runTaskIntakeP env ctx.request.body
                case result of
                  Left err => sendText (renderTaskIntakeErr err) ctx >>= status (taskIntakeStatus err)
                  Right accepted => sendText (SimpleToJSON.encode accepted) ctx >>= status OK)
      , post
          $ pattern "/api/tasks/execute/{taskId}"
          $ consumes' [JSON] {a = ExecutePayload Task.TaskCommand}
              (\ctx => sendText "Content cannot be parsed." ctx >>= status BAD_REQUEST)
              (\ctx =>
                case lookup "taskId" ctx.request.url.path.params of
                  Nothing => sendText "Missing taskId." ctx >>= status BAD_REQUEST
                  Just taskId =>
                    if isTaskStream taskId
                      then do
                        result <- liftPromise $ runTaskExecuteP env taskId ctx.request.body
                        case result of
                          Left err => sendText (renderRuntimeErr Task.renderTaskRejection err) ctx >>= status (runtimeStatus err)
                          Right _ => sendText "OK" ctx >>= status OK
                      else sendText ("Unknown stream: " ++ taskId) ctx >>= status BAD_REQUEST)
      ]
  case storageMode of
    MemoryMode => putStrLn ("Project-task web backend online at port " ++ show serverPort ++ " (memory mode).")
    FileMode path => putStrLn ("Project-task web backend online at port " ++ show serverPort ++ " (file mode: " ++ path ++ ").")
