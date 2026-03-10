module Domain

import Data.String
import EmKit.Modeling.Pattern.StateView
import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Sourcing.Decider

%default total

public export
counterPrefix : String
counterPrefix = "counter-"

public export
maxValue : Nat
maxValue = 10

public export
data Command
  = CreateCounter String
  | Increment
  | Decrement

public export
data Rejection
  = CounterAlreadyCreated
  | CounterMissing
  | EmptyCounterName
  | AtMaximum
  | AtMinimum

public export
data CounterEvent
  = Created String
  | Incremented
  | Decremented

public export
record CounterState where
  constructor MkCounterState
  name : Maybe String
  value : Nat

public export
record CounterView where
  constructor MkCounterView
  exists : Bool
  name : String
  value : Nat
  roman : String

public export
record CounterSummary where
  constructor MkCounterSummary
  counterId : String
  version : Nat
  exists : Bool
  name : String
  value : Nat
  roman : String

public export
record CounterDetail where
  constructor MkCounterDetail
  counterId : String
  version : Nat
  exists : Bool
  name : String
  value : Nat
  roman : String
  history : List CounterEvent

public export
record AppBundle where
  constructor MkAppBundle
  summaries : List CounterSummary
  selectedDetail : Maybe CounterDetail

public export
data Screen = CountersOverview | CounterDetailScreen

public export
data Action
  = CreateCounterAction
  | OpenCounterAction String
  | BackToCountersAction
  | IncrementCounterAction
  | DecrementCounterAction

public export
data Intent
  = PromptCreateCounter
  | ShowCounterDetail String
  | ShowCountersOverview
  | RunIncrement
  | RunDecrement

public export
renderRejection : Rejection -> String
renderRejection CounterAlreadyCreated = "counter already exists."
renderRejection CounterMissing = "counter does not exist yet."
renderRejection EmptyCounterName = "counter name is required."
renderRejection AtMaximum = "counter is already at maximum."
renderRejection AtMinimum = "counter is already at minimum."

public export
renderAction : Action -> String
renderAction CreateCounterAction = "Create counter"
renderAction (OpenCounterAction counterId) = "Open " ++ counterId
renderAction BackToCountersAction = "Back to counters"
renderAction IncrementCounterAction = "Increment"
renderAction DecrementCounterAction = "Decrement"

romanDigit : Nat -> String
romanDigit 0 = ""
romanDigit 1 = "I"
romanDigit 2 = "II"
romanDigit 3 = "III"
romanDigit 4 = "IV"
romanDigit 5 = "V"
romanDigit 6 = "VI"
romanDigit 7 = "VII"
romanDigit 8 = "VIII"
romanDigit 9 = "IX"
romanDigit _ = "X"

decNat : Nat -> Nat
decNat Z = Z
decNat (S k) = k

data BelowMax : Nat -> Type where
  Below0 : BelowMax 0
  Below1 : BelowMax 1
  Below2 : BelowMax 2
  Below3 : BelowMax 3
  Below4 : BelowMax 4
  Below5 : BelowMax 5
  Below6 : BelowMax 6
  Below7 : BelowMax 7
  Below8 : BelowMax 8
  Below9 : BelowMax 9

public export
summaryFromView : String -> Nat -> CounterView -> CounterSummary
summaryFromView counterId streamVersion view =
  MkCounterSummary counterId streamVersion (exists view) (name view) (value view) (roman view)

public export
detailFromView : String -> Nat -> List CounterEvent -> CounterView -> CounterDetail
detailFromView counterId version history view =
  MkCounterDetail counterId version (exists view) (name view) (value view) (roman view) history

public export
summaryFromDetail : CounterDetail -> CounterSummary
summaryFromDetail detail =
  MkCounterSummary (counterId detail) (version detail) (exists detail) (name detail) (value detail) (roman detail)

public export
emptySummary : String -> CounterSummary
emptySummary counterId = MkCounterSummary counterId 0 False "" 0 ""

public export
bundleForApp : List CounterSummary -> Maybe CounterDetail -> AppBundle
bundleForApp = MkAppBundle

public export
applySummaryEvent : String -> Nat -> CounterEvent -> CounterSummary -> Either String CounterSummary
applySummaryEvent counterId streamVersion event summary =
  if streamVersion <= version summary then
    Right summary
  else
    let expected = S (version summary) in
    if streamVersion /= expected then
      Left ("Overview summary gap for " ++ counterId ++ ": expected v" ++ show expected ++ ", got v" ++ show streamVersion ++ ".")
    else
      case event of
        Created counterName => Right (MkCounterSummary counterId streamVersion True counterName 0 "")
        Incremented =>
          let next = S (value summary) in
          Right (MkCounterSummary counterId streamVersion (exists summary) (name summary) next (romanDigit next))
        Decremented =>
          let next = decNat (value summary) in
          Right (MkCounterSummary counterId streamVersion (exists summary) (name summary) next (romanDigit next))

data CommandLegal : Command -> CounterState -> Type where
  CanCreateMissing :
    {rawName : String} ->
    (cleanName : String) ->
    CommandLegal (CreateCounter rawName) state
  CanIncrementBelowMax :
    {counterName : String} ->
    {value : Nat} ->
    BelowMax value ->
    CommandLegal Increment (MkCounterState (Just counterName) value)
  CanDecrementPositive :
    {counterName : String} ->
    {remaining : Nat} ->
    CommandLegal Decrement (MkCounterState (Just counterName) (S remaining))

