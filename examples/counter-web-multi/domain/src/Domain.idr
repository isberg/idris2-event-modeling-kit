module Domain

import EmKit.Sourcing.Decider

%default total

public export
State : Type
State = Nat

public export
data Command = Increment

public export
data CounterEvent = Incremented

public export
data Rejection = NoRejections

public export
renderRejection : Rejection -> String
renderRejection NoRejections = "no rejections"

public export
data Legal : Command -> State -> Type where
  LegalIncrement : {st : State} -> Legal Increment st

public export
legal : (cmd : Command) -> (st : State) -> Either Rejection (Legal cmd st)
legal Increment _ = Right LegalIncrement

public export
decide : (cmd : Command) -> (st : State) -> Legal cmd st -> List CounterEvent
decide Increment _ _ = [Incremented]

public export
evolve : State -> CounterEvent -> State
evolve count Incremented = S count

public export
implementation Projection CounterEvent State where
  initial = 0
  evolve = Domain.evolve

public export
implementation Decider List Command Rejection CounterEvent State where
  Legal = Domain.Legal
  legal = Domain.legal
  decide = Domain.decide
