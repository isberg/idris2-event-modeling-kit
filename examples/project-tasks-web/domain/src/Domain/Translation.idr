module Domain.Translation

import Data.String
import Domain.Task as Task
import EmKit.Modeling.Pattern.Translation

%default total

public export
record TaskIntakeSignal where
  constructor MkTaskIntakeSignal
  projectRef : String
  taskTitle : String

public export
record TaskIntakeIntent where
  constructor MkTaskIntakeIntent
  projectRef : String
  taskTitle : String

public export
data TaskIntakeTranslationRejection
  = IntakeProjectRefMissing

public export
renderTaskIntakeTranslationRejection : TaskIntakeTranslationRejection -> String
renderTaskIntakeTranslationRejection IntakeProjectRefMissing = "project reference is required."

public export
implementation Translation TaskIntakeSignal TaskIntakeIntent TaskIntakeTranslationRejection where
  translate signal =
    let cleanProjectRef = trim (projectRef signal)
        cleanTaskTitle = trim (taskTitle signal)
    in if cleanProjectRef == ""
         then Left IntakeProjectRefMissing
         else Right (MkTaskIntakeIntent cleanProjectRef cleanTaskTitle)

public export
record TaskActionSignal where
  constructor MkTaskActionSignal
  taskRef : String
  action : String

public export
record TaskActionIntent where
  constructor MkTaskActionIntent
  taskRef : String
  command : Task.TaskCommand

public export
data TaskActionTranslationRejection
  = ActionTaskRefMissing
  | UnknownTaskAction String

public export
renderTaskActionTranslationRejection : TaskActionTranslationRejection -> String
renderTaskActionTranslationRejection ActionTaskRefMissing = "task reference is required."
renderTaskActionTranslationRejection (UnknownTaskAction raw) =
  "unknown external task action: " ++ raw

normalizedTaskAction : String -> Maybe Task.TaskCommand
normalizedTaskAction raw =
  let cleaned = trim raw in
    if cleaned == "start" || cleaned == "StartTask"
      then Just Task.StartTask
      else if cleaned == "complete" || cleaned == "CompleteTask"
        then Just Task.CompleteTask
        else Nothing

public export
implementation Translation TaskActionSignal TaskActionIntent TaskActionTranslationRejection where
  translate signal =
    let cleanTaskRef = trim (taskRef signal)
        rawAction = trim (action signal)
    in if cleanTaskRef == ""
         then Left ActionTaskRefMissing
         else case normalizedTaskAction rawAction of
                Nothing => Left (UnknownTaskAction rawAction)
                Just cmd => Right (MkTaskActionIntent cleanTaskRef cmd)
