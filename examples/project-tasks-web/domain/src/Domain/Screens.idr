module Domain.Screens

import Domain.Event
import Domain.Project
import Domain.Task
import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts

%default total

public export
record AppBundle where
  constructor MkAppBundle
  projectSummaries : List ProjectSummary
  selectedProject : Maybe ProjectDetail
  projectTasks : List TaskSummary
  selectedTask : Maybe TaskDetail

public export
data Screen = ProjectsOverview | ProjectDetailScreen | TaskDetailScreen

public export
data Action
  = CreateProjectAction
  | OpenProjectAction String
  | BackToProjectsAction
  | CreateTaskAction
  | OpenTaskAction String
  | BackToProjectAction
  | StartTaskAction
  | CompleteTaskAction

public export
data Intent
  = PromptCreateProject
  | ShowProjectDetail String
  | ShowProjectsOverview
  | PromptCreateTask
  | ShowTaskDetail String
  | ShowCurrentProject
  | RunStartTask
  | RunCompleteTask

public export
bundleForApp : List ProjectSummary -> Maybe ProjectDetail -> List TaskSummary -> Maybe TaskDetail -> AppBundle
bundleForApp = MkAppBundle

public export
renderAction : Action -> String
renderAction CreateProjectAction = "Create project"
renderAction (OpenProjectAction projectId) = "Open " ++ projectId
renderAction BackToProjectsAction = "Back to projects"
renderAction CreateTaskAction = "Create task"
renderAction (OpenTaskAction taskId) = "Open " ++ taskId
renderAction BackToProjectAction = "Back to project"
renderAction StartTaskAction = "Start task"
renderAction CompleteTaskAction = "Complete task"

public export
implementation ScreenCatalog Screen AppBundle where
  specFor ProjectsOverview = MkScreenSpec ProjectsOverview HybridProjection (\_ => True)
  specFor ProjectDetailScreen = MkScreenSpec ProjectDetailScreen HybridProjection (\bundle => case selectedProject bundle of
    Nothing => False
    Just _ => True)
  specFor TaskDetailScreen = MkScreenSpec TaskDetailScreen HybridProjection (\bundle => case selectedTask bundle of
    Nothing => False
    Just _ => True)

public export
implementation ScreenActions Screen AppBundle Action Intent where
  screenForAction CreateProjectAction = ProjectsOverview
  screenForAction (OpenProjectAction _) = ProjectsOverview
  screenForAction BackToProjectsAction = ProjectDetailScreen
  screenForAction CreateTaskAction = ProjectDetailScreen
  screenForAction (OpenTaskAction _) = ProjectDetailScreen
  screenForAction BackToProjectAction = TaskDetailScreen
  screenForAction StartTaskAction = TaskDetailScreen
  screenForAction CompleteTaskAction = TaskDetailScreen

  intentForAction CreateProjectAction = PromptCreateProject
  intentForAction (OpenProjectAction projectId) = ShowProjectDetail projectId
  intentForAction BackToProjectsAction = ShowProjectsOverview
  intentForAction CreateTaskAction = PromptCreateTask
  intentForAction (OpenTaskAction taskId) = ShowTaskDetail taskId
  intentForAction BackToProjectAction = ShowCurrentProject
  intentForAction StartTaskAction = RunStartTask
  intentForAction CompleteTaskAction = RunCompleteTask

  availableScreenActions bundle ProjectsOverview =
    CreateProjectAction :: map (OpenProjectAction . projectId) (filter exists (projectSummaries bundle))
  availableScreenActions bundle ProjectDetailScreen =
    case selectedProject bundle of
      Nothing => []
      Just _ => BackToProjectsAction :: CreateTaskAction :: map (OpenTaskAction . taskId) (filter exists (projectTasks bundle))
  availableScreenActions bundle TaskDetailScreen =
    case selectedTask bundle of
      Nothing => []
      Just detail =>
        BackToProjectAction
          :: (if canStart detail then [StartTaskAction] else [])
          ++ (if canComplete detail then [CompleteTaskAction] else [])
