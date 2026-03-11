module FrontendMain

import Data.Maybe
import Domain
import Domain.JSON.Simple
import EmKit.Frontend.Execute as FrontendExecute
import EmKit.Frontend.SSE as FrontendSSE
import EmKit.Frontend.Stream as FrontendStream
import EmKit.Wire.Contracts
import EmKit.Wire.JSON.Simple
import JS.Util
import JSON.Simple
import Web.MVC
import Web.MVC.Http

%default total

record State where
  constructor MkState
  detail : CounterDetail
  status : String
  busy : Bool
  clientId : Maybe String

initialState : State
initialState = MkState emptyDetail "Connecting live feed..." True Nothing

data Msg : Type where
  Initialized : Msg
  ClientIdReady : String -> Msg
  ResyncFinished : Either HTTPError (ResyncPayload CounterEvent) -> Msg
  LiveEventReceived : String -> Msg
  IncrementClicked : Msg
  IncrementFinished : Either HTTPError () -> Msg
  DecrementClicked : Msg
  DecrementFinished : Either HTTPError () -> Msg

httpErrorMessage : HTTPError -> String
httpErrorMessage Timeout = "Request timed out."
httpErrorMessage NetworkError = "Network error. Run ./scripts/run.sh and open /static/index.html on the configured port."
httpErrorMessage (BadStatus code) = "Server returned status " ++ show code ++ "."
httpErrorMessage (JSONError _ _) = "Failed to decode JSON response."

eventsUrl : String -> String -> String
eventsUrl _ clientId = "/api/counter/events/" ++ clientId

executeUrl : String -> String
executeUrl _ = "/api/counter/execute"

resyncUrl : String -> String
resyncUrl _ = "/api/counter/resync"

subscribeLive : String -> Cmd Msg
subscribeLive clientId = FrontendStream.subscribeStream eventsUrl counterStreamId clientId LiveEventReceived

requestResync : Cmd Msg
requestResync = FrontendExecute.getResync resyncUrl (\_ => ResyncFinished) counterStreamId

postIncrement : Nat -> Cmd Msg
postIncrement expectedVersion =
  FrontendExecute.postExecuteSingle executeUrl IncrementFinished counterStreamId expectedVersion Increment

postDecrement : Nat -> Cmd Msg
postDecrement expectedVersion =
  FrontendExecute.postExecuteSingle executeUrl DecrementFinished counterStreamId expectedVersion Decrement

currentModel : State -> CounterModel
currentModel s = model (detail s)

availableActions : State -> List Action
availableActions s = availableActionsForModel (currentModel s)

hasAction : Action -> State -> Bool
hasAction wanted s = any matches (availableActions s)
  where
    matches : Action -> Bool
    matches current =
      case (wanted, current) of
        (IncrementCounterAction, IncrementCounterAction) => True
        (DecrementCounterAction, DecrementCounterAction) => True
        _ => False

statusText : State -> String
statusText s = if busy s then "Working: " ++ status s else status s

renderHistoryEvent : CounterEvent -> String
renderHistoryEvent Incremented = "Incremented"
renderHistoryEvent Decremented = "Decremented"

msgForAction : Action -> Msg
msgForAction IncrementCounterAction = IncrementClicked
msgForAction DecrementCounterAction = DecrementClicked

actionButton : Bool -> Action -> Node Msg
actionButton isBusy action =
  button
    [ onClick (msgForAction action)
    , disabled isBusy
    , style "padding:9px 12px; border:1px solid #3b5d7e; border-radius:10px; background:#eef5fb;"
    ]
    [ Text (renderAction action) ]

