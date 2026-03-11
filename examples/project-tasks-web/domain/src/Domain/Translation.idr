module Domain.Translation

import Data.String
import Domain.Project as Project
import Domain.Task as Task
import EmKit.Modeling.Pattern.Translation

%default total

public export
record TaskIntakeSignal where
  constructor MkTaskIntakeSignal
  projectRef : String
  taskTitle : String

public export
record TaskIntakeView where
  constructor MkTaskIntakeView
  projectSummary : Maybe Project.ProjectSummary
  existingTasks : List Task.TaskSummary

public export
record TaskIntakeInput where
  constructor MkTaskIntakeInput
  signal : TaskIntakeSignal
  view : TaskIntakeView

public export
data TaskIntakeRejection
  = IntakeProjectMissing String
  | IntakeEmptyTaskTitle

public export
record TranslatedTaskCommand where
  constructor MkTranslatedTaskCommand
  taskId : String
  command : Task.TaskCommand

public export
record TaskIntakeAccepted where
  constructor MkTaskIntakeAccepted
  taskId : String
  projectId : String
  acceptedTitle : String

public export
renderTaskIntakeRejection : TaskIntakeRejection -> String
renderTaskIntakeRejection (IntakeProjectMissing projectId) = "project does not exist: " ++ projectId
renderTaskIntakeRejection IntakeEmptyTaskTitle = "task title is required."

public export
acceptedFromTranslation : TranslatedTaskCommand -> TaskIntakeAccepted
acceptedFromTranslation translated =
  case command translated of
    Task.CreateTask projectId title => MkTaskIntakeAccepted (taskId translated) projectId title
    _ => MkTaskIntakeAccepted (taskId translated) "" ""

public export
implementation Translation TaskIntakeInput TranslatedTaskCommand TaskIntakeRejection where
  translate input =
    let intake = signal input
        intakeView = view input
        cleanTitle = trim (taskTitle intake)
    in case projectSummary intakeView of
         Nothing => Left (IntakeProjectMissing (projectRef intake))
         Just project =>
           if cleanTitle == ""
             then Left IntakeEmptyTaskTitle
             else
               let pid = projectId project
                   freshId = Task.nextTaskIdFromSummaries pid (existingTasks intakeView)
               in Right (MkTranslatedTaskCommand freshId (Task.CreateTask pid cleanTitle))
