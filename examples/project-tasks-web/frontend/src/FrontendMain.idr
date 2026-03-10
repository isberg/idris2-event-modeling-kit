module FrontendMain

import Data.List
import Data.Maybe
import Data.SortedMap as SortedMap
import Data.String
import Domain.Event as Event
import Domain.JSON.Simple
import Domain.Project as Project
import Domain.Screens as Screens
import Domain.Task as Task
import EmKit.Frontend.Execute as FrontendExecute
import EmKit.Frontend.SSE as FrontendSSE
import EmKit.Frontend.Stream as FrontendStream
import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Wire.Contracts
import EmKit.Wire.JSON.Simple
import JS.Util
import JSON.Simple
import Text.HTML.Attribute as HtmlAttr
import Web.MVC
import Web.MVC.Http

%default total

record State where
  constructor MkState
  screen : Screen
  projectSummaries : SortedMap.SortedMap String Project.ProjectSummary
  selectedProject : Maybe Project.ProjectDetail
  projectTasks : SortedMap.SortedMap String Task.TaskSummary
  selectedTask : Maybe Task.TaskDetail
  createProjectTitle : String
  createTaskTitle : String
  status : String
  busy : Bool
  clientId : Maybe String

initialState : State
initialState = MkState ProjectsOverview SortedMap.empty Nothing SortedMap.empty Nothing "Alpha" "First task" "Connecting overview feed..." True Nothing

data Msg : Type where
  Initialized : Msg
  ClientIdReady : String -> Msg
  ProjectsLoaded : Either HTTPError (List Project.ProjectSummary) -> Msg
  ProjectsOverviewEventReceived : String -> Msg
  CreateProjectTitleChanged : String -> Msg
  CreateProjectClicked : Msg
  CreateProjectFinished : String -> Either HTTPError () -> Msg
  OpenProjectClicked : String -> Msg
  ProjectResyncFinished : String -> Either HTTPError (ResyncPayload Event.ProjectEvent) -> Msg
  ProjectEventReceived : String -> String -> Msg
  ProjectTasksLoaded : String -> Either HTTPError (List Task.TaskSummary) -> Msg
  ProjectTaskEventReceived : String -> String -> Msg
  BackToProjectsClicked : Msg
  CreateTaskTitleChanged : String -> Msg
  CreateTaskClicked : Msg
  CreateTaskFinished : String -> Either HTTPError () -> Msg
  OpenTaskClicked : String -> Msg
  TaskResyncFinished : String -> Either HTTPError (ResyncPayload Event.TaskEvent) -> Msg
  TaskEventReceived : String -> String -> Msg
  BackToProjectClicked : Msg
  StartTaskClicked : Msg
  StartTaskFinished : String -> Either HTTPError () -> Msg
  CompleteTaskClicked : Msg
  CompleteTaskFinished : String -> Either HTTPError () -> Msg

httpErrorMessage : HTTPError -> String
httpErrorMessage Timeout = "Request timed out."
httpErrorMessage NetworkError = "Network error. Run ./scripts/run.sh and open /static/index.html on the configured port."
httpErrorMessage (BadStatus code) = "Server returned status " ++ show code ++ "."
httpErrorMessage (JSONError _ _) = "Failed to decode JSON response."

projectsOverviewEventsUrl : String -> String
projectsOverviewEventsUrl clientId = "/api/projects/overview-events/" ++ clientId

projectResyncUrl : String -> String
projectResyncUrl projectId = "/api/projects/resync/" ++ projectId

projectEventsUrl : String -> String -> String
projectEventsUrl projectId clientId = "/api/projects/events/" ++ projectId ++ "/" ++ clientId

projectExecuteUrl : String -> String
projectExecuteUrl projectId = "/api/projects/execute/" ++ projectId

projectTasksUrl : String -> String
projectTasksUrl projectId = "/api/projects/tasks/" ++ projectId

