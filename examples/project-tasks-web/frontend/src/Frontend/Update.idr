module Frontend.Update

import Data.SortedMap as SortedMap
import Data.String
import Domain.JSON.Simple
import Domain.Event as Event
import Domain.Project as Project
import Domain.Screens as Screens
import Domain.Task as Task
import EmKit.Frontend.SSE as FrontendSSE
import EmKit.Wire.Contracts
import EmKit.Wire.JSON.Simple
import Frontend.Routes
import Frontend.State
import Frontend.View
import JSON.Simple
import Web.MVC
import Web.MVC.Http

%default total

export
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
  let s' = replaceProjectSummaries loaded ({ busy := False, status := "Loaded " ++ show (length loaded) ++ " projects." } s) in
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
