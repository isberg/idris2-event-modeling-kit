module Domain.Task

import Data.String
import Domain.Event
import EmKit.Modeling.Pattern.StateView
import EmKit.Sourcing.Decider
import EmKit.Stream.Version

%default total

public export
data TaskCommand
  = CreateTask String String
  | StartTask
  | CompleteTask

public export
data TaskRejection
  = TaskAlreadyCreated
  | TaskMissing
  | EmptyTaskTitle
  | TaskAlreadyStarted
  | TaskAlreadyDone
  | TaskNotStarted

public export
record TaskState where
  constructor MkTaskState
  exists : Bool
  projectId : String
  title : String
  status : TaskStatus

public export
record TaskView where
  constructor MkTaskView
  exists : Bool
  projectId : String
  title : String
  status : TaskStatus

public export
record TaskSummary where
  constructor MkTaskSummary
  taskId : String
  version : Nat
  exists : Bool
  projectId : String
  title : String
  status : TaskStatus

public export
record TaskDetail where
  constructor MkTaskDetail
  taskId : String
  version : Nat
  exists : Bool
  projectId : String
  title : String
  status : TaskStatus
  history : List TaskEvent

public export
renderTaskRejection : TaskRejection -> String
renderTaskRejection TaskAlreadyCreated = "task already exists."
renderTaskRejection TaskMissing = "task does not exist yet."
renderTaskRejection EmptyTaskTitle = "task title is required."
renderTaskRejection TaskAlreadyStarted = "task is already in progress."
renderTaskRejection TaskAlreadyDone = "task is already done."
renderTaskRejection TaskNotStarted = "task must be started before it can be completed."

dropPrefixChars : List Char -> List Char -> Maybe (List Char)
dropPrefixChars [] xs = Just xs
dropPrefixChars (_ :: _) [] = Nothing
dropPrefixChars (p :: ps) (x :: xs) =
  if p == x then dropPrefixChars ps xs else Nothing

digitNat : Char -> Maybe Nat
digitNat '0' = Just 0
digitNat '1' = Just 1
digitNat '2' = Just 2
digitNat '3' = Just 3
digitNat '4' = Just 4
digitNat '5' = Just 5
digitNat '6' = Just 6
digitNat '7' = Just 7
digitNat '8' = Just 8
digitNat '9' = Just 9
digitNat _ = Nothing

parseNatDigits : List Char -> Nat -> Maybe Nat
parseNatDigits [] acc = Just acc
parseNatDigits (c :: cs) acc =
  case digitNat c of
    Nothing => Nothing
    Just d => parseNatDigits cs (acc * 10 + d)

suffixNat : String -> String -> Maybe Nat
suffixNat idPrefix raw =
  case dropPrefixChars (unpack idPrefix) (unpack raw) of
    Nothing => Nothing
    Just [] => Nothing
    Just digits => parseNatDigits digits 0

maxNat : Nat -> Nat -> Nat
maxNat x y = if x < y then y else x

maxSuffixFor : String -> List String -> Nat
maxSuffixFor idPrefix [] = 0
maxSuffixFor idPrefix (raw :: rest) =
  let tailMax = maxSuffixFor idPrefix rest in
  case suffixNat idPrefix raw of
    Nothing => tailMax
    Just n => maxNat n tailMax

public export
taskPrefixForProject : String -> String
taskPrefixForProject projectId = taskPrefix ++ projectId ++ "-"

public export
nextTaskIdFromSummaries : String -> List TaskSummary -> String
nextTaskIdFromSummaries projectId summaries =
  let ids = map taskId summaries
      next = S (maxSuffixFor (taskPrefixForProject projectId) ids)
  in taskPrefixForProject projectId ++ show next

public export
summaryFromView : String -> Nat -> TaskView -> TaskSummary
summaryFromView taskId streamVersion view =
  MkTaskSummary taskId streamVersion (exists view) (projectId view) (title view) (status view)

public export
detailFromView : String -> Nat -> List TaskEvent -> TaskView -> TaskDetail
detailFromView taskId streamVersion history view =
  MkTaskDetail taskId streamVersion (exists view) (projectId view) (title view) (status view) history

public export
summaryFromDetail : TaskDetail -> TaskSummary
summaryFromDetail detail =
  MkTaskSummary (taskId detail) (version detail) (exists detail) (projectId detail) (title detail) (status detail)

public export
emptyTaskSummary : String -> TaskSummary
emptyTaskSummary taskId = MkTaskSummary taskId 0 False "" "" TaskTodo

applyTaskSummaryStep : String -> TaskEvent -> Nat -> TaskSummary -> TaskSummary
applyTaskSummaryStep taskId (TaskCreated projectId taskTitle) nextVersion current =
  MkTaskSummary taskId nextVersion True projectId taskTitle TaskTodo
applyTaskSummaryStep taskId TaskStarted nextVersion current =
  { version := nextVersion, status := TaskInProgress } current
applyTaskSummaryStep taskId TaskCompleted nextVersion current =
  { version := nextVersion, status := TaskDone } current

