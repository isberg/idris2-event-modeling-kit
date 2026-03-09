module EmKit.Store.Memory

import Control.Monad.Reader
import Control.Monad.Trans
import Data.IORef
import Data.List
import Data.SortedMap
import EmKit.Store.Core

%default total

public export
record Env stream ev where
  constructor MkEnv
  streams : IORef (SortedMap stream (List ev))
  subs : IORef (SortedMap stream (SortedMap Int (Nat -> List ev -> IO ())))
  catSubs : IORef (SortedMap Int (stream -> Bool, stream -> Nat -> List ev -> IO ()))
  nextId : IORef Int

public export
mkEnv : Ord stream => IO (Env stream ev)
mkEnv = do
  streams <- newIORef empty
  subs <- newIORef empty
  catSubs <- newIORef empty
  nextId <- newIORef 0
  pure (MkEnv streams subs catSubs nextId)

public export
App : Type -> Type -> Type -> Type
App stream ev a = ReaderT (Env stream ev) IO a

versionOf : List ev -> Nat
versionOf = length

eventsOf : Ord stream => stream -> SortedMap stream (List ev) -> List ev
eventsOf sid m = maybe [] id (lookup sid m)

streamIdsOf : SortedMap stream (List ev) -> List stream
streamIdsOf m = map fst (Data.SortedMap.toList m)

getSubs : Ord stream => stream -> SortedMap stream (SortedMap Int cb) -> SortedMap Int cb
getSubs sid m = maybe empty id (lookup sid m)

public export
implementation {stream', ev' : Type} -> Ord stream' => StreamCatalog (ReaderT (Env stream' ev') IO) stream' where
  listStreams = do
    env <- ask
    m <- lift $ readIORef env.streams
    pure (Right (streamIdsOf m))

public export
implementation {stream, ev : Type} -> Ord stream => Observable (ReaderT (Env stream ev) IO) stream ev where
  subscribe sid cb = do
    env <- ask
    i <- lift $ readIORef env.nextId
    lift $ writeIORef env.nextId (i + 1)

    let cbIO : Nat -> List ev -> IO ()
        cbIO from es = runReaderT env (cb from es)

    lift $ modifyIORef env.subs $ \m =>
      let byStream = getSubs sid m
          byStream' = insert i cbIO byStream
       in insert sid byStream' m

    pure $ do
      env2 <- ask
      lift $ modifyIORef env2.subs $ \m =>
        let byStream = getSubs sid m
            byStream' = delete i byStream
         in insert sid byStream' m

public export
implementation {stream, ev : Type} -> Ord stream => ObservableCategory (ReaderT (Env stream ev) IO) stream ev where
  subscribeCategory matches cb = do
    env <- ask
    i <- lift $ readIORef env.nextId
    lift $ writeIORef env.nextId (i + 1)

    let cbIO : stream -> Nat -> List ev -> IO ()
        cbIO sid from es = runReaderT env (cb sid from es)

    lift $ modifyIORef env.catSubs (insert i (matches, cbIO))

    pure $ do
      env2 <- ask
      lift $ modifyIORef env2.catSubs (delete i)

public export
implementation {stream', ev' : Type} -> Ord stream' => EventStore (ReaderT (Env stream' ev') IO) stream' ev' where
  load sid = do
    env <- ask
    m <- lift $ readIORef env.streams
    let es = eventsOf sid m
    case es of
      [] => pure (Left NoStream)
      _ => pure (Right (versionOf es, es))

  loadFrom sid from = do
    env <- ask
    m <- lift $ readIORef env.streams
    let es = eventsOf sid m
    case es of
      [] => pure (Left NoStream)
      _ =>
        let v = versionOf es
            tail = drop from es
         in pure (Right (v, tail))

  append sid expected newEs = do
    env <- ask
    m <- lift $ readIORef env.streams
    let oldEs = eventsOf sid m
    let v = versionOf oldEs

    if expected /= v
      then pure (Left Conflict)
      else do
        let es' = oldEs ++ newEs
        let v' = v + length newEs

        lift $ writeIORef env.streams (insert sid es' m)

        subsMap <- lift $ readIORef env.subs
        let byStream = getSubs sid subsMap
        let startVersion = v
        lift $ traverse_ (\cb => cb startVersion newEs) (values byStream)

        catSubsMap <- lift $ readIORef env.catSubs
        lift $
          traverse_
            (\(matches, cb) =>
              if matches sid
                then cb sid startVersion newEs
                else pure ())
            (values catSubsMap)

        pure (Right v')
