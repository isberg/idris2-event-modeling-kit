module Domain

import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Sourcing.Decider
import EmKit.Sourcing.Projection

%default total

public export
data Command = Create String | Increment | Decrement

public export
data Rejection = AlreadyCreated | NotCreatedYet | AtMinimum

public export
data CounterEvent = Created String | Incremented | Decremented

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

public export
record CounterBundle where
  constructor MkCounterBundle
  view : CounterView

public export
data Screen = CounterHome

public export
data Action = CreateCounterAction | IncrementCounterAction | DecrementCounterAction

public export
data Intent = PromptCreate | RunIncrement | RunDecrement

public export
decrementNat : Nat -> Nat
decrementNat Z = Z
decrementNat (S k) = k

romanDigit : Nat -> String
romanDigit 0 = ""
romanDigit 1 = "I"
romanDigit 2 = "II"
romanDigit 3 = "III"
romanDigit 4 = "IV"
romanDigit _ = "V+"

public export
renderRejection : Rejection -> String
renderRejection AlreadyCreated = "counter already exists."
renderRejection NotCreatedYet = "counter does not exist yet."
renderRejection AtMinimum = "counter is already at minimum."

public export
renderAction : Action -> String
renderAction CreateCounterAction = "Create counter"
renderAction IncrementCounterAction = "Increment"
renderAction DecrementCounterAction = "Decrement"

public export
renderValueLine : CounterView -> String
renderValueLine view =
  if created view
    then label view ++ " = " ++ show (value view) ++ " [" ++ roman view ++ "]"
    else "not created yet"

data CounterLegal : Command -> CounterState -> Type where
  CanCreate : CounterLegal (Create title) (MkCounterState Nothing value)
  CanIncrement : CounterLegal Increment (MkCounterState (Just title) value)
  CanDecrement : CounterLegal Decrement (MkCounterState (Just title) (S remaining))

createLegal : (title : String) -> (state : CounterState) -> Either Rejection (CounterLegal (Create title) state)
createLegal _ (MkCounterState Nothing _) = Right CanCreate
createLegal _ (MkCounterState (Just _) _) = Left AlreadyCreated

incrementLegal : (state : CounterState) -> Either Rejection (CounterLegal Increment state)
incrementLegal (MkCounterState Nothing _) = Left NotCreatedYet
incrementLegal (MkCounterState (Just _) _) = Right CanIncrement

decrementLegal : (state : CounterState) -> Either Rejection (CounterLegal Decrement state)
decrementLegal (MkCounterState Nothing _) = Left NotCreatedYet
decrementLegal (MkCounterState (Just _) Z) = Left AtMinimum
decrementLegal (MkCounterState (Just _) (S _)) = Right CanDecrement

public export
implementation Projection CounterEvent CounterState where
  initial = MkCounterState Nothing 0
  evolve _ (Created title) = MkCounterState (Just title) 0
  evolve state Incremented = MkCounterState (name state) (S (value state))
  evolve state Decremented = MkCounterState (name state) (decrementNat (value state))

public export
implementation Decider List Command Rejection CounterEvent CounterState where
  Legal = CounterLegal

  legal (Create title) state = createLegal title state
  legal Increment state = incrementLegal state
  legal Decrement state = decrementLegal state

  decide (Create title) _ CanCreate = [Created title]
  decide Increment _ CanIncrement = [Incremented]
  decide Decrement _ CanDecrement = [Decremented]

public export
implementation Projection CounterEvent CounterView where
  initial = MkCounterView "(unnamed)" 0 "" False
  evolve _ (Created title) = MkCounterView title 0 "" True
  evolve view Incremented =
    let next = S (value view) in MkCounterView (label view) next (romanDigit next) True
  evolve view Decremented =
    let next = decrementNat (value view) in MkCounterView (label view) next (romanDigit next) True

public export
bundleForView : CounterView -> CounterBundle
bundleForView = MkCounterBundle

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
