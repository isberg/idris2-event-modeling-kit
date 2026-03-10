module Domain.Automation

import Data.List
import Domain.Event
import Domain.Project
import Domain.Task

%default total

public export
record ProjectCompletionView where
  constructor MkProjectCompletionView
  projectId : String
  projectExists : Bool
  projectCompleted : Bool
  taskCount : Nat
  openTaskCount : Nat

countOpen : List TaskSummary -> Nat
countOpen [] = 0
countOpen (summary :: rest) =
  let step = if exists summary && status summary /= TaskDone then 1 else 0
  in step + countOpen rest

public export
projectCompletionView : ProjectDetail -> List TaskSummary -> ProjectCompletionView
projectCompletionView detail tasks =
  let visible = filter exists tasks in
  MkProjectCompletionView
    (projectId detail)
    (exists detail)
    (completed detail)
    (length visible)
    (countOpen visible)

public export
automatedProjectCommand : ProjectCompletionView -> Maybe ProjectCommand
automatedProjectCommand view =
  if projectExists view && not (projectCompleted view) && taskCount view > 0 && openTaskCount view == 0
    then Just CompleteProject
    else Nothing
