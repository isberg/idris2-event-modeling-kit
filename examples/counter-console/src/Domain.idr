module Domain

import EmKit.Modeling.Pattern.StateView
import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Sourcing.Decider

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
renderValueLine : CounterView -> String
renderValueLine view =
  if created view
    then label view ++ " = " ++ show (value view) ++ " [" ++ roman view ++ "]"
    else "not created yet"

public export
decrementNat : Nat -> Nat
decrementNat Z = Z
decrementNat (S k) = k

public export
implementation Projection CounterEvent CounterState where
  initial = MkCounterState Nothing 0
  evolve _ (Created title) = MkCounterState (Just title) 0
  evolve state Incremented = MkCounterState (name state) (S (value state))
  evolve state Decremented = MkCounterState (name state) (decrementNat (value state))

data CounterLegal : Command -> CounterState -> Type where
  MkCounterLegal : CounterLegal cmd st

public export
implementation Decider List Command Rejection CounterEvent CounterState where
  Legal = CounterLegal

  legal (Create _) state =
    case name state of
      Nothing => Right MkCounterLegal
      Just _ => Left AlreadyCreated
  legal Increment state =
    case name state of
      Nothing => Left NotCreatedYet
      Just _ =>
        if value state < maxValue
          then Right MkCounterLegal
          else Left AtMaximum
  legal Decrement state =
    case name state of
      Nothing => Left NotCreatedYet
      Just _ =>
        if value state == 0
          then Left AtMinimum
          else Right MkCounterLegal

  decide (Create title) _ MkCounterLegal = [Created title]
  decide Increment _ MkCounterLegal = [Incremented]
  decide Decrement _ MkCounterLegal = [Decremented]

public export
implementation StateView CounterEvent CounterView where
  initialView = MkCounterView "(unnamed)" 0 "" False
  projectEvent _ (Created title) = MkCounterView title 0 "" True
  projectEvent view Incremented =
    let next = S (value view) in
      MkCounterView (label view) next (romanDigit next) True
  projectEvent view Decremented =
    let next = decrementNat (value view) in
      MkCounterView (label view) next (romanDigit next) True

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
