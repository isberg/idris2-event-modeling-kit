module Domain

import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Sourcing.Decider
import EmKit.Sourcing.Projection
import EmKit.Stream.Version

%default total

public export
counterStreamId : String
counterStreamId = "counter-main"

public export
data Command
  = Increment
  | Decrement

public export
data Rejection
  = AtMinimum

public export
data CounterEvent
  = Incremented
  | Decremented

public export
record CounterModel where
  constructor MkCounterModel
  value : Nat

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
  = IncrementCounterAction
  | DecrementCounterAction

public export
data Intent
  = RunIncrement
  | RunDecrement

public export
renderRejection : Rejection -> String
renderRejection AtMinimum = "counter is already at minimum."

public export
renderAction : Action -> String
renderAction IncrementCounterAction = "Increment"
renderAction DecrementCounterAction = "Decrement"

public export
decNat : Nat -> Nat
decNat Z = Z
decNat (S k) = k

public export
implementation Projection CounterEvent CounterModel where
  initial = MkCounterModel 0
  evolve (MkCounterModel currentValue) Incremented = MkCounterModel (S currentValue)
  evolve (MkCounterModel currentValue) Decremented = MkCounterModel (decNat currentValue)

data CounterLegal : Command -> CounterModel -> Type where
  CanIncrement : {currentValue : Nat} -> CounterLegal Increment (MkCounterModel currentValue)
  CanDecrementPositive : {remaining : Nat} -> CounterLegal Decrement (MkCounterModel (S remaining))

incrementLegal : (model : CounterModel) -> Either Rejection (CounterLegal Increment model)
incrementLegal (MkCounterModel _) = Right CanIncrement

decrementLegal : (model : CounterModel) -> Either Rejection (CounterLegal Decrement model)
decrementLegal (MkCounterModel Z) = Left AtMinimum
decrementLegal (MkCounterModel (S remaining)) = Right CanDecrementPositive

public export
implementation Decider List Command Rejection CounterEvent CounterModel where
  Legal = CounterLegal

  legal Increment model = incrementLegal model
  legal Decrement model = decrementLegal model

  decide Increment _ CanIncrement = [Incremented]
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
          nextModel = evolve (model current) event
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
  intentForAction IncrementCounterAction = RunIncrement
  intentForAction DecrementCounterAction = RunDecrement

  availableScreenActions bundle CounterHome =
    case value (model bundle) of
      Z => [IncrementCounterAction]
      S _ => [IncrementCounterAction, DecrementCounterAction]

public export
availableActionsForModel : CounterModel -> List Action
availableActionsForModel currentModel =
  availableScreenActions {screen=Screen} {bundle=CounterBundle} {action=Action} {intent=Intent}
    (bundleForModel currentModel)
    CounterHome
