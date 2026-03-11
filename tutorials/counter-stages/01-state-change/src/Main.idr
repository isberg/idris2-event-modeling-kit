module Main

import Control.Monad.Reader
import Control.Monad.Trans
import Data.String
import Domain
import EmKit.Sourcing.Decider
import EmKit.Sourcing.Projection
import EmKit.Runtime.Execute
import EmKit.Store.Core
import EmKit.Store.Memory as Memory

%default covering

streamId : String
streamId = "counter-main"

renderLoadErr : LoadErr -> String
renderLoadErr NoStream = "stream does not exist."
renderLoadErr Corrupt = "stored events are corrupt."
renderLoadErr IOLoadError = "store load failed."

renderAppendErr : AppendErr -> String
renderAppendErr Conflict = "concurrency conflict while appending events."
renderAppendErr IOAppendError = "store append failed."

renderRuntimeErr : RuntimeExecuteError Rejection -> String
renderRuntimeErr (RuntimeLoadFailed err) = "Load failed: " ++ renderLoadErr err
renderRuntimeErr (RuntimeRejected rejection) = "Rejected: " ++ renderRejection rejection
renderRuntimeErr RuntimeConflict = "Append failed: " ++ renderAppendErr Conflict
renderRuntimeErr (RuntimeAppendFailed err) = "Append failed: " ++ renderAppendErr err

renderEvents : List CounterEvent -> String
renderEvents [] = "[]"
renderEvents (Created title :: rest) = "[Created(" ++ title ++ ")" ++ restText rest
  where
    showEvent : CounterEvent -> String
    showEvent (Created raw) = "Created(" ++ raw ++ ")"
    showEvent Incremented = "Incremented"
    showEvent Decremented = "Decremented"

    restText : List CounterEvent -> String
    restText [] = "]"
    restText (event :: xs) = ", " ++ showEvent event ++ restText xs
renderEvents (Incremented :: rest) = "[Incremented" ++ restText rest
  where
    showEvent : CounterEvent -> String
    showEvent (Created raw) = "Created(" ++ raw ++ ")"
    showEvent Incremented = "Incremented"
    showEvent Decremented = "Decremented"

    restText : List CounterEvent -> String
    restText [] = "]"
    restText (event :: xs) = ", " ++ showEvent event ++ restText xs
renderEvents (Decremented :: rest) = "[Decremented" ++ restText rest
  where
    showEvent : CounterEvent -> String
    showEvent (Created raw) = "Created(" ++ raw ++ ")"
    showEvent Incremented = "Incremented"
    showEvent Decremented = "Decremented"

    restText : List CounterEvent -> String
    restText [] = "]"
    restText (event :: xs) = ", " ++ showEvent event ++ restText xs

loadState : Memory.App String CounterEvent (Either String (Nat, CounterState))
loadState = do
  result <- loadStateOrInitial {m=ReaderT (Memory.Env String CounterEvent) IO} {stream=String} {event=CounterEvent} {state=CounterState} streamId
  pure $ case result of
    Left err => Left ("Load failed: " ++ renderLoadErr err)
    Right loaded => Right loaded

executeCommand : Command -> Memory.App String CounterEvent (Either String (RuntimeExecuteSuccess CounterEvent CounterState))
executeCommand command = do
  result <- executeOnStream {m=ReaderT (Memory.Env String CounterEvent) IO} {stream=String} {command=Command} {rejection=Rejection} {event=CounterEvent} {state=CounterState} streamId command
  pure $ case result of
    Left err => Left (renderRuntimeErr err)
    Right success => Right success

resolveCommand : String -> Memory.App String CounterEvent (Maybe Command)
resolveCommand raw =
  case trim raw of
    "1" => do
      lift $ putStr "Counter name: "
      title <- lift getLine
      pure (Just (Create (trim title)))
    "2" => pure (Just Increment)
    "3" => pure (Just Decrement)
    "q" => pure Nothing
    _ => do
      lift $ putStrLn "Invalid action."
      resolveCommand =<< lift getLine

loop : Memory.App String CounterEvent ()
loop = do
  loaded <- loadState
  case loaded of
    Left message => lift (putStrLn message)
    Right (version, state) => do
      lift $ putStrLn ""
      lift $ putStrLn "Slice: 01-state-change"
      lift $ putStrLn ("Version: " ++ show version)
      lift $ putStrLn ("State: " ++ renderState state)
      lift $ putStrLn "1. Create"
      lift $ putStrLn "2. Increment"
      lift $ putStrLn "3. Decrement"
      lift $ putStrLn "q. Quit"
      lift $ putStr "> "
      input <- lift getLine
      case trim input of
        "q" => lift $ putStrLn "Goodbye."
        _ => do
          maybeCommand <- resolveCommand input
          case maybeCommand of
            Nothing => lift $ putStrLn "Goodbye."
            Just command => do
              outcome <- executeCommand command
              case outcome of
                Left message => lift $ putStrLn message
                Right success =>
                  lift $ putStrLn
                    ("Accepted at version " ++ show (newVersion success)
                      ++ " with events " ++ renderEvents (emittedEvents success)
                      ++ "; " ++ renderState (resultingState success))
              loop

main : IO ()
main = do
  env <- Memory.mkEnv {stream=String} {ev=CounterEvent}
  runReaderT env loop
