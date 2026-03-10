module EmKit.Backend.SSE

import Control.Monad.Reader
import Data.Buffer.Ext
import Data.IORef as IORef
import EmKit.Store.Core
import EmKit.Stream.SSE
import TyTTP
import TyTTP.HTTP

%default total

public export
ClientUnsubs : Type
ClientUnsubs = List (String, IO ())

public export
emptyClientUnsubs : ClientUnsubs
emptyClientUnsubs = []

findCleanup : String -> ClientUnsubs -> Maybe (IO ())
findCleanup _ [] = Nothing
findCleanup wanted ((key, cleanup) :: rest) =
  if key == wanted then Just cleanup else findCleanup wanted rest

replaceCleanup : String -> IO () -> ClientUnsubs -> ClientUnsubs
replaceCleanup key cleanup [] = [(key, cleanup)]
replaceCleanup key cleanup ((currentKey, currentCleanup) :: rest) =
  if currentKey == key
    then (key, cleanup) :: rest
    else (currentKey, currentCleanup) :: replaceCleanup key cleanup rest

registerCleanup : IORef.IORef ClientUnsubs -> String -> IO () -> IO ()
registerCleanup ref key cleanup = do
  current <- IORef.readIORef ref
  case findCleanup key current of
    Nothing => pure ()
    Just oldCleanup => oldCleanup
  IORef.writeIORef ref (replaceCleanup key cleanup current)

cleanupKey : String -> String -> String
cleanupKey streamId clientId = streamId ++ "::" ++ clientId

emitBatch : (Buffer -> IO ()) -> (Nat -> ev -> Buffer) -> Nat -> List ev -> IO ()
emitBatch _ _ _ [] = pure ()
emitBatch emit toBuffer version (event :: rest) = do
  let next = S version
  emit (toBuffer next event)
  emitBatch emit toBuffer next rest

emitCategoryBatch : (Buffer -> IO ()) -> (String -> Nat -> ev -> Buffer) -> String -> Nat -> List ev -> IO ()
emitCategoryBatch _ _ _ _ [] = pure ()
emitCategoryBatch emit toBuffer streamId version (event :: rest) = do
  let next = S version
  emit (toBuffer streamId next event)
  emitCategoryBatch emit toBuffer streamId next rest

replayExisting :
  {ev : Type} ->
  {ctx : Type} ->
  {auto es : EventStore (ReaderT ctx IO) String ev} ->
  ctx ->
  (Buffer -> IO ()) ->
  (Nat -> ev -> Buffer) ->
  String ->
  Maybe Nat ->
  IO ()
replayExisting env emit toBuffer streamId maybeLastEventId = do
  let loadAction : ReaderT ctx IO (Either LoadErr (Nat, List ev))
      loadAction =
        case maybeLastEventId of
          Nothing => load {m=ReaderT ctx IO} {stream=String} {ev=ev} streamId
          Just lastSeen => loadFrom {m=ReaderT ctx IO} {stream=String} {ev=ev} streamId lastSeen
  loaded <- runReaderT env loadAction
  case the (Either LoadErr (Nat, List ev)) loaded of
    Left NoStream => pure ()
    Left _ => pure ()
    Right (_, events) => emitBatch emit toBuffer (maybe 0 id maybeLastEventId) events

public export
subscribeStream :
  {ev : Type} ->
  {ctx : Type} ->
  {auto es : EventStore (ReaderT ctx IO) String ev} ->
  {auto obs : Observable (ReaderT ctx IO) String ev} ->
  ctx ->
  IORef.IORef ClientUnsubs ->
  (Nat -> ev -> Buffer) ->
  String ->
  String ->
  Maybe Nat ->
  Publisher IO e Buffer
subscribeStream env unsubsRef toBuffer streamId clientId maybeLastEventId =
  MkPublisher $ \subscriber => do
    subscriber.onNext (fromString sseConnectedCommentText)
    replayExisting env subscriber.onNext toBuffer streamId maybeLastEventId
    unsub <- runReaderT env $
      subscribe {m=ReaderT ctx IO} {stream=String} {ev=ev} streamId $ \startVersion, events =>
        liftIO (emitBatch subscriber.onNext toBuffer startVersion events)
    let cleanup = runReaderT env unsub
    registerCleanup unsubsRef (cleanupKey streamId clientId) cleanup
    pure ()

public export
subscribeCategoryLive :
  {ev : Type} ->
  {ctx : Type} ->
  {auto obs : ObservableCategory (ReaderT ctx IO) String ev} ->
  ctx ->
  IORef.IORef ClientUnsubs ->
  String ->
  (String -> Nat -> ev -> Buffer) ->
  (String -> Bool) ->
  String ->
  Publisher IO e Buffer
subscribeCategoryLive env unsubsRef scopeKey toBuffer matches clientId =
  MkPublisher $ \subscriber => do
    subscriber.onNext (fromString sseConnectedCommentText)
    unsub <- runReaderT env $
      subscribeCategory {m=ReaderT ctx IO} {stream=String} {ev=ev} matches $ \streamId, startVersion, events =>
        liftIO (emitCategoryBatch subscriber.onNext toBuffer streamId startVersion events)
    let cleanup = runReaderT env unsub
    registerCleanup unsubsRef (cleanupKey scopeKey clientId) cleanup
    pure ()
