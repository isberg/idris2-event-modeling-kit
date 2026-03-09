module EmKit.Modeling.Pattern.CommandStateChange

import public EmKit.Sourcing.Decider

%default total

public export
interface
  Decider h command rejection event state =>
  CommandStateChange (h : Type -> Type) (command, rejection, event, state : Type)
    | h, command, rejection, event where

public export
currentState :
  {h : Type -> Type} ->
  {command, rejection, event, state : Type} ->
  CommandStateChange h command rejection event state =>
  h event ->
  state
currentState = hydrate

public export
applyCommand :
  {h : Type -> Type} ->
  {command, rejection, event, state : Type} ->
  CommandStateChange h command rejection event state =>
  h event ->
  command ->
  Either rejection (h event)
applyCommand = execute

public export
previewCommand :
  {h : Type -> Type} ->
  {command, rejection, event, state : Type} ->
  CommandStateChange h command rejection event state =>
  h event ->
  command ->
  Either rejection (state, h event)
previewCommand {h} {command} {rejection} {event} {state} history cmd =
  update {h} {command} {rejection} {event} {state} cmd
    (currentState {h} {command} {rejection} {event} {state} history)
