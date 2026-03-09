module EmKit.Modeling.Pattern.StateView

import public EmKit.Sourcing.History

%default total

public export
interface StateView (event, view : Type) where
  initialView : view
  projectEvent : view -> event -> view

public export
projectFromList :
  {event, view : Type} ->
  {auto sv : StateView event view} ->
  List event ->
  view
projectFromList {sv} events = foldl (projectEvent @{sv}) (initialView @{sv}) events

public export
projectFromHistory :
  {h : Type -> Type} ->
  {event, view : Type} ->
  History h =>
  {auto sv : StateView event view} ->
  h event ->
  view
projectFromHistory {sv} history = replay (projectEvent @{sv}) (initialView @{sv}) history

public export
projectFromHistoryStarting :
  {h : Type -> Type} ->
  {event, view : Type} ->
  History h =>
  {auto sv : StateView event view} ->
  view ->
  h event ->
  view
projectFromHistoryStarting {sv} start history = replay (projectEvent @{sv}) start history
