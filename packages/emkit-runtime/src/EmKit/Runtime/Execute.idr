module EmKit.Runtime.Execute

import EmKit.Modeling.Pattern.StateView
import EmKit.Sourcing.Decider
import EmKit.Store.Core

%default total

public export
data RuntimeExecuteError rejection
  = RuntimeLoadFailed LoadErr
  | RuntimeRejected rejection
  | RuntimeConflict
  | RuntimeAppendFailed AppendErr

public export
record RuntimeExecuteSuccess event state where
  constructor MkRuntimeExecuteSuccess
  previousVersion : Nat
  newVersion : Nat
  emittedEvents : List event
  resultingState : state

public export
loadHistoryOrEmpty :
  {m : Type -> Type} ->
  {stream, event : Type} ->
  Monad m =>
  EventStore m stream event =>
  stream ->
  m (Either LoadErr (Nat, List event))
loadHistoryOrEmpty streamId = do
  loaded <- load streamId
  pure $
    case loaded of
      Left NoStream => Right (0, [])
      Left err => Left err
      Right history => Right history

public export
loadStateOrInitial :
  {m : Type -> Type} ->
  {stream, event, state : Type} ->
  Monad m =>
  EventStore m stream event =>
  Projection event state =>
  stream ->
  m (Either LoadErr (Nat, state))
loadStateOrInitial streamId = do
  loaded <- loadHistoryOrEmpty {m} {stream} {event} streamId
  pure $
    case loaded of
      Left err => Left err
      Right (version, history) =>
        Right (version, hydrate {h=List} {event=event} {state=state} history)

public export
projectStreamView :
  {m : Type -> Type} ->
  {stream, event, view : Type} ->
  Monad m =>
  EventStore m stream event =>
  StateView event view =>
  stream ->
  m (Either LoadErr (Nat, view))
projectStreamView streamId = do
  loaded <- loadHistoryOrEmpty {m} {stream} {event} streamId
  pure $
    case loaded of
      Left err => Left err
      Right (version, history) => Right (version, projectFromList history)

public export
executeOnStream :
  {m : Type -> Type} ->
  {stream, command, rejection, event, state : Type} ->
  Monad m =>
  EventStore m stream event =>
  Decider List command rejection event state =>
  stream ->
  command ->
  m (Either (RuntimeExecuteError rejection) (RuntimeExecuteSuccess event state))
executeOnStream streamId cmd = do
  loaded <- loadHistoryOrEmpty {m} {stream} {event} streamId
  case loaded of
    Left err => pure (Left (RuntimeLoadFailed err))
    Right (version, history) =>
      let currentState = hydrate {h=List} {event=event} {state=state} history in
      case decideR {h=List} {command=command} {rejection=rejection} {event=event} {state=state} cmd currentState of
        Left domainRejection => pure (Left (RuntimeRejected domainRejection))
        Right events => do
          appended <- append streamId version events
          pure $
            case appended of
              Left Conflict => Left RuntimeConflict
              Left err => Left (RuntimeAppendFailed err)
              Right newVersion =>
                let nextState = replayFrom currentState events
                 in Right (MkRuntimeExecuteSuccess version newVersion events nextState)
