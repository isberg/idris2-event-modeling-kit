module Main

import Control.Monad.Reader
import Control.Monad.Trans
import Data.List
import Data.String
import Domain
import EmKit.Modeling.Pattern.StateView
import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Sourcing.Decider
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

loadHistoryOrEmpty : Memory.App String CounterEvent (Either LoadErr (Nat, List CounterEvent))
loadHistoryOrEmpty = do
  result <- load streamId
  pure $
    case result of
      Left NoStream => Right (0, [])
      Left err => Left err
      Right loaded => Right loaded

loadBundle : Memory.App String CounterEvent (Either String (Nat, CounterState, CounterView, CounterBundle))
loadBundle = do
  result <- loadHistoryOrEmpty
  pure $
    case result of
      Left err => Left ("Load failed: " ++ renderLoadErr err)
      Right (version, history) =>
        let state = hydrate {h=List} {event=CounterEvent} {state=CounterState} history
            view = projectFromList history
            bundle = bundleForView view
         in Right (version, state, view, bundle)

executeCommandDirect : Command -> Memory.App String CounterEvent (Either String (Nat, List CounterEvent, CounterState))
executeCommandDirect command = do
  loaded <- loadHistoryOrEmpty
  case loaded of
    Left err => pure (Left ("Load failed: " ++ renderLoadErr err))
    Right (version, history) =>
      let state = hydrate {h=List} {event=CounterEvent} {state=CounterState} history in
      case decideR {h=List} {command=Command} {rejection=Rejection} {event=CounterEvent} {state=CounterState} command state of
        Left rejection => pure (Left ("Rejected: " ++ renderRejection rejection))
        Right events => do
          appended <- append streamId version events
          pure $
            case appended of
              Left err => Left ("Append failed: " ++ renderAppendErr err)
              Right newVersion =>
                let nextState = replayFrom state events
                 in Right (newVersion, events, nextState)

renderEvents : List CounterEvent -> String
renderEvents [] = "[]"
renderEvents events = "[" ++ joinBy ", " (map showEvent events) ++ "]"
  where
    showEvent : CounterEvent -> String
    showEvent (Created title) = "Created(" ++ title ++ ")"
    showEvent Incremented = "Incremented"
    showEvent Decremented = "Decremented"

renderScreen : Nat -> CounterView -> List Action -> IO ()
renderScreen version view actions = do
  putStrLn ""
  putStrLn ("Screen: counter-home (policy=" ++ showPolicy CounterHome ++ ")")
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

    showPolicy : Screen -> String
    showPolicy screen =
      case dataSourcePolicy (specFor {bundle=CounterBundle} screen) of
        QueryOnly => "QueryOnly"
        ClientProjectionOnly => "ClientProjectionOnly"
        HybridProjection => "HybridProjection"

parseChoice : String -> Maybe Nat
parseChoice raw =
  case parseInteger (trim raw) of
    Just n =>
      if n > 0
        then Just (integerToNat n)
        else Nothing
    Nothing => Nothing

pickAction : List Action -> String -> Maybe Action
pickAction actions raw =
  case parseChoice raw of
    Nothing => Nothing
    Just n => index (decrementNat n) actions
  where
    index : Nat -> List a -> Maybe a
    index _ [] = Nothing
    index Z (x :: _) = Just x
    index (S k) (_ :: rest) = index k rest

resolveIntent : Intent -> Memory.App String CounterEvent Command
resolveIntent PromptCreate = do
  lift $ putStr "Counter name: "
  name <- lift getLine
  pure (Create (trim name))
resolveIntent RunIncrement = pure Increment
resolveIntent RunDecrement = pure Decrement

loop : Memory.App String CounterEvent ()
loop = do
  loaded <- loadBundle
  case loaded of
    Left message => lift (putStrLn message)
    Right (version, _, view, bundle) => do
      let actions = availableScreenActions bundle CounterHome
      lift $ renderScreen version view actions
      lift $ putStr "> "
      input <- lift getLine
      if trim input == "q"
        then lift $ putStrLn "Goodbye."
        else
          case pickAction actions input of
            Nothing => do
              lift $ putStrLn "Invalid action."
              loop
            Just action => do
              command <- resolveIntent (intentForAction action)
              outcome <- executeCommandDirect command
              case outcome of
                Left message => lift $ putStrLn message
                Right (newVersion, events, state) =>
                  lift $ putStrLn ("Accepted at version " ++ show newVersion ++ " with events " ++ renderEvents events ++ "; state value=" ++ show (value state))
              loop

main : IO ()
main = do
  env <- Memory.mkEnv {stream=String} {ev=CounterEvent}
  runReaderT env loop
