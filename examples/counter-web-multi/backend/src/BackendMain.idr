module BackendMain

import EmKit.Backend.SSE
import Control.Monad.Reader
import Data.Buffer.Ext
import Data.IORef as IORef
import Data.List
import Data.SortedMap as SortedMap
import Data.String
import Domain
import Domain.JSON
import Domain.JSON.Simple
import EmKit.Runtime.Execute
import EmKit.Sourcing.Decider
import EmKit.Store.Core
import EmKit.Store.Memory as Memory
import EmKit.Stream.SSE
import EmKit.Wire.Contracts
import EmKit.Wire.JSON
import EmKit.Wire.JSON.Simple
import JSON
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

streamIds : List String
streamIds = ["counter-a", "counter-b", "counter-c"]

isKnownStream : String -> Bool
isKnownStream streamId = elem streamId streamIds

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

findHeader : String -> List (String, String) -> Maybe String
findHeader _ [] = Nothing
findHeader wanted ((name, value) :: rest) =
  if toLower name == wanted then Just value else findHeader wanted rest

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

frameStreamEvent : Nat -> CounterEvent -> Buffer
frameStreamEvent version event =
  let payload = SimpleToJSON.encode (the (StreamEvent CounterEvent) (MkStreamEvent version event))
      frame = sseFrameText (Just (show version)) Nothing payload
   in fromString frame

executeCommandInStore : String -> ExecutePayload Command -> Memory.App String CounterEvent (Either (RuntimeExecuteError Rejection) Nat)
executeCommandInStore streamId payload = do
  result <- executeOnStreamExpected {m=ReaderT (Memory.Env String CounterEvent) IO} {stream=String} {command=Command} {rejection=Rejection} {event=CounterEvent} {state=State} streamId (expectedVersion payload) (command payload)
  pure (map newVersion result)

runExecuteP : Memory.Env String CounterEvent -> String -> ExecutePayload Command -> Promise Error IO (Either (RuntimeExecuteError Rejection) Nat)
runExecuteP env streamId payload = promise $ \resolve, _ => do
  result <- runReaderT env (executeCommandInStore streamId payload)
  resolve result

resyncPayloadInStore : String -> Memory.App String CounterEvent (Either String (ResyncPayload CounterEvent))
resyncPayloadInStore streamId = do
  loaded <- loadHistoryOrEmpty {m=ReaderT (Memory.Env String CounterEvent) IO} {stream=String} {event=CounterEvent} streamId
  pure $ case loaded of
    Left err => Left (renderLoadErr err)
    Right (version, events) => Right (MkResyncPayload version events)

runResyncP : Memory.Env String CounterEvent -> String -> Promise Error IO (Either String (ResyncPayload CounterEvent))
runResyncP env streamId = promise $ \resolve, _ => do
  result <- runReaderT env (resyncPayloadInStore streamId)
  resolve result

loadCount : Memory.Env String CounterEvent -> String -> IO Nat
loadCount env streamId = do
  loaded <- runReaderT env (loadStateOrInitial {m=ReaderT (Memory.Env String CounterEvent) IO} {stream=String} {event=CounterEvent} {state=State} streamId)
  pure $ case loaded of
    Left _ => 0
    Right (_, count) => count

readTotalP : Memory.Env String CounterEvent -> Promise Error IO String
readTotalP env = promise $ \resolve, _ => do
  counts <- traverse (loadCount env) streamIds
  resolve (show (sum counts))

covering
main : IO ()
main = do
  args <- getArgs
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
  env <- Memory.mkEnv {stream=String} {ev=CounterEvent}
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
      , get $ pattern "/api/counter/events/{streamId}/{clientId}" $ \ctx =>
          case (lookup "streamId" ctx.request.url.path.params, lookup "clientId" ctx.request.url.path.params) of
            (Just streamId, Just clientId) =>
              if isKnownStream streamId
                then
                  let stream = subscribeStream env unsubsRef frameStreamEvent streamId clientId (lastEventIdFromHeaders ctx.request.headers)
                   in pure $ MkContext ctx.request (MkResponse OK sseHeaders stream)
                else sendText ("Unknown stream: " ++ streamId) ctx >>= status BAD_REQUEST
            _ => sendText "Missing streamId or clientId." ctx >>= status BAD_REQUEST
      , post
          $ pattern "/api/counter/execute/{streamId}"
          $ consumes' [JSON] {a = ExecutePayload Command}
              (\ctx => sendText "Content cannot be parsed." ctx >>= status BAD_REQUEST)
              (\ctx =>
                case lookup "streamId" ctx.request.url.path.params of
                  Nothing => sendText "Missing streamId." ctx >>= status BAD_REQUEST
                  Just streamId =>
                    if isKnownStream streamId
                      then do
                        result <- liftPromise $ runExecuteP env streamId ctx.request.body
                        case result of
                          Left err => sendText (renderRuntimeErr err) ctx >>= status (runtimeStatus err)
                          Right _ => sendText "OK" ctx >>= status OK
                      else sendText ("Unknown stream: " ++ streamId) ctx >>= status BAD_REQUEST)
      , get $ pattern "/api/counter/resync/{streamId}" $ \ctx =>
          case lookup "streamId" ctx.request.url.path.params of
            Nothing => sendText "Missing streamId." ctx >>= status BAD_REQUEST
            Just streamId =>
              if isKnownStream streamId
                then do
                  result <- liftPromise $ runResyncP env streamId
                  case result of
                    Left err => sendText err ctx >>= status INTERNAL_SERVER_ERROR
                    Right payload => sendText (SimpleToJSON.encode payload) ctx >>= status OK
                else sendText ("Unknown stream: " ++ streamId) ctx >>= status BAD_REQUEST
      ]
  putStrLn ("Counter multi web backend online at port " ++ show serverPort ++ ".")
