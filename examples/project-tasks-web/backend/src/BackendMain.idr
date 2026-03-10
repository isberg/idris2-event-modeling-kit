module BackendMain

import Control.Monad.Reader
import Control.Monad.Trans
import Data.Buffer.Ext
import Data.IORef as IORef
import Data.List
import Data.String
import Domain.Event as Event
import Domain.JSON
import Domain.JSON.Simple
import Domain.Project as Project
import Domain.Task as Task
import EmKit.Backend.SSE
import EmKit.Runtime.Execute
import EmKit.Runtime.Query
import EmKit.Sourcing.Decider
import EmKit.Store.Core
import EmKit.Store.File as File
import EmKit.Store.Memory as Memory
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

data StorageMode = MemoryMode | FileMode String

data StoreBackend ev = UseMemory (Memory.Env String ev) | UseFile (File.Env ev)

record AppEnv ev where
  constructor MkAppEnv
  storageMode : StorageMode
  store : StoreBackend ev

ProjectTaskApp : Type -> Type -> Type
ProjectTaskApp ev a = ReaderT (AppEnv ev) IO a

findFileStorageArg : List String -> Maybe StorageMode
findFileStorageArg [] = Nothing
findFileStorageArg ("file" :: path :: _) = Just (FileMode path)
findFileStorageArg (_ :: rest) = findFileStorageArg rest

findPortArg : List String -> Maybe String
findPortArg [] = Nothing
findPortArg ("--port" :: value :: _) = Just value
findPortArg (_ :: rest) = findPortArg rest

parsePort : String -> Maybe Int
parsePort raw =
  case parseInteger (trim raw) of
    Nothing => Nothing
    Just n => if n <= 0 || n > 65535 then Nothing else Just (cast n)

isProjectStream : String -> Bool
isProjectStream streamId = isPrefixOf (unpack Event.projectPrefix) (unpack streamId)

isTaskStream : String -> Bool
isTaskStream streamId = isPrefixOf (unpack Event.taskPrefix) (unpack streamId)

isTaskForProject : String -> String -> Bool
isTaskForProject projectId streamId =
  isPrefixOf (unpack (Task.taskPrefixForProject projectId)) (unpack streamId)

runStore :
  AppEnv ev ->
  ReaderT (Memory.Env String ev) IO a ->
  ReaderT (File.Env ev) IO a ->
  IO a
runStore env memAction fileAction =
  case store env of
    UseMemory memEnv => runReaderT memEnv memAction
    UseFile fileEnv => runReaderT fileEnv fileAction

public export
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => EventStore (ReaderT (AppEnv ev) IO) String ev where
  load streamId = do
    env <- ask
    lift $ runStore env (load streamId) (load streamId)

  loadFrom streamId from = do
    env <- ask
    lift $ runStore env (loadFrom streamId from) (loadFrom streamId from)

  append streamId expected events = do
    env <- ask
    lift $ runStore env (append streamId expected events) (append streamId expected events)

public export
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => Observable (ReaderT (AppEnv ev) IO) String ev where
  subscribe streamId cb = do
    env <- ask
    case store env of
      UseMemory memEnv => do
        let wrapped : Nat -> List ev -> ReaderT (Memory.Env String ev) IO ()
            wrapped from events = lift $ runReaderT env (cb from events)
        unsub <- lift $ runReaderT memEnv (EmKit.Store.Core.subscribe {m=ReaderT (Memory.Env String ev) IO} {stream=String} {ev=ev} streamId wrapped)
        pure (do _ <- ask; lift $ runReaderT memEnv unsub)
      UseFile fileEnv => do
        let wrapped : Nat -> List ev -> ReaderT (File.Env ev) IO ()
            wrapped from events = lift $ runReaderT env (cb from events)
        unsub <- lift $ runReaderT fileEnv (EmKit.Store.Core.subscribe {m=ReaderT (File.Env ev) IO} {stream=String} {ev=ev} streamId wrapped)
        pure (do _ <- ask; lift $ runReaderT fileEnv unsub)

