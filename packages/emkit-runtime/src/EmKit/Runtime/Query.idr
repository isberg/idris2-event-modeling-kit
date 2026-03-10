module EmKit.Runtime.Query

import EmKit.Runtime.Execute
import EmKit.Store.Core

%default total

keepJusts : List (Maybe value) -> List value
keepJusts [] = []
keepJusts (Nothing :: rest) = keepJusts rest
keepJusts (Just value :: rest) = value :: keepJusts rest

public export
data ProjectedSummaryError
  = ProjectedSummaryListFailed ListStreamsErr
  | ProjectedSummaryLoadFailed LoadErr

public export
listProjectedSummaries :
  {m : Type -> Type} ->
  {stream, event, summary : Type} ->
  Monad m =>
  StreamCatalog m stream =>
  EventStore m stream event =>
  (matches : stream -> Bool) ->
  (project : stream -> Nat -> List event -> summary) ->
  (include : summary -> Bool) ->
  m (Either ListStreamsErr (List summary))
listProjectedSummaries matches project include = do
  listed <- listStreams
  case listed of
    Left err => pure (Left err)
    Right streamIds => do
      summaries <- traverse loadSummary (filter matches streamIds)
      pure (Right (keepJusts summaries))
  where
    loadSummary : stream -> m (Maybe summary)
    loadSummary streamId = do
      loaded <- loadHistoryOrEmpty {m} {stream} {event} streamId
      pure $
        case loaded of
          Left _ => Nothing
          Right (streamVersion, history) =>
            let summary = project streamId streamVersion history in
            if include summary then Just summary else Nothing

public export
listMappedProjectedSummaries :
  {m : Type -> Type} ->
  {stream, storedEvent, localEvent, summary : Type} ->
  Monad m =>
  StreamCatalog m stream =>
  EventStore m stream storedEvent =>
  (decode : storedEvent -> Either LoadErr localEvent) ->
  (matches : stream -> Bool) ->
  (project : stream -> Nat -> List localEvent -> summary) ->
  (include : summary -> Bool) ->
  m (Either ProjectedSummaryError (List summary))
listMappedProjectedSummaries decode matches project include = do
  listed <- listStreams
  case listed of
    Left err => pure (Left (ProjectedSummaryListFailed err))
    Right streamIds => do
      summaries <- traverse loadSummary (filter matches streamIds)
      pure $
        case sequenceMapped summaries of
          Left err => Left err
          Right values => Right (keepJusts values)
  where
    loadSummary : stream -> m (Either ProjectedSummaryError (Maybe summary))
    loadSummary streamId = do
      loaded <- loadMappedHistoryOrEmpty {m} {stream} {storedEvent} {localEvent} decode streamId
      pure $
        case loaded of
          Left err => Left (ProjectedSummaryLoadFailed err)
          Right (streamVersion, history) =>
            let summary = project streamId streamVersion history in
            Right (if include summary then Just summary else Nothing)

    sequenceMapped : List (Either ProjectedSummaryError value) -> Either ProjectedSummaryError (List value)
    sequenceMapped [] = Right []
    sequenceMapped (Left err :: _) = Left err
    sequenceMapped (Right value :: rest) =
      case sequenceMapped rest of
        Left err => Left err
        Right values => Right (value :: values)