viewNode : State -> Node Msg
viewNode s =
  let current = currentModel s
      showDecrement = hasAction DecrementCounterAction s
      historyRows = zipWith historyRow [1..length (history (detail s))] (history (detail s))
  in div [ style "min-height:100vh; padding:24px; background:linear-gradient(135deg,#f1eee8 0%, #e5eef7 55%, #dde7d8 100%); font-family:Georgia,serif; color:#20303b;" ]
       [ div [ style "max-width:860px; margin:0 auto;" ]
           [ div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:14px; padding:12px 14px; margin-bottom:18px; display:flex; gap:12px; flex-wrap:wrap;" ]
               [ Text ("Status: " ++ statusText s)
               , div [ style "margin-left:auto; font-size:12px; opacity:0.72;" ] [ Text ("Stream: " ++ counterStreamId ++ feedStatus (clientId s)) ]
               ]
           , div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:18px; padding:18px;" ]
               [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;" ] [ Text "ClientProjectionOnly" ]
               , h1 [ style "margin:8px 0 6px 0; font-size:30px;" ] [ Text "Counter" ]
               , div [ style "font-size:84px; font-weight:700; line-height:0.9; color:#1b4f3e;" ] [ Text (show (value current)) ]
               , div [ style "display:flex; gap:10px; flex-wrap:wrap; margin:18px 0;" ]
                   ([actionButton (busy s) IncrementCounterAction] ++
                    (if showDecrement then [actionButton (busy s) DecrementCounterAction] else []))
               , h2 [ style "margin:0 0 8px 0;" ] [ Text "Event History" ]
               , if null historyRows
                   then Text "No events yet."
                   else ul [ style "margin:0; padding-left:20px;" ] historyRows
               ]
           ]
       ]
  where
    feedStatus : Maybe String -> String
    feedStatus Nothing = " · disconnected"
    feedStatus (Just _) = " · connected"

    historyRow : Nat -> CounterEvent -> Node Msg
    historyRow idx currentEvent =
      li [ style "margin-bottom:6px;" ] [ Text ("v" ++ show idx ++ " " ++ renderHistoryEvent currentEvent) ]

updateView : State -> Cmd Msg
updateView s = children Ref.Body [viewNode s]

controller : Msg -> State -> (State, Cmd Msg)
controller Initialized s =
  let s' = { busy := True, status := "Connecting live feed..." } s in
  (s', batch [updateView s', FrontendSSE.requestClientId ClientIdReady])

controller (ClientIdReady client) s =
  let s' = { clientId := Just client, busy := True, status := "Syncing stream..." } s in
  (s', batch [updateView s', subscribeLive client, requestResync])

controller (ResyncFinished (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (ResyncFinished (Right payload)) s =
  let nextDetail = detailFromEvents (version payload) (events payload)
      s' = { detail := nextDetail, busy := False, status := "Stream synced." } s in
  (s', updateView s')

controller (LiveEventReceived raw) s =
  case decode {a=StreamEvent CounterEvent} raw of
    Left _ =>
      let s' = { busy := True, status := "Live decode failed. Resyncing stream..." } s in
      (s', batch [updateView s', requestResync])
    Right liveEvent =>
      case applyDetailEvent (version liveEvent) (event liveEvent) (detail s) of
        Left err =>
          let s' = { busy := True, status := err ++ " Resyncing stream..." } s in
          (s', batch [updateView s', requestResync])
        Right nextDetail =>
          let s' = { detail := nextDetail, busy := False, status := "Live update applied." } s in
          (s', updateView s')

controller IncrementClicked s =
  let s' = { busy := True, status := "Incrementing counter..." } s in
  (s', batch [updateView s', postIncrement (version (detail s))])

controller (IncrementFinished (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (IncrementFinished (Right _)) s =
  let s' = { busy := False, status := "Increment accepted. Waiting for live update..." } s in
  (s', updateView s')

controller DecrementClicked s =
  let s' = { busy := True, status := "Decrementing counter..." } s in
  (s', batch [updateView s', postDecrement (version (detail s))])

controller (DecrementFinished (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (DecrementFinished (Right _)) s =
  let s' = { busy := False, status := "Decrement accepted. Waiting for live update..." } s in
  (s', updateView s')

onError : JS.Util.JSErr -> IO ()
onError = putStrLn . dispErr

covering
main : IO ()
main = runController {e = Msg, s = State} controller onError Initialized initialState
