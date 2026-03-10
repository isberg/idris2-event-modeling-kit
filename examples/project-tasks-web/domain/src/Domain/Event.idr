module Domain.Event

%default total

public export
projectPrefix : String
projectPrefix = "project-"

public export
taskPrefix : String
taskPrefix = "task-"

public export
data ProjectEvent
  = ProjectCreated String
  | ProjectCompleted

public export
data TaskStatus = TaskTodo | TaskInProgress | TaskDone

public export
Eq TaskStatus where
  TaskTodo == TaskTodo = True
  TaskInProgress == TaskInProgress = True
  TaskDone == TaskDone = True
  _ == _ = False

public export
data TaskEvent
  = TaskCreated String String
  | TaskStarted
  | TaskCompleted

public export
data StoredEvent
  = StoredProject ProjectEvent
  | StoredTask TaskEvent

public export
renderTaskStatus : TaskStatus -> String
renderTaskStatus TaskTodo = "Todo"
renderTaskStatus TaskInProgress = "In Progress"
renderTaskStatus TaskDone = "Done"

public export
renderProjectStatus : Bool -> String
renderProjectStatus False = "Open"
renderProjectStatus True = "Completed"