projectTasksEventsUrl : String -> String -> String
projectTasksEventsUrl projectId clientId = "/api/projects/tasks-events/" ++ projectId ++ "/" ++ clientId

taskResyncUrl : String -> String
taskResyncUrl taskId = "/api/tasks/resync/" ++ taskId

taskEventsUrl : String -> String -> String
taskEventsUrl taskId clientId = "/api/tasks/events/" ++ taskId ++ "/" ++ clientId

taskExecuteUrl : String -> String
taskExecuteUrl taskId = "/api/tasks/execute/" ++ taskId

loadProjects : Cmd Msg
loadProjects = get "/api/projects" (ExpectJSON ProjectsLoaded)

loadProjectTasks : String -> Cmd Msg
loadProjectTasks projectId = get (projectTasksUrl projectId) (ExpectJSON (ProjectTasksLoaded projectId))

subscribeProjectsOverview : String -> Cmd Msg
subscribeProjectsOverview clientId = FrontendSSE.subscribe (projectsOverviewEventsUrl clientId) ProjectsOverviewEventReceived

subscribeProjectDetail : String -> String -> Cmd Msg
subscribeProjectDetail projectId clientId = FrontendStream.subscribeStream projectEventsUrl projectId clientId (ProjectEventReceived projectId)

closeProjectDetail : String -> String -> Cmd Msg
closeProjectDetail projectId clientId = FrontendStream.closeStream projectEventsUrl projectId clientId

subscribeProjectTasks : String -> String -> Cmd Msg
subscribeProjectTasks projectId clientId = FrontendStream.subscribeStream projectTasksEventsUrl projectId clientId (ProjectTaskEventReceived projectId)

closeProjectTasks : String -> String -> Cmd Msg
closeProjectTasks projectId clientId = FrontendStream.closeStream projectTasksEventsUrl projectId clientId

subscribeTaskDetail : String -> String -> Cmd Msg
subscribeTaskDetail taskId clientId = FrontendStream.subscribeStream taskEventsUrl taskId clientId (TaskEventReceived taskId)

closeTaskDetail : String -> String -> Cmd Msg
closeTaskDetail taskId clientId = FrontendStream.closeStream taskEventsUrl taskId clientId

getProjectResync : String -> Cmd Msg
getProjectResync projectId = FrontendExecute.getResync projectResyncUrl ProjectResyncFinished projectId

getTaskResync : String -> Cmd Msg
getTaskResync taskId = FrontendExecute.getResync taskResyncUrl TaskResyncFinished taskId

postCreateProject : String -> String -> Cmd Msg
postCreateProject projectId title = FrontendExecute.postExecute projectExecuteUrl CreateProjectFinished projectId 0 (Project.CreateProject title)

postCreateTask : String -> String -> String -> Cmd Msg
postCreateTask taskId projectId title = FrontendExecute.postExecute taskExecuteUrl CreateTaskFinished taskId 0 (Task.CreateTask projectId title)

postStartTask : String -> Nat -> Cmd Msg
postStartTask taskId currentVersion = FrontendExecute.postExecute taskExecuteUrl StartTaskFinished taskId currentVersion Task.StartTask

postCompleteTask : String -> Nat -> Cmd Msg
postCompleteTask taskId currentVersion = FrontendExecute.postExecute taskExecuteUrl CompleteTaskFinished taskId currentVersion Task.CompleteTask

statusText : State -> String
statusText s = if busy s then "Working: " ++ status s else status s

projectSummaryList : State -> List Project.ProjectSummary
projectSummaryList s = filter exists (SortedMap.values (projectSummaries s))

projectTaskList : State -> List Task.TaskSummary
projectTaskList s = filter exists (SortedMap.values (projectTasks s))

bundleForState : State -> AppBundle
bundleForState s = bundleForApp (projectSummaryList s) (selectedProject s) (projectTaskList s) (selectedTask s)

