module EmKit.Backend.StoreApp

import Control.Monad.Reader
import Control.Monad.Trans
import Data.String
import EmKit.Store.Core
import EmKit.Store.File as File
import EmKit.Store.Memory as Memory
import JSON.Simple.FromJSON as SimpleFromJSON
import JSON.Simple.ToJSON as SimpleToJSON

%default total

public export
data StorageMode = MemoryMode | FileMode String

public export
data StoreBackend ev = UseMemory (Memory.Env String ev) | UseFile (File.Env ev)

public export
record StoreAppEnv ev where
  constructor MkStoreAppEnv
  storageMode : StorageMode
  store : StoreBackend ev

public export
findFileStorageArg : List String -> Maybe StorageMode
findFileStorageArg [] = Nothing
findFileStorageArg ("file" :: path :: _) = Just (FileMode path)
findFileStorageArg (_ :: rest) = findFileStorageArg rest

public export
findPortArg : List String -> Maybe String
findPortArg [] = Nothing
findPortArg ("--port" :: value :: _) = Just value
findPortArg (_ :: rest) = findPortArg rest

public export
parsePort : String -> Maybe Int
parsePort raw =
  case parseInteger (trim raw) of
    Nothing => Nothing
    Just n =>
      if n <= 0 || n > 65535
        then Nothing
        else Just (cast n)

public export
runStore :
  StoreAppEnv ev ->
  ReaderT (Memory.Env String ev) IO a ->
  ReaderT (File.Env ev) IO a ->
  IO a
runStore env memAction fileAction =
  case store env of
    UseMemory memEnv => runReaderT memEnv memAction
    UseFile fileEnv => runReaderT fileEnv fileAction

public export
initStoreAppEnv : (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => StorageMode -> IO (StoreAppEnv ev)
initStoreAppEnv MemoryMode = do
  memEnv <- Memory.mkEnv {stream=String} {ev=ev}
  pure (MkStoreAppEnv MemoryMode (UseMemory memEnv))
initStoreAppEnv (FileMode path) = do
  fileEnv <- File.mkEnv path
  pure (MkStoreAppEnv (FileMode path) (UseFile fileEnv))

public export
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => EventStore (ReaderT (StoreAppEnv ev) IO) String ev where
  load streamId = do
    env <- ask
    lift $ runStore env
      (load {m=ReaderT (Memory.Env String ev) IO} {stream=String} {ev=ev} streamId)
      (load {m=ReaderT (File.Env ev) IO} {stream=String} {ev=ev} streamId)

  loadFrom streamId from = do
    env <- ask
    lift $ runStore env
      (loadFrom {m=ReaderT (Memory.Env String ev) IO} {stream=String} {ev=ev} streamId from)
      (loadFrom {m=ReaderT (File.Env ev) IO} {stream=String} {ev=ev} streamId from)

  append streamId expected newEvents = do
    env <- ask
    lift $ runStore env
      (append {m=ReaderT (Memory.Env String ev) IO} {stream=String} {ev=ev} streamId expected newEvents)
      (append {m=ReaderT (File.Env ev) IO} {stream=String} {ev=ev} streamId expected newEvents)

public export
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => Observable (ReaderT (StoreAppEnv ev) IO) String ev where
  subscribe streamId callback = do
    env <- ask
    case store env of
      UseMemory memEnv => do
        let wrapped : Nat -> List ev -> ReaderT (Memory.Env String ev) IO ()
            wrapped from events = lift $ runReaderT env (callback from events)
        unsub <- lift $ runReaderT memEnv (EmKit.Store.Core.subscribe {m=ReaderT (Memory.Env String ev) IO} {stream=String} {ev=ev} streamId wrapped)
        pure (do _ <- ask; lift $ runReaderT memEnv unsub)
      UseFile fileEnv => do
        let wrapped : Nat -> List ev -> ReaderT (File.Env ev) IO ()
            wrapped from events = lift $ runReaderT env (callback from events)
        unsub <- lift $ runReaderT fileEnv (EmKit.Store.Core.subscribe {m=ReaderT (File.Env ev) IO} {stream=String} {ev=ev} streamId wrapped)
        pure (do _ <- ask; lift $ runReaderT fileEnv unsub)

public export
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => ObservableCategory (ReaderT (StoreAppEnv ev) IO) String ev where
  subscribeCategory matches callback = do
    env <- ask
    case store env of
      UseMemory memEnv => do
        let wrapped : String -> Nat -> List ev -> ReaderT (Memory.Env String ev) IO ()
            wrapped streamId from events = lift $ runReaderT env (callback streamId from events)
        unsub <- lift $ runReaderT memEnv (EmKit.Store.Core.subscribeCategory {m=ReaderT (Memory.Env String ev) IO} {stream=String} {ev=ev} matches wrapped)
        pure (do _ <- ask; lift $ runReaderT memEnv unsub)
      UseFile fileEnv => do
        let wrapped : String -> Nat -> List ev -> ReaderT (File.Env ev) IO ()
            wrapped streamId from events = lift $ runReaderT env (callback streamId from events)
        unsub <- lift $ runReaderT fileEnv (EmKit.Store.Core.subscribeCategory {m=ReaderT (File.Env ev) IO} {stream=String} {ev=ev} matches wrapped)
        pure (do _ <- ask; lift $ runReaderT fileEnv unsub)

public export
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => StreamCatalog (ReaderT (StoreAppEnv ev) IO) String where
  listStreams = do
    env <- ask
    lift $ runStore env
      (listStreams {m=ReaderT (Memory.Env String ev) IO} {stream=String})
      (listStreams {m=ReaderT (File.Env ev) IO} {stream=String})
