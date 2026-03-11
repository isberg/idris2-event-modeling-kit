module Domain.Translation

import Data.String
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