screenPolicyText : Screen -> String
screenPolicyText currentScreen =
  case dataSourcePolicy (specFor {bundle=AppBundle} currentScreen) of
    QueryOnly => "QueryOnly"
    ClientProjectionOnly => "ClientProjectionOnly"
    HybridProjection => "HybridProjection"

currentProjectId : State -> Maybe String
currentProjectId s =
  case selectedProject s of
    Just detail => Just (projectId detail)
    Nothing => map projectId (selectedTask s)

currentTaskId : State -> Maybe String
currentTaskId s = map taskId (selectedTask s)

replaceProjectSummary : Project.ProjectSummary -> State -> State
replaceProjectSummary summary s = { projectSummaries := SortedMap.insert (projectId summary) summary (projectSummaries s) } s

replaceProjectTasks : List Task.TaskSummary -> State -> State
replaceProjectTasks tasks s =
  { projectTasks := foldl (\m, summary => SortedMap.insert (taskId summary) summary m) SortedMap.empty tasks } s

replaceTaskSummary : Task.TaskSummary -> State -> State
replaceTaskSummary summary s = { projectTasks := SortedMap.insert (taskId summary) summary (projectTasks s) } s

updateProjectSummaryFromDetail : Project.ProjectDetail -> State -> State
updateProjectSummaryFromDetail detail s = replaceProjectSummary (Project.summaryFromDetail detail) s

updateTaskSummaryFromDetail : Task.TaskDetail -> State -> State
updateTaskSummaryFromDetail detail s = replaceTaskSummary (Task.summaryFromDetail detail) s

applyProjectsOverviewEvent : MultiplexedStreamEvent String Event.ProjectEvent -> State -> Either String State
applyProjectsOverviewEvent msg s =
  let sid = streamId msg
      current = fromMaybe (Project.emptyProjectSummary sid) (SortedMap.lookup sid (projectSummaries s))
  in case Project.applyProjectSummaryEvent sid (streamVersion msg) (event msg) current of
       Left err => Left err
       Right next => Right (replaceProjectSummary next s)

applyProjectTaskEvent : MultiplexedStreamEvent String Event.TaskEvent -> State -> Either String State
applyProjectTaskEvent msg s =
  let sid = streamId msg
      current = fromMaybe (Task.emptyTaskSummary sid) (SortedMap.lookup sid (projectTasks s))
  in case Task.applyTaskSummaryEvent sid (streamVersion msg) (event msg) current of
       Left err => Left err
       Right next => Right (replaceTaskSummary next s)

nextProjectId : State -> String
nextProjectId s = Project.nextProjectIdFromSummaries (projectSummaryList s)

nextTaskId : Project.ProjectDetail -> State -> String
nextTaskId detail s = Task.nextTaskIdFromSummaries (projectId detail) (projectTaskList s)

closeCurrentProjectDetail : State -> List (Cmd Msg)
closeCurrentProjectDetail s = FrontendStream.closeCurrent (currentProjectId s) (clientId s) closeProjectDetail

closeCurrentProjectTasks : State -> List (Cmd Msg)
closeCurrentProjectTasks s = FrontendStream.closeCurrent (currentProjectId s) (clientId s) closeProjectTasks

closeCurrentTaskDetail : State -> List (Cmd Msg)
closeCurrentTaskDetail s = FrontendStream.closeCurrent (currentTaskId s) (clientId s) closeTaskDetail

openProjectCommands : State -> String -> List (Cmd Msg)
openProjectCommands s projectId =
  FrontendStream.withClientId
    (clientId s)
    (FrontendSSE.requestClientId ClientIdReady)
    (\cid =>
      closeCurrentTaskDetail s
        ++ closeCurrentProjectDetail s
        ++ closeCurrentProjectTasks s
        ++ [ subscribeProjectDetail projectId cid
           , subscribeProjectTasks projectId cid
           , getProjectResync projectId
           , loadProjectTasks projectId
           ])

