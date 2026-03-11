module Frontend.Routes

import Domain.JSON.Simple
import Domain.Event as Event
import Domain.Project as Project
import Domain.Task as Task
import EmKit.Frontend.Execute as FrontendExecute
import EmKit.Frontend.SSE as FrontendSSE
import EmKit.Frontend.Stream as FrontendStream
import EmKit.Wire.Contracts
import EmKit.Wire.JSON.Simple
import Frontend.State
import JSON.Simple
import Web.MVC
import Web.MVC.Http

%default total

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

export
loadProjects : Cmd Msg
loadProjects = get "/api/projects" (ExpectJSON ProjectsLoaded)

export
loadProjectTasks : String -> Cmd Msg
loadProjectTasks projectId = get (projectTasksUrl projectId) (ExpectJSON (ProjectTasksLoaded projectId))

export
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

export
getProjectResync : String -> Cmd Msg
getProjectResync projectId = FrontendExecute.getResync projectResyncUrl ProjectResyncFinished projectId

export
getTaskResync : String -> Cmd Msg
getTaskResync taskId = FrontendExecute.getResync taskResyncUrl TaskResyncFinished taskId

export
postCreateProject : String -> String -> Cmd Msg
postCreateProject projectId title = FrontendExecute.postExecute projectExecuteUrl CreateProjectFinished projectId 0 (Project.CreateProject title)

export
postCreateTask : String -> String -> String -> Cmd Msg
postCreateTask taskId projectId title = FrontendExecute.postExecute taskExecuteUrl CreateTaskFinished taskId 0 (Task.CreateTask projectId title)

export
postStartTask : String -> Nat -> Cmd Msg
postStartTask taskId currentVersion = FrontendExecute.postExecute taskExecuteUrl StartTaskFinished taskId currentVersion Task.StartTask

export
postCompleteTask : String -> Nat -> Cmd Msg
postCompleteTask taskId currentVersion = FrontendExecute.postExecute taskExecuteUrl CompleteTaskFinished taskId currentVersion Task.CompleteTask

export
closeCurrentProjectDetail : State -> List (Cmd Msg)
closeCurrentProjectDetail s = FrontendStream.closeCurrent (currentProjectId s) (clientId s) closeProjectDetail

export
closeCurrentProjectTasks : State -> List (Cmd Msg)
closeCurrentProjectTasks s = FrontendStream.closeCurrent (currentProjectId s) (clientId s) closeProjectTasks

export
closeCurrentTaskDetail : State -> List (Cmd Msg)
closeCurrentTaskDetail s = FrontendStream.closeCurrent (currentTaskId s) (clientId s) closeTaskDetail

export
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

export
openTaskCommands : State -> String -> List (Cmd Msg)
openTaskCommands s taskId =
  FrontendStream.withClientId
    (clientId s)
    (FrontendSSE.requestClientId ClientIdReady)
    (\cid => closeCurrentTaskDetail s ++ [subscribeTaskDetail taskId cid, getTaskResync taskId])
