module BackendMain

import Control.Monad.Reader
import Control.Monad.Trans
import Data.Buffer.Ext
import Data.IORef as IORef
import Data.List
import Data.Maybe
import Data.String
import Domain
import Domain.JSON
import Domain.JSON.Simple
import EmKit.Backend.SSE
import EmKit.Runtime.Execute
import EmKit.Sourcing.Decider
import EmKit.Store.Core
import EmKit.Store.File as File
import EmKit.Store.Memory as Memory
import EmKit.Stream.SSE
import EmKit.Wire.Contracts
import EmKit.Wire.JSON
import EmKit.Wire.JSON.Simple
import JSON as StdJSON
import JSON.Simple.FromJSON as SimpleFromJSON
import JSON.Simple.ToJSON as SimpleToJSON
import Promise
import System
import System.Directory
import TyTTP
import TyTTP.Adapter.Node.HTTP
import TyTTP.Adapter.Node.Static
import TyTTP.HTTP
import TyTTP.HTTP.Consumer.JSON
import TyTTP.URL

%default covering
%hide JSON.Parser.JSON

data StorageMode = MemoryMode | FileMode String

data StoreBackend ev = UseMemory (Memory.Env String ev) | UseFile (File.Env ev)

record AppEnv ev where
  constructor MkAppEnv
  storageMode : StorageMode
  store : StoreBackend ev

TodoApp : Type -> Type -> Type
TodoApp ev a = ReaderT (AppEnv ev) IO a

findFileStorageArg : List String -> Maybe StorageMode
findFileStorageArg [] = Nothing
findFileStorageArg ("file" :: path :: _) = Just (FileMode path)
findFileStorageArg (_ :: rest) = findFileStorageArg rest

findPortArg : List String -> Maybe String
findPortArg [] = Nothing
findPortArg ("--port" :: value :: _) = Just value
findPortArg (_ :: rest) = findPortArg rest

parsePort : String -> Maybe Int
parsePort raw =
  case parseInteger (trim raw) of
    Nothing => Nothing
    Just n =>
      if n <= 0 || n > 65535
        then Nothing
        else Just (cast n)

isTodoStream : String -> Bool
isTodoStream streamId = isPrefixOf (unpack listPrefix) (unpack streamId)

runStore :
  AppEnv ev ->
  ReaderT (Memory.Env String ev) IO a ->
  ReaderT (File.Env ev) IO a ->
  IO a
runStore env memAction fileAction =
  case store env of
    UseMemory memEnv => runReaderT memEnv memAction
    UseFile fileEnv => runReaderT fileEnv fileAction

public export
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => EventStore (ReaderT (AppEnv ev) IO) String ev where
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
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => Observable (ReaderT (AppEnv ev) IO) String ev where
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
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => ObservableCategory (ReaderT (AppEnv ev) IO) String ev where
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
implementation {ev : Type} -> (SimpleFromJSON.FromJSON ev, SimpleToJSON.ToJSON ev) => StreamCatalog (ReaderT (AppEnv ev) IO) String where
  listStreams = do
    env <- ask
    lift $ runStore env
      (listStreams {m=ReaderT (Memory.Env String ev) IO} {stream=String})
      (listStreams {m=ReaderT (File.Env ev) IO} {stream=String})

findHeader : String -> List (String, String) -> Maybe String
findHeader _ [] = Nothing
findHeader wanted ((name, value) :: rest) =
  if toLower name == wanted
    then Just value
    else findHeader wanted rest

parseEventIdHeader : String -> Maybe Nat
parseEventIdHeader raw =
  case parseInteger (trim raw) of
    Nothing => Nothing
    Just n => if n < 0 then Nothing else Just (integerToNat n)

lastEventIdFromHeaders : List (String, String) -> Maybe Nat
lastEventIdFromHeaders headers =
  case findHeader "last-event-id" headers of
    Nothing => Nothing
    Just raw => parseEventIdHeader raw

renderLoadErr : LoadErr -> String
renderLoadErr NoStream = "stream does not exist."
renderLoadErr Corrupt = "stored events are corrupt."
renderLoadErr IOLoadError = "store load failed."

renderAppendErr : AppendErr -> String
renderAppendErr Conflict = "concurrency conflict while appending events."
renderAppendErr IOAppendError = "store append failed."

renderListStreamsErr : ListStreamsErr -> String
renderListStreamsErr IOListStreamsError = "listing streams failed."

renderRuntimeErr : RuntimeExecuteError Rejection -> String
renderRuntimeErr (RuntimeLoadFailed err) = "Load failed: " ++ renderLoadErr err
renderRuntimeErr (RuntimeRejected rejection) = renderRejection rejection
renderRuntimeErr RuntimeConflict = renderAppendErr Conflict
renderRuntimeErr (RuntimeAppendFailed err) = renderAppendErr err