openTaskCommands : State -> String -> List (Cmd Msg)
openTaskCommands s taskId =
  FrontendStream.withClientId
    (clientId s)
    (FrontendSSE.requestClientId ClientIdReady)
    (\cid => closeCurrentTaskDetail s ++ [subscribeTaskDetail taskId cid, getTaskResync taskId])

renderTaskEvent : Event.TaskEvent -> String
renderTaskEvent (Event.TaskCreated projectId title) = "Created for " ++ projectId ++ ": " ++ title
renderTaskEvent Event.TaskStarted = "Started"
renderTaskEvent Event.TaskCompleted = "Completed"

projectStatusLabel : Bool -> String
projectStatusLabel = Event.renderProjectStatus

messageForAction : Action -> Msg
messageForAction CreateProjectAction = CreateProjectClicked
messageForAction (OpenProjectAction projectId) = OpenProjectClicked projectId
messageForAction BackToProjectsAction = BackToProjectsClicked
messageForAction CreateTaskAction = CreateTaskClicked
messageForAction (OpenTaskAction taskId) = OpenTaskClicked taskId
messageForAction BackToProjectAction = BackToProjectClicked
messageForAction StartTaskAction = StartTaskClicked
messageForAction CompleteTaskAction = CompleteTaskClicked

actionButton : Bool -> Action -> Node Msg
actionButton isBusy action =
  button
    [ onClick (messageForAction action)
    , disabled isBusy
    , style "padding:9px 12px; border:1px solid #3b5d7e; border-radius:10px; background:#eef5fb;"
    ]
    [ Text (renderAction action) ]

projectCard : State -> Project.ProjectSummary -> Node Msg
projectCard s summary =
  div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:18px; padding:18px; min-width:220px; flex:1;" ]
    [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;" ] [ Text (projectId summary) ]
    , h3 [ style "margin:8px 0 8px 0; font-size:26px;" ] [ Text (title summary) ]
    , div [ style "font-size:13px; opacity:0.78; margin:8px 0 14px 0;" ] [ Text (projectStatusLabel (completed summary)) ]
    , actionButton (busy s) (OpenProjectAction (projectId summary))
    ]

projectsOverviewSection : State -> Node Msg
projectsOverviewSection s =
  let cards = map (projectCard s) (projectSummaryList s) in
  div []
    [ div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:16px; padding:16px; margin-bottom:18px;" ]
        [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px; margin-bottom:4px;" ] [ Text (screenPolicyText ProjectsOverview) ]
        , h2 [ style "margin:0 0 8px 0; font-size:28px;" ] [ Text "Projects" ]
        , div [ style "display:flex; gap:10px; flex-wrap:wrap;" ]
            [ input [ onInput CreateProjectTitleChanged, HtmlAttr.value (createProjectTitle s), placeholder "new project title", style "padding:10px; border:1px solid #98aaba; border-radius:10px; min-width:240px;" ] []
            , actionButton (busy s) CreateProjectAction
            ]
        ]
    , if null cards
        then div [ style "padding:18px; background:#ffffffd9; border:1px dashed #bcc9d5; border-radius:16px;" ] [ Text "No projects yet." ]
        else div [ style "display:flex; gap:14px; flex-wrap:wrap;" ] cards
    ]

taskRow : State -> Task.TaskSummary -> Node Msg
taskRow s summary =
  div [ style "display:flex; gap:10px; align-items:center; justify-content:space-between; padding:12px 0; border-top:1px solid #e1e8ef;" ]
    [ div []
        [ div [ style "font-weight:600;" ] [ Text (title summary) ]
        , div [ style "font-size:12px; opacity:0.7;" ] [ Text (taskId summary ++ " · " ++ renderTaskStatus (status summary)) ]
        ]
    , actionButton (busy s) (OpenTaskAction (taskId summary))
    ]

