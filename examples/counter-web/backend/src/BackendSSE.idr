module BackendSSE

import Control.Monad.Reader
import Data.Buffer.Ext
import Data.IORef as IORef
import Data.SortedMap as SortedMap
import EmKit.Store.Core
import EmKit.Stream.SSE
import TyTTP
import TyTTP.HTTP

%default total

public export
ClientUnsubs : Type
ClientUnsubs = SortedMap String (IO ())

public export
emptyClientUnsubs : ClientUnsubs
emptyClientUnsubs = SortedMap.empty

registerCleanup : IORef.IORef ClientUnsubs -> String -> IO () -> IO ()
registerCleanup ref clientId cleanup = do
  current <- IORef.readIORef ref
  case SortedMap.lookup clientId current of
    Nothing => pure ()
    Just oldCleanup => oldCleanup
  IORef.writeIORef ref (SortedMap.insert clientId cleanup current)

emitBatch : (Buffer -> IO ()) -> (Nat -> ev -> Buffer) -> Nat -> List ev -> IO ()
emitBatch _ _ _ [] = pure ()
emitBatch emit toBuffer version (event :: rest) = do
  let next = S version
  emit (toBuffer next event)
  emitBatch emit toBuffer next rest

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
    registerCleanup unsubsRef clientId cleanup
    pure ()