runtimeStatus : RuntimeExecuteError Rejection -> Status
runtimeStatus RuntimeConflict = CONFLICT
runtimeStatus (RuntimeRejected _) = BAD_REQUEST
runtimeStatus (RuntimeLoadFailed _) = INTERNAL_SERVER_ERROR
runtimeStatus (RuntimeAppendFailed _) = INTERNAL_SERVER_ERROR

keepJusts : List (Maybe a) -> List a
keepJusts [] = []
keepJusts (Nothing :: rest) = keepJusts rest
keepJusts (Just value :: rest) = value :: keepJusts rest

listSummariesInStore : TodoApp TodoEvent (Either String (List TodoListSummary))
listSummariesInStore = do
  listed <- listStreams {m=ReaderT (AppEnv TodoEvent) IO} {stream=String}
  case listed of
    Left err => pure (Left (renderListStreamsErr err))
    Right streamIds => do
      summaries <- traverse loadSummary (filter isTodoStream streamIds)
      pure (Right (keepJusts summaries))
  where
    loadSummary : String -> TodoApp TodoEvent (Maybe TodoListSummary)
    loadSummary streamId = do
      loaded <- loadHistoryOrEmpty {m=ReaderT (AppEnv TodoEvent) IO} {stream=String} {event=TodoEvent} streamId
      pure $ case loaded of
        Left _ => Nothing
        Right (streamVersion, history) =>
          let summary = summaryFromEvents streamId streamVersion history in
            if exists summary then Just summary else Nothing

detailResyncInStore : String -> TodoApp TodoEvent (Either String (ResyncPayload TodoEvent))
detailResyncInStore streamId = do
  loaded <- loadHistoryOrEmpty {m=ReaderT (AppEnv TodoEvent) IO} {stream=String} {event=TodoEvent} streamId
  pure $ case loaded of
    Left err => Left (renderLoadErr err)
    Right (version, events) => Right (MkResyncPayload version events)

executeCommandInStore : String -> ExecutePayload Command -> TodoApp TodoEvent (Either (RuntimeExecuteError Rejection) Nat)
executeCommandInStore streamId payload = do
  result <- executeOnStreamExpected {m=ReaderT (AppEnv TodoEvent) IO} {stream=String} {command=Command} {rejection=Rejection} {event=TodoEvent} {state=TodoListState} streamId (expectedVersion payload) (command payload)
  pure (map newVersion result)

frameDetailEvent : Nat -> TodoEvent -> Buffer
frameDetailEvent version event =
  let payload = SimpleToJSON.encode (the (StreamEvent TodoEvent) (MkStreamEvent version event))
      frame = sseFrameText (Just (show version)) Nothing payload
   in fromString frame

frameOverviewEvent : String -> Nat -> TodoEvent -> Buffer
frameOverviewEvent streamId version event =
  let payload = SimpleToJSON.encode (the (MultiplexedStreamEvent String TodoEvent) (MkMultiplexedStreamEvent streamId version event))
      frame = sseFrameText Nothing Nothing payload
   in fromString frame

subscribeOverview : AppEnv TodoEvent -> IORef.IORef ClientUnsubs -> String -> Publisher IO e Buffer
subscribeOverview env unsubsRef clientId =
  subscribeCategoryLive env unsubsRef "overview" frameOverviewEvent isTodoStream clientId

readSummariesP : AppEnv TodoEvent -> Promise Error IO (List TodoListSummary)
readSummariesP env = promise $ \resolve, _ => do
  result <- runReaderT env listSummariesInStore
  case result of
    Left _ => resolve []
    Right summaries => resolve summaries

runResyncP : AppEnv TodoEvent -> String -> Promise Error IO (Either String (ResyncPayload TodoEvent))
runResyncP env streamId = promise $ \resolve, _ => do
  result <- runReaderT env (detailResyncInStore streamId)
  resolve result

runExecuteP : AppEnv TodoEvent -> String -> ExecutePayload Command -> Promise Error IO (Either (RuntimeExecuteError Rejection) Nat)
runExecuteP env streamId payload = promise $ \resolve, _ => do
  result <- runReaderT env (executeCommandInStore streamId payload)
  resolve result

initAppEnv : StorageMode -> IO (AppEnv TodoEvent)
initAppEnv MemoryMode = do
  memEnv <- Memory.mkEnv {stream=String} {ev=TodoEvent}
  pure (MkAppEnv MemoryMode (UseMemory memEnv))