projectDetailSection : State -> Project.ProjectDetail -> Node Msg
projectDetailSection s detail =
  let tasks = projectTaskList s in
  div []
    [ div [ style "display:flex; justify-content:space-between; align-items:end; gap:14px; flex-wrap:wrap; margin-bottom:18px;" ]
        [ div []
            [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;" ] [ Text (screenPolicyText ProjectDetailScreen ++ " · " ++ projectId detail) ]
            , h2 [ style "margin:6px 0 0 0; font-size:30px;" ] [ Text (title detail) ]
            , div [ style "font-size:13px; opacity:0.78; margin-top:6px;" ] [ Text (projectStatusLabel (completed detail)) ]
            ]
        , actionButton (busy s) BackToProjectsAction
        ]
    , div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:16px; padding:16px; margin-bottom:18px;" ]
        [ h3 [ style "margin:0 0 8px 0;" ] [ Text "Add Task" ]
        , div [ style "display:flex; gap:10px; flex-wrap:wrap;" ]
            [ input [ onInput CreateTaskTitleChanged, HtmlAttr.value (createTaskTitle s), placeholder "new task title", style "padding:10px; border:1px solid #98aaba; border-radius:10px; min-width:260px;" ] []
            , actionButton (busy s) CreateTaskAction
            ]
        ]
    , div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:16px; padding:16px;" ]
        [ h3 [ style "margin:0 0 4px 0;" ] [ Text "Tasks" ]
        , div [ style "font-size:12px; opacity:0.7; margin-bottom:8px;" ] [ Text (show (length tasks) ++ " visible task streams") ]
        , if null tasks
            then div [ style "padding:10px 0; opacity:0.75;" ] [ Text "No tasks yet for this project." ]
            else div [] (map (taskRow s) tasks)
        ]
    ]

historyRow : Nat -> Event.TaskEvent -> Node Msg
historyRow version event =
  div [ style "display:flex; gap:12px; padding:8px 0; border-top:1px solid #e4e9ee;" ]
    [ div [ style "font-size:12px; opacity:0.65; min-width:44px;" ] [ Text ("v" ++ show version) ]
    , div [] [ Text (renderTaskEvent event) ]
    ]

taskDetailSection : State -> Task.TaskDetail -> Node Msg
taskDetailSection s detail =
  let actions =
        BackToProjectAction
          :: (if Task.canStart detail then [StartTaskAction] else [])
          ++ (if Task.canComplete detail then [CompleteTaskAction] else [])
      rows = zipWith historyRow [1 .. length (history detail)] (history detail)
      projectLine = case selectedProject s of
        Nothing => projectId detail
        Just projectDetail => projectId detail ++ " · project " ++ projectStatusLabel (completed projectDetail)
  in div []
      [ div [ style "display:flex; justify-content:space-between; align-items:end; gap:14px; flex-wrap:wrap; margin-bottom:18px;" ]
          [ div []
              [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;" ] [ Text (screenPolicyText TaskDetailScreen ++ " · " ++ taskId detail) ]
              , h2 [ style "margin:6px 0 0 0; font-size:30px;" ] [ Text (title detail) ]
              , div [ style "font-size:13px; opacity:0.78; margin-top:6px;" ] [ Text (projectLine ++ " · " ++ renderTaskStatus (status detail)) ]
              ]
          , div [ style "display:flex; gap:10px; flex-wrap:wrap;" ] (map (actionButton (busy s)) actions)
          ]
      , div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:16px; padding:16px;" ]
          [ h3 [ style "margin:0 0 8px 0;" ] [ Text "Task History" ]
          , if null rows
              then div [ style "padding:10px 0; opacity:0.75;" ] [ Text "No task events yet." ]
              else div [] rows
          ]
      ]

overviewStatusText : State -> String
overviewStatusText s = statusText s

projectStatusText : State -> String
projectStatusText s = statusText s

taskStatusText : State -> String
taskStatusText s = statusText s

