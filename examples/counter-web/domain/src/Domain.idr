module Domain

import EmKit.Sourcing.Projection
import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Sourcing.Decider
import JSON.Simple
import JSON.Simple.Derive

%language ElabReflection
%default total

public export
data Command
  = Create String
  | Increment
  | Decrement

public export
data Rejection
  = AlreadyCreated
  | NotCreatedYet
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
  label : String
  value : Nat
  roman : String
  created : Bool

%runElab derive "CounterView" [ToJSON, FromJSON]

public export
record CounterBundle where
  constructor MkCounterBundle
  view : CounterView

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

maxValue : Nat
maxValue = 10

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
renderRejection : Rejection -> String
renderRejection AlreadyCreated = "counter already exists."
renderRejection NotCreatedYet = "counter does not exist yet."
renderRejection AtMaximum = "counter is already at maximum."
renderRejection AtMinimum = "counter is already at minimum."

public export
renderAction : Action -> String
renderAction CreateCounterAction = "Create counter"
renderAction IncrementCounterAction = "Increment"
renderAction DecrementCounterAction = "Decrement"

public export
decrementNat : Nat -> Nat
decrementNat Z = Z
decrementNat (S k) = k

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
implementation Projection CounterEvent CounterState where
  initial = MkCounterState Nothing 0
  evolve _ (Created title) = MkCounterState (Just title) 0
  evolve state Incremented = MkCounterState (name state) (S (value state))
  evolve state Decremented = MkCounterState (name state) (decrementNat (value state))

data CounterLegal : Command -> CounterState -> Type where
  CanCreateMissing :
    {title : String} ->
    {value : Nat} ->
    CounterLegal (Create title) (MkCounterState Nothing value)
  CanIncrementBelowMax :
    {counterName : String} ->
    {value : Nat} ->
    BelowMax value ->
    CounterLegal Increment (MkCounterState (Just counterName) value)
  CanDecrementPositive :
    {counterName : String} ->
    {remaining : Nat} ->
    CounterLegal Decrement (MkCounterState (Just counterName) (S remaining))

createLegal : (title : String) -> (state : CounterState) -> Either Rejection (CounterLegal (Create title) state)
createLegal _ (MkCounterState Nothing value) = Right CanCreateMissing
createLegal _ (MkCounterState (Just _) _) = Left AlreadyCreated

incrementLegal : (state : CounterState) -> Either Rejection (CounterLegal Increment state)
incrementLegal (MkCounterState Nothing _) = Left NotCreatedYet
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
decrementLegal (MkCounterState Nothing _) = Left NotCreatedYet
decrementLegal (MkCounterState (Just _) Z) = Left AtMinimum
decrementLegal (MkCounterState (Just _) (S remaining)) = Right CanDecrementPositive

public export
implementation Decider List Command Rejection CounterEvent CounterState where
  Legal = CounterLegal

  legal (Create title) state = createLegal title state
  legal Increment state = incrementLegal state
  legal Decrement state = decrementLegal state

  decide (Create title) _ CanCreateMissing = [Created title]
  decide Increment _ (CanIncrementBelowMax _) = [Incremented]
  decide Decrement _ CanDecrementPositive = [Decremented]

public export
implementation Projection CounterEvent CounterView where
  initial = MkCounterView "(unnamed)" 0 "" False
  evolve _ (Created title) = MkCounterView title 0 "" True
  evolve view Incremented =
    let next = S (value view) in
      MkCounterView (label view) next (romanDigit next) True
  evolve view Decremented =
    let next = decrementNat (value view) in
      MkCounterView (label view) next (romanDigit next) True

public export
bundleForView : CounterView -> CounterBundle
bundleForView = MkCounterBundle

public export
availableActionsForView : CounterView -> List Action
availableActionsForView view =
  if created view
    then [IncrementCounterAction, DecrementCounterAction]
    else [CreateCounterAction]

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
    if created (view bundle)
      then [IncrementCounterAction, DecrementCounterAction]
      else [CreateCounterAction]
