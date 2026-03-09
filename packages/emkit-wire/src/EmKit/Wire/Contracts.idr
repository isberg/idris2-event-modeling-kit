module EmKit.Wire.Contracts

%default total

public export
record ExecutePayload (cmd : Type) where
  constructor MkExecutePayload
  expectedVersion : Nat
  command : cmd

public export
record StreamEvent (ev : Type) where
  constructor MkStreamEvent
  version : Nat
  event : ev

public export
record MultiplexedStreamEvent (stream : Type) (ev : Type) where
  constructor MkMultiplexedStreamEvent
  streamId : stream
  streamVersion : Nat
  event : ev

public export
record ResyncPayload (ev : Type) where
  constructor MkResyncPayload
  version : Nat
  events : List ev
