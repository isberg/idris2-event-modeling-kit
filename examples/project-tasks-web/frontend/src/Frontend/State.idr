module Frontend.State

import Data.List
import Data.Maybe
import Data.SortedMap as SortedMap
import Domain.Event as Event
import Domain.Project as Project
import Domain.Screens as Screens
import Domain.Task as Task
import EmKit.Wire.Contracts
import Web.MVC.Http

%default total

public export
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

export
initialState : State
initialState = MkState ProjectsOverview SortedMap.empty Nothing SortedMap.empty Nothing "Alpha" "First task" "Connecting overview feed..." True Nothing

public export
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

export
httpErrorMessage : HTTPError -> String
httpErrorMessage Timeout = "Request timed out."
httpErrorMessage NetworkError = "Network error. Run ./scripts/run.sh and open /static/index.html on the configured port."
httpErrorMessage (BadStatus code) = "Server returned status " ++ show code ++ "."
httpErrorMessage (JSONError _ _) = "Failed to decode JSON response."

export
statusText : State -> String
statusText s = if busy s then "Working: " ++ status s else status s

export
projectSummaryList : State -> List Project.ProjectSummary
projectSummaryList s = filter exists (SortedMap.values (projectSummaries s))

export
projectTaskList : State -> List Task.TaskSummary
projectTaskList s = filter exists (SortedMap.values (projectTasks s))

export
bundleForState : State -> AppBundle
bundleForState s = bundleForApp (projectSummaryList s) (selectedProject s) (projectTaskList s) (selectedTask s)

export
currentProjectId : State -> Maybe String
currentProjectId s =
  case selectedProject s of
    Just detail => Just (projectId detail)
    Nothing => map projectId (selectedTask s)

export
currentTaskId : State -> Maybe String
currentTaskId s = map taskId (selectedTask s)

export
replaceProjectSummaries : List Project.ProjectSummary -> State -> State
replaceProjectSummaries loaded s =
  { projectSummaries := foldl (\m, summary => SortedMap.insert (projectId summary) summary m) SortedMap.empty loaded } s

export
replaceProjectSummary : Project.ProjectSummary -> State -> State
replaceProjectSummary summary s = { projectSummaries := SortedMap.insert (projectId summary) summary (projectSummaries s) } s

export
replaceProjectTasks : List Task.TaskSummary -> State -> State
replaceProjectTasks tasks s =
  { projectTasks := foldl (\m, summary => SortedMap.insert (taskId summary) summary m) SortedMap.empty tasks } s

export
replaceTaskSummary : Task.TaskSummary -> State -> State
replaceTaskSummary summary s = { projectTasks := SortedMap.insert (taskId summary) summary (projectTasks s) } s

export
updateProjectSummaryFromDetail : Project.ProjectDetail -> State -> State
updateProjectSummaryFromDetail detail s = replaceProjectSummary (Project.summaryFromDetail detail) s

export
updateTaskSummaryFromDetail : Task.TaskDetail -> State -> State
updateTaskSummaryFromDetail detail s = replaceTaskSummary (Task.summaryFromDetail detail) s

export
applyProjectsOverviewEvent : MultiplexedStreamEvent String Event.ProjectEvent -> State -> Either String State
applyProjectsOverviewEvent msg s =
  let sid = streamId msg
      current = fromMaybe (Project.emptyProjectSummary sid) (SortedMap.lookup sid (projectSummaries s))
  in case Project.applyProjectSummaryEvent sid (streamVersion msg) (event msg) current of
       Left err => Left err
       Right next => Right (replaceProjectSummary next s)

export
applyProjectTaskEvent : MultiplexedStreamEvent String Event.TaskEvent -> State -> Either String State
applyProjectTaskEvent msg s =
  let sid = streamId msg
      current = fromMaybe (Task.emptyTaskSummary sid) (SortedMap.lookup sid (projectTasks s))
  in case Task.applyTaskSummaryEvent sid (streamVersion msg) (event msg) current of
       Left err => Left err
       Right next => Right (replaceTaskSummary next s)

export
nextProjectId : State -> String
nextProjectId s = Project.nextProjectIdFromSummaries (projectSummaryList s)

export
nextTaskId : Project.ProjectDetail -> State -> String
nextTaskId detail s = Task.nextTaskIdFromSummaries (projectId detail) (projectTaskList s)
