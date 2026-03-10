module Domain.Task

import Data.String
import Domain.Event
import EmKit.Sourcing.Projection
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
record TaskModel where
  constructor MkTaskModel
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
summaryFromModel : String -> Nat -> TaskModel -> TaskSummary
summaryFromModel taskId streamVersion model =
  MkTaskSummary taskId streamVersion (exists model) (projectId model) (title model) (status model)

public export
detailFromModel : String -> Nat -> List TaskEvent -> TaskModel -> TaskDetail
detailFromModel taskId streamVersion history model =
  MkTaskDetail taskId streamVersion (exists model) (projectId model) (title model) (status model) history

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

data TaskLegal : TaskCommand -> TaskModel -> Type where
  CanCreateTask :
    {projectId : String} ->
    {rawTitle : String} ->
    (cleanTitle : String) ->
    TaskLegal (CreateTask projectId rawTitle) state
  CanStartTask : TaskLegal StartTask state
  CanCompleteTask : TaskLegal CompleteTask state

createLegal : (projectId : String) -> (rawTitle : String) -> TaskModel -> Either TaskRejection (TaskLegal (CreateTask projectId rawTitle) state)
createLegal projectId rawTitle (MkTaskModel False _ _ _) =
  let cleanTitle = trim rawTitle in
    if cleanTitle == ""
      then Left EmptyTaskTitle
      else Right (CanCreateTask cleanTitle)
createLegal _ _ (MkTaskModel True _ _ _) = Left TaskAlreadyCreated

startLegal : TaskModel -> Either TaskRejection (TaskLegal StartTask state)
startLegal (MkTaskModel False _ _ _) = Left TaskMissing
startLegal (MkTaskModel True _ _ TaskTodo) = Right CanStartTask
startLegal (MkTaskModel True _ _ TaskInProgress) = Left TaskAlreadyStarted
startLegal (MkTaskModel True _ _ TaskDone) = Left TaskAlreadyDone

completeLegal : TaskModel -> Either TaskRejection (TaskLegal CompleteTask state)
completeLegal (MkTaskModel False _ _ _) = Left TaskMissing
completeLegal (MkTaskModel True _ _ TaskTodo) = Left TaskNotStarted
completeLegal (MkTaskModel True _ _ TaskInProgress) = Right CanCompleteTask
completeLegal (MkTaskModel True _ _ TaskDone) = Left TaskAlreadyDone

public export
implementation Projection TaskEvent TaskModel where
  initial = MkTaskModel False "" "" TaskTodo
  evolve _ (TaskCreated projectId taskTitle) = MkTaskModel True projectId taskTitle TaskTodo
  evolve model TaskStarted = { status := TaskInProgress } model
  evolve model TaskCompleted = { status := TaskDone } model

public export
implementation Decider List TaskCommand TaskRejection TaskEvent TaskModel where
  Legal = TaskLegal

  legal (CreateTask projectId rawTitle) state = createLegal projectId rawTitle state
  legal StartTask state = startLegal state
  legal CompleteTask state = completeLegal state

  decide (CreateTask projectId rawTitle) state (CanCreateTask cleanTitle) =
    [TaskCreated projectId cleanTitle]
  decide StartTask state CanStartTask = [TaskStarted]
  decide CompleteTask state CanCompleteTask = [TaskCompleted]

public export
summaryFromEvents : String -> Nat -> List TaskEvent -> TaskSummary
summaryFromEvents taskId streamVersion events = summaryFromModel taskId streamVersion (project events)

public export
detailFromEvents : String -> Nat -> List TaskEvent -> TaskDetail
detailFromEvents taskId streamVersion events =
  detailFromModel taskId streamVersion events (project events)

public export
canStart : TaskDetail -> Bool
canStart detail = exists detail && status detail == TaskTodo

public export
canComplete : TaskDetail -> Bool
canComplete detail = exists detail && status detail == TaskInProgress
