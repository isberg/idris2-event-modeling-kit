module BackendMain

import Control.Monad.Reader
import Control.Monad.Trans
import Data.Buffer.Ext
import Data.IORef as IORef
import Data.SortedMap
import Data.String
import Domain
import EmKit.Backend.SSE
import EmKit.Sourcing.Projection
import EmKit.Runtime.Execute
import EmKit.Sourcing.Decider
import EmKit.Store.Core
import EmKit.Store.Memory as Memory
import EmKit.Stream.SSE
import JSON
import JSON.Simple
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
import WebApiTypes

%language ElabReflection
%default covering
%hide JSON.Parser.JSON

counterStreamId : String
counterStreamId = "counter-main"

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

snapshotFromStore : Memory.App String CounterEvent (Either String CounterSnapshotDto)
snapshotFromStore = do
  loaded <- loadHistoryOrEmpty {m=ReaderT (Memory.Env String CounterEvent) IO} {stream=String} {event=CounterEvent} counterStreamId
  pure $
    case loaded of
      Left err => Left (renderLoadErr err)
      Right (version, history) =>
        let view = project {event=CounterEvent} {model=CounterView} history in
          Right (toSnapshot version view history)

executeCommandInStore : Command -> Memory.App String CounterEvent CommandResponseDto
executeCommandInStore command = do
  result <- executeOnStream {m=ReaderT (Memory.Env String CounterEvent) IO} {stream=String} {command=Command} {rejection=Rejection} {event=CounterEvent} {state=CounterState} counterStreamId command
  pure $
    case result of
      Left err => MkCommandResponseDto False (renderRuntimeErr err) Nothing
      Right success => MkCommandResponseDto True "Command accepted." (Just (newVersion success))

frameLiveEvent : Nat -> CounterEvent -> Buffer
frameLiveEvent version event =
  let payload = SimpleToJSON.encode (toLiveEvent version event)
      frame = sseFrameText (Just (show version)) Nothing payload
  in fromString frame

readSnapshotP : Memory.Env String CounterEvent -> Promise Error IO CounterSnapshotDto
readSnapshotP env = promise $ \resolve, _ => do
  result <- runReaderT env snapshotFromStore
  case result of
    Left _ => resolve (toSnapshot 0 (initial {event=CounterEvent} {model=CounterView}) [])
    Right snapshot => resolve snapshot

runCommandP : Memory.Env String CounterEvent -> Command -> Promise Error IO CommandResponseDto
runCommandP env command = promise $ \resolve, _ => do
  response <- runReaderT env (executeCommandInStore command)
  resolve response

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
  Just folder <- currentDir | _ => putStrLn "There is no current folder."
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
      , get $ pattern "/api/events/{clientId}" $ \ctx =>
          case lookup "clientId" ctx.request.url.path.params of
            Nothing => sendText "Missing clientId." ctx >>= status BAD_REQUEST
            Just clientId =>
              let stream =
                    subscribeStream env unsubsRef frameLiveEvent counterStreamId clientId (lastEventIdFromHeaders ctx.request.headers)
               in pure $ MkContext ctx.request (MkResponse OK sseHeaders stream)
      , get $ pattern "/api/counter" $ \ctx => do
          snapshot <- liftPromise $ readSnapshotP env
          sendText (SimpleToJSON.encode snapshot) ctx >>= status OK
      , post
          $ pattern "/api/counter/create"
          $ consumes' [JSON] {a = String}
              (\ctx => sendText "Content cannot be parsed." ctx >>= status BAD_REQUEST)
              (\ctx => do
                response <- liftPromise $ runCommandP env (Create ctx.request.body)
                sendText (SimpleToJSON.encode response) ctx >>= status OK
              )
      , post $ pattern "/api/counter/increment" $ \ctx => do
          response <- liftPromise $ runCommandP env Increment
          sendText (SimpleToJSON.encode response) ctx >>= status OK
      , post $ pattern "/api/counter/decrement" $ \ctx => do
          response <- liftPromise $ runCommandP env Decrement
          sendText (SimpleToJSON.encode response) ctx >>= status OK
      ]
  putStrLn ("Counter web backend online at port " ++ show serverPort ++ ".")