public export
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => ObservableCategory (ReaderT (AppEnv ev) IO) String ev where
  subscribeCategory matches cb = do
    env <- ask
    case store env of
      UseMemory memEnv => do
        let wrapped : String -> Nat -> List ev -> ReaderT (Memory.Env String ev) IO ()
            wrapped streamId from events = lift $ runReaderT env (cb streamId from events)
        unsub <- lift $ runReaderT memEnv (EmKit.Store.Core.subscribeCategory {m=ReaderT (Memory.Env String ev) IO} {stream=String} {ev=ev} matches wrapped)
        pure (do _ <- ask; lift $ runReaderT memEnv unsub)
      UseFile fileEnv => do
        let wrapped : String -> Nat -> List ev -> ReaderT (File.Env ev) IO ()
            wrapped streamId from events = lift $ runReaderT env (cb streamId from events)
        unsub <- lift $ runReaderT fileEnv (EmKit.Store.Core.subscribeCategory {m=ReaderT (File.Env ev) IO} {stream=String} {ev=ev} matches wrapped)
        pure (do _ <- ask; lift $ runReaderT fileEnv unsub)

public export
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => StreamCatalog (ReaderT (AppEnv ev) IO) String where
  listStreams = do
    env <- ask
    lift $ runStore env listStreams listStreams

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

listProjectSummariesInStore : ProjectTaskApp Event.DomainEvent (Either String (List Project.ProjectSummary))
listProjectSummariesInStore = do
  listed <-
    listProjectedSummaries
      {m=ReaderT (AppEnv Event.DomainEvent) IO}
      {stream=String}
      {event=Event.DomainEvent}
      {summary=Project.ProjectSummary}
      isProjectStream
      Project.summaryFromEvents
      (\summary => exists summary)
  pure $ case listed of
    Left err => Left (renderListStreamsErr err)
    Right summaries => Right summaries

projectResyncInStore : String -> ProjectTaskApp Event.DomainEvent (Either String (ResyncPayload Event.DomainEvent))
projectResyncInStore streamId = do
  loaded <- loadHistoryOrEmpty {m=ReaderT (AppEnv Event.DomainEvent) IO} {stream=String} {event=Event.DomainEvent} streamId
  pure $ case loaded of
    Left err => Left (renderLoadErr err)
    Right (version, events) => Right (MkResyncPayload version events)

tasksForProjectInStore : String -> ProjectTaskApp Event.DomainEvent (Either String (List Task.TaskSummary))
tasksForProjectInStore targetProjectId = do
  listed <-
    listProjectedSummaries
      {m=ReaderT (AppEnv Event.DomainEvent) IO}
      {stream=String}
      {event=Event.DomainEvent}
      {summary=Task.TaskSummary}
      isTaskStream
      Task.summaryFromEvents
      (\summary => exists summary && projectId summary == targetProjectId)
  pure $ case listed of
    Left err => Left (renderListStreamsErr err)
    Right summaries => Right summaries

taskResyncInStore : String -> ProjectTaskApp Event.DomainEvent (Either String (ResyncPayload Event.DomainEvent))
taskResyncInStore streamId = do
  loaded <- loadHistoryOrEmpty {m=ReaderT (AppEnv Event.DomainEvent) IO} {stream=String} {event=Event.DomainEvent} streamId
  pure $ case loaded of
    Left err => Left (renderLoadErr err)
    Right (version, events) => Right (MkResyncPayload version events)

executeProjectCommandInStore : String -> ExecutePayload Project.ProjectCommand -> ProjectTaskApp Event.DomainEvent (Either (RuntimeExecuteError Project.ProjectRejection) Nat)
executeProjectCommandInStore streamId payload = do
  result <- executeOnStreamExpected {m=ReaderT (AppEnv Event.DomainEvent) IO} {stream=String} {command=Project.ProjectCommand} {rejection=Project.ProjectRejection} {event=Event.DomainEvent} {state=Project.ProjectState} streamId (expectedVersion payload) (command payload)
  pure (map newVersion result)

executeTaskCommandInStore : String -> ExecutePayload Task.TaskCommand -> ProjectTaskApp Event.DomainEvent (Either (RuntimeExecuteError Task.TaskRejection) Nat)
executeTaskCommandInStore streamId payload = do
  result <- executeOnStreamExpected {m=ReaderT (AppEnv Event.DomainEvent) IO} {stream=String} {command=Task.TaskCommand} {rejection=Task.TaskRejection} {event=Event.DomainEvent} {state=Task.TaskState} streamId (expectedVersion payload) (command payload)
  pure (map newVersion result)

frameTaskDetailEvent : Nat -> Event.DomainEvent -> Buffer
frameTaskDetailEvent version event =
  let payload = SimpleToJSON.encode (the (StreamEvent Event.DomainEvent) (MkStreamEvent version event))
      frame = sseFrameText (Just (show version)) Nothing payload
  in fromString frame

