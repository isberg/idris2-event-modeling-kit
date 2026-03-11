module BackendMain

import Control.Monad.Reader
import Data.Buffer.Ext
import Data.IORef as IORef
import Data.String
import Domain
import Domain.JSON
import Domain.JSON.Simple
import EmKit.Backend.SSE
import EmKit.Backend.StoreApp
import EmKit.Runtime.Execute
import EmKit.Sourcing.Decider
import EmKit.Sourcing.Projection
import EmKit.Store.Core
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

StarterApp : Type -> Type -> Type
StarterApp ev a = ReaderT (StoreAppEnv ev) IO a

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

viewInStore : StarterApp CounterEvent (Either String CounterModel)
viewInStore = do
  loaded <- loadHistoryOrEmpty {m=ReaderT (StoreAppEnv CounterEvent) IO} {stream=String} {event=CounterEvent} counterStreamId
  pure $ case loaded of
    Left err => Left (renderLoadErr err)
    Right (_, events) => Right (project {h=List} events)

detailResyncInStore : StarterApp CounterEvent (Either String (ResyncPayload CounterEvent))
detailResyncInStore = do
  loaded <- loadHistoryOrEmpty {m=ReaderT (StoreAppEnv CounterEvent) IO} {stream=String} {event=CounterEvent} counterStreamId
  pure $ case loaded of
    Left err => Left (renderLoadErr err)
    Right (version, events) => Right (MkResyncPayload version events)

executeCommandInStore : ExecutePayload Command -> StarterApp CounterEvent (Either (RuntimeExecuteError Rejection) Nat)
executeCommandInStore payload = do
  result <- executeOnStreamExpected {m=ReaderT (StoreAppEnv CounterEvent) IO} {stream=String} {command=Command} {rejection=Rejection} {event=CounterEvent} {state=CounterModel} counterStreamId (expectedVersion payload) (command payload)
  pure (map newVersion result)

frameEvent : Nat -> CounterEvent -> Buffer
frameEvent version event =
  let payload = SimpleToJSON.encode (the (StreamEvent CounterEvent) (MkStreamEvent version event))
      frame = sseFrameText (Just (show version)) Nothing payload
  in fromString frame

runViewP : StoreAppEnv CounterEvent -> Promise Error IO (Either String CounterModel)
runViewP env = promise $ \resolve, _ => do
  result <- runReaderT env viewInStore
  resolve result

runResyncP : StoreAppEnv CounterEvent -> Promise Error IO (Either String (ResyncPayload CounterEvent))
runResyncP env = promise $ \resolve, _ => do
  result <- runReaderT env detailResyncInStore
  resolve result

runExecuteP : StoreAppEnv CounterEvent -> ExecutePayload Command -> Promise Error IO (Either (RuntimeExecuteError Rejection) Nat)
runExecuteP env payload = promise $ \resolve, _ => do
  result <- runReaderT env (executeCommandInStore payload)
  resolve result

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
  env <- initStoreAppEnv storageMode
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
      , get $ pattern "/api/counter/view" $ \ctx => do
          result <- liftPromise $ runViewP env
          case result of
            Left err => sendText err ctx >>= status INTERNAL_SERVER_ERROR
            Right currentModel => sendText (SimpleToJSON.encode currentModel) ctx >>= status OK
      , get $ pattern "/api/counter/resync" $ \ctx => do
          result <- liftPromise $ runResyncP env
          case result of
            Left err => sendText err ctx >>= status INTERNAL_SERVER_ERROR
            Right payload => sendText (SimpleToJSON.encode payload) ctx >>= status OK
      , get $ pattern "/api/counter/events/{clientId}" $ \ctx =>
          case lookup "clientId" ctx.request.url.path.params of
            Nothing => sendText "Missing clientId." ctx >>= status BAD_REQUEST
            Just clientId =>
              let stream = subscribeStream env unsubsRef frameEvent counterStreamId clientId (lastEventIdFromHeaders ctx.request.headers)
              in pure $ MkContext ctx.request (MkResponse OK sseHeaders stream)
      , post
          $ pattern "/api/counter/execute"
          $ consumes' [JSON] {a = ExecutePayload Command}
              (\ctx => sendText "Content cannot be parsed." ctx >>= status BAD_REQUEST)
              (\ctx => do
                result <- liftPromise $ runExecuteP env ctx.request.body
                case result of
                  Left err => sendText (renderRuntimeErr err) ctx >>= status (runtimeStatus err)
                  Right _ => sendText "OK" ctx >>= status OK)
      ]
  case storageMode of
    MemoryMode => putStrLn ("Web single-stream starter online at port " ++ show serverPort ++ " (memory mode).")
    FileMode path => putStrLn ("Web single-stream starter online at port " ++ show serverPort ++ " (file mode: " ++ path ++ ").")
