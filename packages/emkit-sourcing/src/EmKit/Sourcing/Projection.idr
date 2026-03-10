module EmKit.Sourcing.Projection

import public EmKit.Sourcing.History

%default total

public export
interface Projection (event, model : Type) where
  initial : model
  evolve : model -> event -> model

public export
projectFrom :
  {h : Type -> Type} ->
  History h =>
  {event, model : Type} ->
  Projection event model =>
  model ->
  h event ->
  model
projectFrom start events = replay evolve start events

public export
project :
  {h : Type -> Type} ->
  History h =>
  {event, model : Type} ->
  Projection event model =>
  h event ->
  model
project = projectFrom (initial {event=event})
