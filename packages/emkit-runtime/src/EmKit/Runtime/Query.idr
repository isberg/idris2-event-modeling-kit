module EmKit.Runtime.Query

import EmKit.Runtime.Execute
import EmKit.Store.Core

%default total

keepJusts : List (Maybe value) -> List value
keepJusts [] = []
keepJusts (Nothing :: rest) = keepJusts rest
keepJusts (Just value :: rest) = value :: keepJusts rest

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