viewNodes : State -> List (Node Msg)
viewNodes s =
  [ div [ style "min-height:100vh; padding:24px; background:linear-gradient(180deg,#f6fbff 0%,#edf4f8 100%); color:#16324f; font-family:Georgia, serif;" ]
      [ div [ style "max-width:980px; margin:0 auto;" ]
          [ div [ style "display:flex; justify-content:space-between; align-items:end; gap:16px; flex-wrap:wrap; margin-bottom:18px;" ]
              [ div []
                  [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;" ] [ Text "Project/Task Example" ]
                  , h1 [ style "margin:6px 0 0 0; font-size:38px;" ] [ Text "Project Tracker" ]
                  ]
              , div [ style "font-size:13px; opacity:0.78; max-width:420px; text-align:right;" ]
                  [ Text (case screen s of
                      ProjectsOverview => overviewStatusText s
                      ProjectDetailScreen => projectStatusText s
                      TaskDetailScreen => taskStatusText s) ]
              ]
          , case screen s of
              ProjectsOverview => projectsOverviewSection s
              ProjectDetailScreen => case selectedProject s of
                Nothing => div [ style "padding:18px; background:#ffffffd9; border:1px dashed #bcc9d5; border-radius:16px;" ] [ Text "Loading project..." ]
                Just detail => projectDetailSection s detail
              TaskDetailScreen => case selectedTask s of
                Nothing => div [ style "padding:18px; background:#ffffffd9; border:1px dashed #bcc9d5; border-radius:16px;" ] [ Text "Loading task..." ]
                Just detail => taskDetailSection s detail
          ]
      ]
  ]

updateView : State -> Cmd Msg
updateView s = children Ref.Body (viewNodes s)

controller : Msg -> State -> (State, Cmd Msg)
controller Initialized s =
  let s' = { busy := True, status := "Requesting client id..." } s in
  (s', batch [updateView s', FrontendSSE.requestClientId ClientIdReady])

controller (ClientIdReady cid) s =
  let s' = { clientId := Just cid, busy := True, status := "Loading projects..." } s in
  (s', batch [updateView s', subscribeProjectsOverview cid, loadProjects])

controller (ProjectsLoaded (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (ProjectsLoaded (Right loaded)) s =
  let summaries = foldl (\m, summary => SortedMap.insert (projectId summary) summary m) SortedMap.empty loaded
      s' = { projectSummaries := summaries, busy := False, status := "Loaded " ++ show (length loaded) ++ " projects." } s in
  (s', updateView s')

controller (ProjectsOverviewEventReceived raw) s =
  case decode {a=MultiplexedStreamEvent String Event.ProjectEvent} raw of
    Left _ =>
      let s' = { busy := True, status := "Overview feed decode failed. Reloading projects..." } s in
      (s', batch [updateView s', loadProjects])
    Right msg =>
      case applyProjectsOverviewEvent msg s of
        Left err =>
          let s' = { busy := True, status := err ++ " Reloading projects..." } s in
          (s', batch [updateView s', loadProjects])
        Right next =>
          let s' = { busy := False, status := "Project overview updated from " ++ streamId msg ++ "." } next in
          (s', updateView s')

controller (CreateProjectTitleChanged value) s = ({ createProjectTitle := value } s, Cmd.noAction)

controller CreateProjectClicked s =
  let cleanTitle = trim (createProjectTitle s) in
  if cleanTitle == "" then
    let s' = { busy := False, status := "Project title is required." } s in
    (s', updateView s')
  else
    let freshId = nextProjectId s
        s' = { busy := True, status := "Creating project " ++ freshId ++ "..." } s in
    (s', batch [updateView s', postCreateProject freshId cleanTitle])

