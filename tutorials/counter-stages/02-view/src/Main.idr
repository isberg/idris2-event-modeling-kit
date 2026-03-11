module Main

import Control.Monad.Reader
import Control.Monad.Trans
import Data.String
import Domain
import EmKit.Sourcing.Decider
import EmKit.Sourcing.Projection
import EmKit.Modeling.Screen.Actions
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

loadBundle : Memory.App String CounterEvent (Either String (Nat, CounterView, CounterBundle))
loadBundle = do
  result <- projectStreamModel {m=ReaderT (Memory.Env String CounterEvent) IO} {stream=String} {event=CounterEvent} {model=CounterView} streamId
  pure $ case result of
    Left err => Left ("Load failed: " ++ renderLoadErr err)
    Right (version, view) => Right (version, view, bundleForView view)

executeCommand : Command -> Memory.App String CounterEvent (Either String (RuntimeExecuteSuccess CounterEvent CounterState))
executeCommand command = do
  result <- executeOnStream {m=ReaderT (Memory.Env String CounterEvent) IO} {stream=String} {command=Command} {rejection=Rejection} {event=CounterEvent} {state=CounterState} streamId command
  pure $ case result of
    Left err => Left (renderRuntimeErr err)
    Right success => Right success

renderScreen : Nat -> CounterView -> List Action -> IO ()
renderScreen version view actions = do
  putStrLn ""
  putStrLn "Slice: 02-view"
  putStrLn ("Version: " ++ show version)
  putStrLn ("Counter: " ++ renderValueLine view)
  putStrLn "Actions:"
  renderChoices 1 actions
  putStrLn "q. Quit"
  where
    renderChoices : Nat -> List Action -> IO ()
    renderChoices _ [] = pure ()
    renderChoices index (action :: rest) = do
      putStrLn (show index ++ ". " ++ renderAction action)
      renderChoices (S index) rest

parseChoice : String -> Maybe Nat
parseChoice raw =
  case parseInteger (trim raw) of
    Just n => if n > 0 then Just (cast n) else Nothing
    Nothing => Nothing

pickAction : List Action -> String -> Maybe Action
pickAction actions raw = index (parseChoice raw) actions
  where
    index : Maybe Nat -> List a -> Maybe a
    index Nothing _ = Nothing
    index (Just _) [] = Nothing
    index (Just 1) (x :: _) = Just x
    index (Just n) (_ :: xs) = index (Just (decrementNat n)) xs

resolveIntent : Intent -> Memory.App String CounterEvent Command
resolveIntent PromptCreate = do
  lift $ putStr "Counter name: "
  title <- lift getLine
  pure (Create (trim title))
resolveIntent RunIncrement = pure Increment
resolveIntent RunDecrement = pure Decrement

loop : Memory.App String CounterEvent ()
loop = do
  loaded <- loadBundle
  case loaded of
    Left message => lift (putStrLn message)
    Right (version, view, bundle) => do
      let actions = availableScreenActions bundle CounterHome
      lift $ renderScreen version view actions
      lift $ putStr "> "
      input <- lift getLine
      if trim input == "q"
        then lift $ putStrLn "Goodbye."
        else case pickAction actions input of
          Nothing => do
            lift $ putStrLn "Invalid action."
            loop
          Just action => do
            outcome <- executeCommand !(resolveIntent (intentForAction action))
            case outcome of
              Left message => lift $ putStrLn message
              Right success => lift $ putStrLn ("Accepted at version " ++ show (newVersion success) ++ " with events " ++ renderEvents (emittedEvents success))
            loop

main : IO ()
main = do
  env <- Memory.mkEnv {stream=String} {ev=CounterEvent}
  runReaderT env loop
