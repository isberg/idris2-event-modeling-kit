module Domain.Routing

import Domain.Project as Project
import Domain.Task as Task
import Domain.Translation as Translation

%default total

public export
record TaskIntakeRoutingView where
  constructor MkTaskIntakeRoutingView
  projectSummary : Maybe Project.ProjectSummary
  existingTasks : List Task.TaskSummary

public export
data TaskIntakeRoutingRejection
  = IntakeProjectMissing String

public export
renderTaskIntakeRoutingRejection : TaskIntakeRoutingRejection -> String
renderTaskIntakeRoutingRejection (IntakeProjectMissing projectId) =
  "project does not exist: " ++ projectId

public export
record RoutedTaskIntake where
  constructor MkRoutedTaskIntake
  taskId : String
  command : Task.TaskCommand

public export
record TaskIntakeAccepted where
  constructor MkTaskIntakeAccepted
  taskId : String
  projectId : String
  acceptedTitle : String

public export
acceptedFromRoutedTaskIntake : RoutedTaskIntake -> TaskIntakeAccepted
acceptedFromRoutedTaskIntake routed =
  case command routed of
    Task.CreateTask projectId title => MkTaskIntakeAccepted (taskId routed) projectId title
    _ => MkTaskIntakeAccepted (taskId routed) "" ""

public export
routeTaskIntake :
  Translation.TaskIntakeIntent ->
  TaskIntakeRoutingView ->
  Either TaskIntakeRoutingRejection RoutedTaskIntake
routeTaskIntake intent routingView =
  case projectSummary routingView of
    Nothing => Left (IntakeProjectMissing (projectRef intent))
    Just project =>
      let pid = projectId project
          freshId = Task.nextTaskIdFromSummaries pid (existingTasks routingView)
      in Right (MkRoutedTaskIntake freshId (Task.CreateTask pid (taskTitle intent)))