controller (CreateProjectFinished _ (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (CreateProjectFinished projectId (Right _)) s =
  let s' = { busy := False, createProjectTitle := "", status := "Project command accepted for " ++ projectId ++ "." } s in
  (s', updateView s')

controller (OpenProjectClicked projectId) s =
  let s' = { screen := ProjectDetailScreen, selectedProject := Nothing, selectedTask := Nothing, projectTasks := SortedMap.empty, busy := True, status := "Loading project " ++ projectId ++ "..." } s in
  (s', batch (updateView s' :: openProjectCommands s projectId))

controller (ProjectResyncFinished projectId (Left err)) s =
  if currentProjectId s /= Just projectId then
    (s, Cmd.noAction)
  else
    let s' = { busy := False, status := httpErrorMessage err } s in
    (s', updateView s')

controller (ProjectResyncFinished projectId (Right payload)) s =
  if currentProjectId s /= Just projectId then
    (s, Cmd.noAction)
  else
    let detail = Project.detailFromEvents projectId (version payload) (events payload)
        s' = updateProjectSummaryFromDetail detail ({ selectedProject := Just detail, busy := False, status := "Project synced: " ++ projectId } s) in
    (s', updateView s')

controller (ProjectEventReceived projectStreamId raw) s =
  case selectedProject s of
    Nothing => (s, Cmd.noAction)
    Just detail =>
      if projectStreamId /= projectId detail then
        (s, Cmd.noAction)
      else
        case decode {a=StreamEvent Event.ProjectEvent} raw of
          Left _ =>
            let s' = { busy := True, status := "Project feed decode failed. Resyncing..." } s in
            (s', batch [updateView s', getProjectResync projectStreamId])
          Right msg =>
            case Project.applyProjectDetailEvent (version msg) (event msg) detail of
              Left err =>
                let s' = { busy := True, status := err ++ " Resyncing project..." } s in
                (s', batch [updateView s', getProjectResync projectStreamId])
              Right nextDetail =>
                let s' = updateProjectSummaryFromDetail nextDetail ({ selectedProject := Just nextDetail, busy := False, status := "Project updated from live stream." } s) in
                (s', updateView s')

controller (ProjectTasksLoaded projectId (Left err)) s =
  if currentProjectId s /= Just projectId then
    (s, Cmd.noAction)
  else
    let s' = { busy := False, status := httpErrorMessage err } s in
    (s', updateView s')

controller (ProjectTasksLoaded projectId (Right loaded)) s =
  if currentProjectId s /= Just projectId then
    (s, Cmd.noAction)
  else
    let s' = replaceProjectTasks loaded ({ busy := False, status := "Loaded " ++ show (length loaded) ++ " tasks for " ++ projectId ++ "." } s) in
    (s', updateView s')

controller (ProjectTaskEventReceived projectId raw) s =
  if currentProjectId s /= Just projectId then
    (s, Cmd.noAction)
  else
    case decode {a=MultiplexedStreamEvent String Event.TaskEvent} raw of
      Left _ =>
        let s' = { busy := True, status := "Project task feed decode failed. Reloading tasks..." } s in
        (s', batch [updateView s', loadProjectTasks projectId])
      Right msg =>
        case applyProjectTaskEvent msg s of
          Left err =>
            let s' = { busy := True, status := err ++ " Reloading tasks..." } s in
            (s', batch [updateView s', loadProjectTasks projectId])
          Right next =>
            let s' = { busy := False, status := "Project tasks updated from " ++ streamId msg ++ "." } next in
            (s', updateView s')

controller BackToProjectsClicked s =
  let s' = { screen := ProjectsOverview, selectedProject := Nothing, selectedTask := Nothing, projectTasks := SortedMap.empty, busy := False, status := "Back on project overview." } s in
  (s', batch (updateView s' :: closeCurrentTaskDetail s ++ closeCurrentProjectDetail s ++ closeCurrentProjectTasks s))

controller (CreateTaskTitleChanged value) s = ({ createTaskTitle := value } s, Cmd.noAction)