frameProjectOverviewEvent : String -> Nat -> Event.DomainEvent -> Buffer
frameProjectOverviewEvent streamId version event =
  let payload = SimpleToJSON.encode (the (MultiplexedStreamEvent String Event.DomainEvent) (MkMultiplexedStreamEvent streamId version event))
      frame = sseFrameText Nothing Nothing payload
  in fromString frame

frameProjectTaskEvent : String -> Nat -> Event.DomainEvent -> Buffer
frameProjectTaskEvent streamId version event =
  let payload = SimpleToJSON.encode (the (MultiplexedStreamEvent String Event.DomainEvent) (MkMultiplexedStreamEvent streamId version event))
      frame = sseFrameText Nothing Nothing payload
  in fromString frame

subscribeProjectOverview : AppEnv Event.DomainEvent -> IORef.IORef ClientUnsubs -> String -> Publisher IO e Buffer
subscribeProjectOverview env unsubsRef clientId =
  subscribeCategoryLive env unsubsRef "project-overview" frameProjectOverviewEvent isProjectStream clientId

subscribeProjectTasks : AppEnv Event.DomainEvent -> IORef.IORef ClientUnsubs -> String -> String -> Publisher IO e Buffer
subscribeProjectTasks env unsubsRef projectId clientId =
  subscribeCategoryLive env unsubsRef ("project-tasks:" ++ projectId) frameProjectTaskEvent (isTaskForProject projectId) clientId

readProjectSummariesP : AppEnv Event.DomainEvent -> Promise Error IO (List Project.ProjectSummary)
readProjectSummariesP env = promise $ \resolve, _ => do
  result <- runReaderT env listProjectSummariesInStore
  case result of
    Left _ => resolve []
    Right summaries => resolve summaries

runProjectResyncP : AppEnv Event.DomainEvent -> String -> Promise Error IO (Either String (ResyncPayload Event.DomainEvent))
runProjectResyncP env streamId = promise $ \resolve, _ => do
  result <- runReaderT env (projectResyncInStore streamId)
  resolve result

readProjectTasksP : AppEnv Event.DomainEvent -> String -> Promise Error IO (Either String (List Task.TaskSummary))
readProjectTasksP env projectId = promise $ \resolve, _ => do
  result <- runReaderT env (tasksForProjectInStore projectId)
  resolve result

runTaskResyncP : AppEnv Event.DomainEvent -> String -> Promise Error IO (Either String (ResyncPayload Event.DomainEvent))
runTaskResyncP env streamId = promise $ \resolve, _ => do
  result <- runReaderT env (taskResyncInStore streamId)
  resolve result

runProjectExecuteP : AppEnv Event.DomainEvent -> String -> ExecutePayload Project.ProjectCommand -> Promise Error IO (Either (RuntimeExecuteError Project.ProjectRejection) Nat)
runProjectExecuteP env streamId payload = promise $ \resolve, _ => do
  result <- runReaderT env (executeProjectCommandInStore streamId payload)
  resolve result

runTaskExecuteP : AppEnv Event.DomainEvent -> String -> ExecutePayload Task.TaskCommand -> Promise Error IO (Either (RuntimeExecuteError Task.TaskRejection) Nat)
runTaskExecuteP env streamId payload = promise $ \resolve, _ => do
  result <- runReaderT env (executeTaskCommandInStore streamId payload)
  resolve result

initAppEnv : StorageMode -> IO (AppEnv Event.DomainEvent)
initAppEnv MemoryMode = do
  memEnv <- Memory.mkEnv {stream=String} {ev=Event.DomainEvent}
  pure (MkAppEnv MemoryMode (UseMemory memEnv))
initAppEnv (FileMode path) = do
  fileEnv <- File.mkEnv path
  pure (MkAppEnv (FileMode path) (UseFile fileEnv))

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
  env <- initAppEnv storageMode
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
                  let stream = subscribeStream env unsubsRef frameTaskDetailEvent taskId clientId (lastEventIdFromHeaders ctx.request.headers)
                  in pure $ MkContext ctx.request (MkResponse OK sseHeaders stream)
                else sendText ("Unknown stream: " ++ taskId) ctx >>= status BAD_REQUEST
            _ => sendText "Missing taskId or clientId." ctx >>= status BAD_REQUEST
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