initAppEnv (FileMode path) = do
  fileEnv <- File.mkEnv path
  pure (MkAppEnv (FileMode path) (UseFile fileEnv))

covering
main : IO ()
main = do
  args <- getArgs
  let storageMode = maybe MemoryMode id (findFileStorageArg args)
  serverPort <- case findPortArg args of
    Nothing => pure (the Int 3000)
    Just raw =>
      case parsePort raw of
        Nothing => do
          putStrLn ("Invalid --port value: " ++ raw ++ ". Expected integer in range 1..65535.")
          exitFailure
        Just port => pure port
  http <- HTTP.require
  current <- currentDir
  folder <- pure (maybe "." id current)
  env <- initAppEnv storageMode
  unsubsRef <- IORef.newIORef emptyClientUnsubs
  let options : TyTTP.Adapter.Node.HTTP.Options Error
      options =
        { listenOptions :=
            { port := Just serverPort
            } Listen.defaultOptions
        } defaultOptions
  _ <- HTTP.listen http options
    $ parseUrl' (const $ sendText "URL has invalid format" >=> status BAD_REQUEST) {m = Promise Error IO}
    $ routes' (sendText "Not Found" >=> status NOT_FOUND)
      [ get $ pattern "/" $ \ctx =>
          sendText "Open /static/index.html" ctx >>= status OK
      , get $ pattern "/health" $ \ctx =>
          sendText "OK" ctx >>= status OK
      , get $ pattern "/static/*" :> hStatic "\{folder}/static/" $ flip $ \ctx =>
          \case
            StatError _ =>
              sendText "File error while serving static content." ctx >>= status INTERNAL_SERVER_ERROR
            NotAFile path =>
              sendText ("Could not find file: " ++ path) ctx >>= status NOT_FOUND
      , get $ pattern "/api/todo/lists" $ \ctx => do
          summaries <- liftPromise $ readSummariesP env
          sendText (SimpleToJSON.encode summaries) ctx >>= status OK
      , get $ pattern "/api/todo/overview-events/{clientId}" $ \ctx =>
          case lookup "clientId" ctx.request.url.path.params of
            Nothing => sendText "Missing clientId." ctx >>= status BAD_REQUEST
            Just clientId =>
              pure $ MkContext ctx.request (MkResponse OK sseHeaders (subscribeOverview env unsubsRef clientId))
      , get $ pattern "/api/todo/events/{listId}/{clientId}" $ \ctx =>
          case (lookup "listId" ctx.request.url.path.params, lookup "clientId" ctx.request.url.path.params) of
            (Just listId, Just clientId) =>
              if isTodoStream listId
                then
                  let stream = subscribeStream env unsubsRef frameDetailEvent listId clientId (lastEventIdFromHeaders ctx.request.headers)
                   in pure $ MkContext ctx.request (MkResponse OK sseHeaders stream)
                else sendText ("Unknown stream: " ++ listId) ctx >>= status BAD_REQUEST
            _ => sendText "Missing listId or clientId." ctx >>= status BAD_REQUEST
      , get $ pattern "/api/todo/resync/{listId}" $ \ctx =>
          case lookup "listId" ctx.request.url.path.params of
            Nothing => sendText "Missing listId." ctx >>= status BAD_REQUEST
            Just listId =>
              if isTodoStream listId
                then do
                  result <- liftPromise $ runResyncP env listId
                  case result of
                    Left err => sendText err ctx >>= status INTERNAL_SERVER_ERROR
                    Right payload => sendText (SimpleToJSON.encode payload) ctx >>= status OK
                else sendText ("Unknown stream: " ++ listId) ctx >>= status BAD_REQUEST
      , post
          $ pattern "/api/todo/execute/{listId}"
          $ consumes' [JSON] {a = ExecutePayload Command}
              (\ctx => sendText "Content cannot be parsed." ctx >>= status BAD_REQUEST)
              (\ctx =>
                case lookup "listId" ctx.request.url.path.params of
                  Nothing => sendText "Missing listId." ctx >>= status BAD_REQUEST
                  Just listId =>
                    if isTodoStream listId
                      then do
                        result <- liftPromise $ runExecuteP env listId ctx.request.body
                        case result of
                          Left err => sendText (renderRuntimeErr err) ctx >>= status (runtimeStatus err)
                          Right _ => sendText "OK" ctx >>= status OK
                      else sendText ("Unknown stream: " ++ listId) ctx >>= status BAD_REQUEST)
      ]
  case storageMode of
    MemoryMode => putStrLn ("Todo web backend online at port " ++ show serverPort ++ " (memory mode).")
    FileMode path => putStrLn ("Todo web backend online at port " ++ show serverPort ++ " (file mode: " ++ path ++ ").")
