module EmKit.Sourcing.Decider

import public EmKit.Sourcing.History

%default total

public export
interface Projection (event, state : Type) where
  initial : state
  evolve : state -> event -> state

public export
replayFrom :
  {h : Type -> Type} ->
  History h =>
  {event, state : Type} ->
  Projection event state =>
  state ->
  h event ->
  state
replayFrom start events = replay evolve start events

public export
hydrate :
  {h : Type -> Type} ->
  History h =>
  {event, state : Type} ->
  Projection event state =>
  h event ->
  state
hydrate = replayFrom (initial {event=event})

public export
interface (History h, Projection event state) =>
Decider (h : Type -> Type) (command, rejection, event, state : Type) | h, command, rejection, event where
  Legal : command -> state -> Type
  legal : (cmd : command) -> (st : state) -> Either rejection (Legal cmd st)
  decide : (cmd : command) -> (st : state) -> Legal cmd st -> h event

public export
decideR :
  {h : Type -> Type} ->
  {command, rejection, event, state : Type} ->
  Decider h command rejection event state =>
  command ->
  state ->
  Either rejection (h event)
decideR cmd st =
  case legal cmd st of
    Left rej => Left rej
    Right prf => Right (decide cmd st prf)

public export
update :
  {h : Type -> Type} ->
  {command, rejection, event, state : Type} ->
  Decider h command rejection event state =>
  command ->
  state ->
  Either rejection (state, h event)
update cmd st =
  case decideR {h} {command} {rejection} {event} {state} cmd st of
    Left rej => Left rej
    Right evs => Right (replayFrom st evs, evs)

public export
execute :
  {h : Type -> Type} ->
  {command, rejection, event, state : Type} ->
  Decider h command rejection event state =>
  h event ->
  command ->
  Either rejection (h event)
execute history cmd =
  decideR {h} {command} {rejection} {event} {state} cmd (hydrate history)