createLegal : (rawName : String) -> (state : CounterState) -> Either Rejection (CommandLegal (CreateCounter rawName) state)
createLegal rawName (MkCounterState Nothing currentValue) =
  let cleanName = trim rawName in
    if cleanName == ""
      then Left EmptyCounterName
      else Right (CanCreateMissing cleanName)
createLegal _ (MkCounterState (Just _) _) = Left CounterAlreadyCreated

incrementLegal : (state : CounterState) -> Either Rejection (CommandLegal Increment state)
incrementLegal (MkCounterState Nothing _) = Left CounterMissing
incrementLegal (MkCounterState (Just _) 0) = Right (CanIncrementBelowMax Below0)
incrementLegal (MkCounterState (Just _) 1) = Right (CanIncrementBelowMax Below1)
incrementLegal (MkCounterState (Just _) 2) = Right (CanIncrementBelowMax Below2)
incrementLegal (MkCounterState (Just _) 3) = Right (CanIncrementBelowMax Below3)
incrementLegal (MkCounterState (Just _) 4) = Right (CanIncrementBelowMax Below4)
incrementLegal (MkCounterState (Just _) 5) = Right (CanIncrementBelowMax Below5)
incrementLegal (MkCounterState (Just _) 6) = Right (CanIncrementBelowMax Below6)
incrementLegal (MkCounterState (Just _) 7) = Right (CanIncrementBelowMax Below7)
incrementLegal (MkCounterState (Just _) 8) = Right (CanIncrementBelowMax Below8)
incrementLegal (MkCounterState (Just _) 9) = Right (CanIncrementBelowMax Below9)
incrementLegal (MkCounterState (Just _) _) = Left AtMaximum

decrementLegal : (state : CounterState) -> Either Rejection (CommandLegal Decrement state)
decrementLegal (MkCounterState Nothing _) = Left CounterMissing
decrementLegal (MkCounterState (Just _) Z) = Left AtMinimum
decrementLegal (MkCounterState (Just _) (S remaining)) = Right CanDecrementPositive

public export
implementation Projection CounterEvent CounterState where
  initial = MkCounterState Nothing 0
  evolve _ (Created counterName) = MkCounterState (Just counterName) 0
  evolve state Incremented = { value := S (value state) } state
  evolve state Decremented = { value := decNat (value state) } state

public export
implementation Decider List Command Rejection CounterEvent CounterState where
  Legal = CommandLegal

  legal (CreateCounter rawName) state = createLegal rawName state
  legal Increment state = incrementLegal state
  legal Decrement state = decrementLegal state

  decide (CreateCounter rawName) _ (CanCreateMissing cleanName) = [Created cleanName]
  decide Increment _ (CanIncrementBelowMax _) = [Incremented]
  decide Decrement _ CanDecrementPositive = [Decremented]

public export
implementation StateView CounterEvent CounterView where
  initialView = MkCounterView False "" 0 ""
  projectEvent _ (Created counterName) = MkCounterView True counterName 0 ""
  projectEvent view Incremented =
    let next = S (value view) in
      MkCounterView (exists view) (name view) next (romanDigit next)
  projectEvent view Decremented =
    let next = decNat (value view) in
      MkCounterView (exists view) (name view) next (romanDigit next)

public export
summaryFromEvents : String -> Nat -> List CounterEvent -> CounterSummary
summaryFromEvents counterId streamVersion events = summaryFromView counterId streamVersion (projectFromList events)

public export
detailFromEvents : String -> Nat -> List CounterEvent -> CounterDetail
detailFromEvents counterId version history = detailFromView counterId version history (projectFromList history)

canIncrement : CounterDetail -> Bool
canIncrement detail = exists detail && value detail < maxValue

canDecrement : CounterDetail -> Bool
canDecrement detail = exists detail && value detail > 0

public export
implementation ScreenCatalog Screen AppBundle where
  specFor CountersOverview = MkScreenSpec CountersOverview HybridProjection (\_ => True)
  specFor CounterDetailScreen = MkScreenSpec CounterDetailScreen HybridProjection (\bundle => case selectedDetail bundle of
    Nothing => False
    Just _ => True)

public export
implementation ScreenActions Screen AppBundle Action Intent where
  screenForAction CreateCounterAction = CountersOverview
  screenForAction (OpenCounterAction _) = CountersOverview
  screenForAction BackToCountersAction = CounterDetailScreen
  screenForAction IncrementCounterAction = CounterDetailScreen
  screenForAction DecrementCounterAction = CounterDetailScreen

  intentForAction CreateCounterAction = PromptCreateCounter
  intentForAction (OpenCounterAction counterId) = ShowCounterDetail counterId
  intentForAction BackToCountersAction = ShowCountersOverview
  intentForAction IncrementCounterAction = RunIncrement
  intentForAction DecrementCounterAction = RunDecrement

  availableScreenActions bundle CountersOverview =
    CreateCounterAction :: map (OpenCounterAction . counterId) (filter exists (summaries bundle))
  availableScreenActions bundle CounterDetailScreen =
    case selectedDetail bundle of
      Nothing => []
      Just detail =>
        BackToCountersAction
          :: (if canIncrement detail then [IncrementCounterAction] else [])
          ++ (if canDecrement detail then [DecrementCounterAction] else [])
