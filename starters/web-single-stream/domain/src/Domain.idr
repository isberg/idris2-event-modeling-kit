module Domain

import Data.String
import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Sourcing.Decider
import EmKit.Sourcing.Projection
import EmKit.Stream.Version

%default total

public export
maxValue : Nat
maxValue = 10

public export
counterStreamId : String
counterStreamId = "counter-main"

public export
data Command
  = Create String
  | Increment
  | Decrement

public export
data Rejection
  = AlreadyCreated
  | CounterMissing
  | EmptyName
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
record CounterModel where
  constructor MkCounterModel
  created : Bool
  label : String
  value : Nat
  roman : String

public export
record CounterDetail where
  constructor MkCounterDetail
  version : Nat
  model : CounterModel
  history : List CounterEvent

public export
record CounterBundle where
  constructor MkCounterBundle
  model : CounterModel

public export
data Screen = CounterHome

public export
data Action
  = CreateCounterAction
  | IncrementCounterAction
  | DecrementCounterAction

public export
data Intent
  = PromptCreate
  | RunIncrement
  | RunDecrement

public export
renderRejection : Rejection -> String
renderRejection AlreadyCreated = "counter already exists."
renderRejection CounterMissing = "counter does not exist yet."
renderRejection EmptyName = "counter name is required."
renderRejection AtMaximum = "counter is already at maximum."
renderRejection AtMinimum = "counter is already at minimum."

public export
renderAction : Action -> String
renderAction CreateCounterAction = "Create counter"
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

public export
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

stepState : CounterState -> CounterEvent -> CounterState
stepState _ (Created cleanName) = MkCounterState (Just cleanName) 0
stepState state Incremented = MkCounterState (name state) (S (value state))
stepState state Decremented = MkCounterState (name state) (decNat (value state))

stepModel : CounterModel -> CounterEvent -> CounterModel
stepModel _ (Created cleanName) = MkCounterModel True cleanName 0 ""
stepModel model Incremented =
  let next = S (value model) in
  MkCounterModel True (label model) next (romanDigit next)
stepModel model Decremented =
  let next = decNat (value model) in
  MkCounterModel True (label model) next (romanDigit next)

public export
implementation Projection CounterEvent CounterState where
  initial = MkCounterState Nothing 0
  evolve = stepState

public export
implementation Projection CounterEvent CounterModel where
  initial = MkCounterModel False "(unnamed)" 0 ""
  evolve = stepModel

data CounterLegal : Command -> CounterState -> Type where
  CanCreateMissing :
    {rawName : String} ->
    {currentValue : Nat} ->
    (cleanName : String) ->
    CounterLegal (Create rawName) (MkCounterState Nothing currentValue)
  CanIncrementBelowMax :
    {counterName : String} ->
    {currentValue : Nat} ->
    BelowMax currentValue ->
    CounterLegal Increment (MkCounterState (Just counterName) currentValue)
  CanDecrementPositive :
    {counterName : String} ->
    {remaining : Nat} ->
    CounterLegal Decrement (MkCounterState (Just counterName) (S remaining))

createLegal : (rawName : String) -> (state : CounterState) -> Either Rejection (CounterLegal (Create rawName) state)
createLegal rawName (MkCounterState Nothing currentValue) =
  let cleanName = trim rawName in
  if cleanName == ""
    then Left EmptyName
    else Right (CanCreateMissing cleanName)
createLegal _ (MkCounterState (Just _) _) = Left AlreadyCreated

incrementLegal : (state : CounterState) -> Either Rejection (CounterLegal Increment state)
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

decrementLegal : (state : CounterState) -> Either Rejection (CounterLegal Decrement state)
decrementLegal (MkCounterState Nothing _) = Left CounterMissing
decrementLegal (MkCounterState (Just _) Z) = Left AtMinimum
decrementLegal (MkCounterState (Just _) (S remaining)) = Right CanDecrementPositive

public export
implementation Decider List Command Rejection CounterEvent CounterState where
  Legal = CounterLegal

  legal (Create rawName) state = createLegal rawName state
  legal Increment state = incrementLegal state
  legal Decrement state = decrementLegal state

  decide (Create _) _ (CanCreateMissing cleanName) = [Created cleanName]
  decide Increment _ (CanIncrementBelowMax _) = [Incremented]
  decide Decrement _ CanDecrementPositive = [Decremented]

public export
emptyDetail : CounterDetail
emptyDetail = MkCounterDetail 0 (initial {event=CounterEvent} {model=CounterModel}) []

public export
detailFromEvents : Nat -> List CounterEvent -> CounterDetail
detailFromEvents version events = MkCounterDetail version (project {h=List} events) events

public export
applyDetailEvent : Nat -> CounterEvent -> CounterDetail -> Either String CounterDetail
applyDetailEvent incomingVersion event detail =
  case applyVersionedUpdate counterStreamId (version detail) incomingVersion step detail of
    Left err => Left (formatAdvanceError id err)
    Right (IgnoredStale current) => Right current
    Right (Applied next) => Right next
  where
    step : Nat -> CounterDetail -> CounterDetail
    step nextVersion current =
      let nextHistory = history current ++ [event]
          nextModel = stepModel (model current) event
      in MkCounterDetail nextVersion nextModel nextHistory

public export
bundleForModel : CounterModel -> CounterBundle
bundleForModel = MkCounterBundle

public export
implementation ScreenCatalog Screen CounterBundle where
  specFor CounterHome = MkScreenSpec CounterHome ClientProjectionOnly (\_ => True)

public export
implementation ScreenActions Screen CounterBundle Action Intent where
  screenForAction _ = CounterHome
  intentForAction CreateCounterAction = PromptCreate
  intentForAction IncrementCounterAction = RunIncrement
  intentForAction DecrementCounterAction = RunDecrement

  availableScreenActions bundle CounterHome =
    if created (model bundle)
      then [IncrementCounterAction, DecrementCounterAction]
      else [CreateCounterAction]

public export
availableActionsForModel : CounterModel -> List Action
availableActionsForModel currentModel =
  availableScreenActions {screen=Screen} {bundle=CounterBundle} {action=Action} {intent=Intent}
    (bundleForModel currentModel)
    CounterHome