controller CreateTaskClicked s =
  case selectedProject s of
    Nothing => (s, Cmd.noAction)
    Just detail =>
      let cleanTitle = trim (createTaskTitle s) in
      if cleanTitle == "" then
        let s' = { busy := False, status := "Task title is required." } s in
        (s', updateView s')
      else
        let freshId = nextTaskId detail s
            s' = { busy := True, status := "Creating task " ++ freshId ++ "..." } s in
        (s', batch [updateView s', postCreateTask freshId (projectId detail) cleanTitle])

controller (CreateTaskFinished _ (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (CreateTaskFinished taskId (Right _)) s =
  let s' = { busy := False, createTaskTitle := "", status := "Task command accepted for " ++ taskId ++ "." } s in
  (s', updateView s')

controller (OpenTaskClicked taskId) s =
  let s' = { screen := TaskDetailScreen, selectedTask := Nothing, busy := True, status := "Loading task " ++ taskId ++ "..." } s in
  (s', batch (updateView s' :: openTaskCommands s taskId))

controller (TaskResyncFinished taskId (Left err)) s =
  if currentTaskId s /= Just taskId then
    (s, Cmd.noAction)
  else
    let s' = { busy := False, status := httpErrorMessage err } s in
    (s', updateView s')

controller (TaskResyncFinished taskId (Right payload)) s =
  if currentTaskId s /= Just taskId then
    (s, Cmd.noAction)
  else
    let detail = Task.detailFromEvents taskId (version payload) (events payload)
        s' = updateTaskSummaryFromDetail detail ({ selectedTask := Just detail, busy := False, status := "Task synced: " ++ taskId } s) in
    (s', updateView s')

controller (TaskEventReceived streamId raw) s =
  case selectedTask s of
    Nothing => (s, Cmd.noAction)
    Just detail =>
      if streamId /= taskId detail then
        (s, Cmd.noAction)
      else
        case decode {a=StreamEvent Event.TaskEvent} raw of
          Left _ =>
            let s' = { busy := True, status := "Task feed decode failed. Resyncing..." } s in
            (s', batch [updateView s', getTaskResync streamId])
          Right msg =>
            case Task.applyTaskDetailEvent (version msg) (event msg) detail of
              Left err =>
                let s' = { busy := True, status := err ++ " Resyncing..." } s in
                (s', batch [updateView s', getTaskResync streamId])
              Right nextDetail =>
                let s' = updateTaskSummaryFromDetail nextDetail ({ selectedTask := Just nextDetail, busy := False, status := "Task updated from live stream." } s) in
                (s', updateView s')

controller BackToProjectClicked s =
  let s' = { screen := ProjectDetailScreen, selectedTask := Nothing, busy := False, status := "Back on project detail." } s in
  (s', batch (updateView s' :: closeCurrentTaskDetail s))

controller StartTaskClicked s =
  case selectedTask s of
    Nothing => (s, Cmd.noAction)
    Just detail =>
      let s' = { busy := True, status := "Starting " ++ taskId detail ++ "..." } s in
      (s', batch [updateView s', postStartTask (taskId detail) (version detail)])

controller (StartTaskFinished _ (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (StartTaskFinished taskId (Right _)) s =
  let s' = { busy := False, status := "Start command accepted for " ++ taskId ++ "." } s in
  (s', updateView s')

controller CompleteTaskClicked s =
  case selectedTask s of
    Nothing => (s, Cmd.noAction)
    Just detail =>
      let s' = { busy := True, status := "Completing " ++ taskId detail ++ "..." } s in
      (s', batch [updateView s', postCompleteTask (taskId detail) (version detail)])

controller (CompleteTaskFinished _ (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (CompleteTaskFinished taskId (Right _)) s =
  let s' = { busy := False, status := "Complete command accepted for " ++ taskId ++ "." } s in
  (s', updateView s')

onError : JS.Util.JSErr -> IO ()
onError = putStrLn . dispErr

covering
main : IO ()
main = runController {e=Msg, s=State} controller onError Initialized initialState
