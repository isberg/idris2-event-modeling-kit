module EmKit.Runtime.Execute

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
        Right (version, project {h=List} {event=event} {model=state} history)

public export
projectStreamModel :
  {m : Type -> Type} ->
  {stream, event, model : Type} ->
  Monad m =>
  EventStore m stream event =>
  Projection event model =>
  stream ->
  m (Either LoadErr (Nat, model))
projectStreamModel streamId = do
  loaded <- loadHistoryOrEmpty {m} {stream} {event} streamId
  pure $
    case loaded of
      Left err => Left err
      Right (version, history) => Right (version, project history)

mutual
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
        executeAgainstLoaded streamId version history cmd

  executeAgainstLoaded :
    {m : Type -> Type} ->
    {stream, command, rejection, event, state : Type} ->
    Monad m =>
    EventStore m stream event =>
    Decider List command rejection event state =>
    stream ->
    Nat ->
    List event ->
    command ->
    m (Either (RuntimeExecuteError rejection) (RuntimeExecuteSuccess event state))
  executeAgainstLoaded streamId version history cmd = do
    let currentState = project {h=List} {event=event} {model=state} history
    case decideR {h=List} {command=command} {rejection=rejection} {event=event} {state=state} cmd currentState of
      Left domainRejection => pure (Left (RuntimeRejected domainRejection))
      Right events => do
        appended <- append streamId version events
        pure $
          case appended of
            Left Conflict => Left RuntimeConflict
            Left err => Left (RuntimeAppendFailed err)
            Right newVersion =>
              let nextState = projectFrom {h=List} {event=event} {model=state} currentState events
               in Right (MkRuntimeExecuteSuccess version newVersion events nextState)

  public export
  executeOnStreamExpected :
    {m : Type -> Type} ->
    {stream, command, rejection, event, state : Type} ->
    Monad m =>
    EventStore m stream event =>
    Decider List command rejection event state =>
    stream ->
    Nat ->
    command ->
    m (Either (RuntimeExecuteError rejection) (RuntimeExecuteSuccess event state))
  executeOnStreamExpected streamId expectedVersion cmd = do
    loaded <- loadHistoryOrEmpty {m} {stream} {event} streamId
    case loaded of
      Left err => pure (Left (RuntimeLoadFailed err))
      Right (version, history) =>
        if expectedVersion == version
          then executeAgainstLoaded streamId version history cmd
          else pure (Left RuntimeConflict)