public export
applyTaskSummaryEvent : String -> Nat -> TaskEvent -> TaskSummary -> Either String TaskSummary
applyTaskSummaryEvent taskId streamVersion event summary =
  case applyVersionedUpdate taskId (version summary) streamVersion (applyTaskSummaryStep taskId event) summary of
    Left (VersionGap _ expected incoming) =>
      Left ("Task summary gap for " ++ taskId ++ ": expected v" ++ show expected ++ ", got v" ++ show incoming ++ ".")
    Right (IgnoredStale current) => Right current
    Right (Applied next) => Right next

applyTaskDetailStep : String -> TaskEvent -> Nat -> TaskDetail -> TaskDetail
applyTaskDetailStep taskId (TaskCreated projectId taskTitle) nextVersion current =
  let nextHistory = history current ++ [TaskCreated projectId taskTitle]
  in MkTaskDetail taskId nextVersion True projectId taskTitle TaskTodo nextHistory
applyTaskDetailStep taskId TaskStarted nextVersion current =
  let nextHistory = history current ++ [TaskStarted]
  in MkTaskDetail taskId nextVersion (exists current) (projectId current) (title current) TaskInProgress nextHistory
applyTaskDetailStep taskId TaskCompleted nextVersion current =
  let nextHistory = history current ++ [TaskCompleted]
  in MkTaskDetail taskId nextVersion (exists current) (projectId current) (title current) TaskDone nextHistory

public export
applyTaskDetailEvent : Nat -> TaskEvent -> TaskDetail -> Either String TaskDetail
applyTaskDetailEvent streamVersion event detail =
  let tid = taskId detail in
  case applyVersionedUpdate tid (version detail) streamVersion (applyTaskDetailStep tid event) detail of
    Left (VersionGap _ expected incoming) =>
      Left ("Task detail gap for " ++ tid ++ ": expected v" ++ show expected ++ ", got v" ++ show incoming ++ ".")
    Right (IgnoredStale current) => Right current
    Right (Applied next) => Right next

data TaskLegal : TaskCommand -> TaskState -> Type where
  CanCreateTask :
    {projectId : String} ->
    {rawTitle : String} ->
    (cleanTitle : String) ->
    TaskLegal (CreateTask projectId rawTitle) state
  CanStartTask : TaskLegal StartTask state
  CanCompleteTask : TaskLegal CompleteTask state

createLegal : (projectId : String) -> (rawTitle : String) -> TaskState -> Either TaskRejection (TaskLegal (CreateTask projectId rawTitle) state)
createLegal projectId rawTitle (MkTaskState False _ _ _) =
  let cleanTitle = trim rawTitle in
    if cleanTitle == ""
      then Left EmptyTaskTitle
      else Right (CanCreateTask cleanTitle)
createLegal _ _ (MkTaskState True _ _ _) = Left TaskAlreadyCreated

startLegal : TaskState -> Either TaskRejection (TaskLegal StartTask state)
startLegal (MkTaskState False _ _ _) = Left TaskMissing
startLegal (MkTaskState True _ _ TaskTodo) = Right CanStartTask
startLegal (MkTaskState True _ _ TaskInProgress) = Left TaskAlreadyStarted
startLegal (MkTaskState True _ _ TaskDone) = Left TaskAlreadyDone

completeLegal : TaskState -> Either TaskRejection (TaskLegal CompleteTask state)
completeLegal (MkTaskState False _ _ _) = Left TaskMissing
completeLegal (MkTaskState True _ _ TaskTodo) = Left TaskNotStarted
completeLegal (MkTaskState True _ _ TaskInProgress) = Right CanCompleteTask
completeLegal (MkTaskState True _ _ TaskDone) = Left TaskAlreadyDone

public export
implementation Projection TaskEvent TaskState where
  initial = MkTaskState False "" "" TaskTodo
  evolve _ (TaskCreated projectId taskTitle) = MkTaskState True projectId taskTitle TaskTodo
  evolve state TaskStarted = { status := TaskInProgress } state
  evolve state TaskCompleted = { status := TaskDone } state

public export
implementation Decider List TaskCommand TaskRejection TaskEvent TaskState where
  Legal = TaskLegal

  legal (CreateTask projectId rawTitle) state = createLegal projectId rawTitle state
  legal StartTask state = startLegal state
  legal CompleteTask state = completeLegal state

  decide (CreateTask projectId rawTitle) state (CanCreateTask cleanTitle) =
    [TaskCreated projectId cleanTitle]
  decide StartTask state CanStartTask = [TaskStarted]
  decide CompleteTask state CanCompleteTask = [TaskCompleted]

public export
implementation StateView TaskEvent TaskView where
  initialView = MkTaskView False "" "" TaskTodo
  projectEvent _ (TaskCreated projectId taskTitle) = MkTaskView True projectId taskTitle TaskTodo
  projectEvent view TaskStarted = { status := TaskInProgress } view
  projectEvent view TaskCompleted = { status := TaskDone } view

public export
summaryFromEvents : String -> Nat -> List TaskEvent -> TaskSummary
summaryFromEvents taskId streamVersion events = summaryFromView taskId streamVersion (projectFromList events)

public export
detailFromEvents : String -> Nat -> List TaskEvent -> TaskDetail
detailFromEvents taskId streamVersion events =
  detailFromView taskId streamVersion events (projectFromList events)

public export
canStart : TaskDetail -> Bool
canStart detail = exists detail && status detail == TaskTodo

public export
canComplete : TaskDetail -> Bool
canComplete detail = exists detail && status detail == TaskInProgress
