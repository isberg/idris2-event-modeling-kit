module Domain

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
decrementNat : Nat -> Nat
decrementNat Z = Z
decrementNat (S k) = k

public export
renderRejection : Rejection -> String
renderRejection AlreadyCreated = "counter already exists."
renderRejection NotCreatedYet = "counter does not exist yet."
renderRejection AtMinimum = "counter is already at minimum."

public export
renderState : CounterState -> String
renderState (MkCounterState Nothing value) = "state{name=<missing>, value=" ++ show value ++ "}"
renderState (MkCounterState (Just title) value) = "state{name=" ++ title ++ ", value=" ++ show value ++ "}"

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
