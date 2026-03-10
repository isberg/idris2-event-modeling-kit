module FrontendMain

import Data.List
import Data.String
import Domain
import EmKit.Sourcing.Projection
import EmKit.Frontend.SSE as FrontendSSE
import JS.Util
import JSON.Simple
import Text.HTML.Attribute as HtmlAttr
import Web.MVC
import Web.MVC.Http
import WebApiTypes

%default total

data Msg : Type where
  Initialized : Msg
  ClientIdReady : String -> Msg
  SnapshotLoaded : Either HTTPError CounterSnapshotDto -> Msg
  SseEventReceived : String -> Msg
  ResyncClicked : Msg
  CreateNameChanged : String -> Msg
  CreateClicked : Msg
  CreateFinished : Either HTTPError CommandResponseDto -> Msg
  IncrementClicked : Msg
  IncrementFinished : Either HTTPError CommandResponseDto -> Msg
  DecrementClicked : Msg
  DecrementFinished : Either HTTPError CommandResponseDto -> Msg

record State where
  constructor MkState
  version : Nat
  view : CounterView
  history : List EventHistoryDto
  createName : String
  status : String
  busy : Bool
  clientId : Maybe String

initialCounterView : CounterView
initialCounterView = MkCounterView "(unnamed)" 0 "" False

initialState : State
initialState = MkState 0 initialCounterView [] "Kitchen" "Connecting live feed..." True Nothing

httpErrorMessage : HTTPError -> String
httpErrorMessage Timeout = "Request timed out."
httpErrorMessage NetworkError = "Network error calling /api/counter. Run ./scripts/run.sh and open /static/index.html on the configured port."
httpErrorMessage (BadStatus code) = "Server returned status " ++ show code ++ "."
httpErrorMessage (JSONError _ _) = "Failed to decode JSON response."

statusText : State -> String
statusText s = if busy s then "Working: " ++ status s else status s

liveStatusText : State -> String
liveStatusText s =
  case clientId s of
    Nothing => "Live feed: disconnected"
    Just _ => "Live feed: connected"

eventsUrl : String -> String
eventsUrl clientId = "/api/events/" ++ clientId

loadSnapshot : Cmd Msg
loadSnapshot = get "/api/counter" (ExpectJSON SnapshotLoaded)

postCreate : String -> Cmd Msg
postCreate counterName = post "/api/counter/create" (JSONBody counterName) (ExpectJSON CreateFinished)

emptyJsonNat : Nat
emptyJsonNat = 0

postIncrement : Cmd Msg
postIncrement = post "/api/counter/increment" (JSONBody emptyJsonNat) (ExpectJSON IncrementFinished)

postDecrement : Cmd Msg
postDecrement = post "/api/counter/decrement" (JSONBody emptyJsonNat) (ExpectJSON DecrementFinished)

subscribeEvents : String -> Cmd Msg
subscribeEvents clientId = FrontendSSE.subscribe (eventsUrl clientId) SseEventReceived

reconnectEvents : String -> Cmd Msg
reconnectEvents clientId = batch [FrontendSSE.close (eventsUrl clientId), subscribeEvents clientId]

resyncCommands : State -> List (Cmd Msg)
resyncCommands s =
  case clientId s of
    Nothing => [requestClientId ClientIdReady]
    Just cid => [reconnectEvents cid, loadSnapshot]

applyLiveEvent : CounterLiveEventDto -> State -> Either String State
applyLiveEvent dto s =
  if streamVersion dto <= version s then
    Right s
  else
    let expected = S (version s) in
    if streamVersion dto /= expected then
      Left ("Live stream version gap: expected v" ++ show expected ++ ", got v" ++ show (streamVersion dto) ++ ".")
    else
      case decodeLiveEvent dto of
        Left err => Left err
        Right event =>
          let nextView = evolve (view s) event
              nextHistory = history s ++ [MkEventHistoryDto (streamVersion dto) (eventType dto) (detail dto)] in
            Right ({ version := streamVersion dto, view := nextView, history := nextHistory, busy := False, status := "Live event: " ++ eventType dto ++ "." } s)

historyRow : EventHistoryDto -> Node Msg
historyRow row =
  let detailText =
        case detail row of
          Nothing => ""
          Just info => " (" ++ info ++ ")" in
  li [ style "margin-bottom:4px;" ] [ Text ("v" ++ show (streamVersion row) ++ " " ++ eventType row ++ detailText) ]

actionButton : Bool -> Action -> Node Msg
actionButton isBusy action =
  let msg =
        case action of
          CreateCounterAction => CreateClicked
          IncrementCounterAction => IncrementClicked
          DecrementCounterAction => DecrementClicked
   in button
        [ onClick msg
        , disabled isBusy
        , style "padding:10px 14px; border:1px solid #255f4c; border-radius:10px; background:#ebf7f0;"
        ]
        [ Text (renderAction action) ]

createSection : State -> Node Msg
createSection s =
  div [ style "background:#ffffffcc; border:1px solid #c5d9cf; border-radius:14px; padding:14px; margin-bottom:14px;" ]
    [ h3 [ style "margin:0 0 8px 0;" ] [ Text "Create Counter" ]
    , div [ style "display:flex; gap:8px; flex-wrap:wrap;" ]
        [ input [ onInput CreateNameChanged, HtmlAttr.value (createName s), placeholder "counter name", style "padding:10px; border:1px solid #9db7ac; border-radius:10px; min-width:240px;" ] []
        , actionButton (busy s) CreateCounterAction
        ]
    ]

displayedActions : CounterView -> List Action
displayedActions view = keepOperational (availableActionsForView view)
  where
    keepOperational : List Action -> List Action
    keepOperational [] = []
    keepOperational (CreateCounterAction :: rest) = keepOperational rest
    keepOperational (action :: rest) = action :: keepOperational rest

counterCard : State -> Node Msg
counterCard s =
  let actions = displayedActions (view s)
      numberText = if created (view s) then show (Domain.CounterView.value (view s)) else "-"
      romanText = if created (view s) then roman (view s) else "counter not created"
      subtitle = if created (view s) then label (view s) else "Waiting for first Create command" in
  div [ style "background:#ffffffcc; border:1px solid #c5d9cf; border-radius:18px; padding:18px; margin-bottom:14px;" ]
    [ div [ style "display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:10px;" ]
        [ h2 [ style "margin:0; font-size:26px;" ] [ Text "Counter Web" ]
        , div [ style "font-size:12px; opacity:0.7;" ] [ Text ("stream v" ++ show (version s)) ]
        ]
    , div [ style "font-size:15px; opacity:0.8; margin-bottom:4px;" ] [ Text subtitle ]
    , div [ style "font-size:96px; font-weight:700; line-height:0.9; color:#1b4f3e;" ] [ Text numberText ]
    , div [ style "font-size:28px; letter-spacing:1px; margin-top:6px; color:#406657; min-height:34px;" ] [ Text romanText ]
    , div [ style "margin-top:14px; display:flex; gap:8px; flex-wrap:wrap;" ] (map (actionButton (busy s)) actions)
    ]

historySection : State -> Node Msg
historySection s =
  div [ style "background:#ffffffcc; border:1px solid #c5d9cf; border-radius:14px; padding:14px;" ]
    [ h3 [ style "margin:0 0 8px 0;" ] [ Text "Event History" ]
    , if null (history s)
        then Text "No events yet."
        else ul [ style "margin:0; padding-left:20px;" ] (map historyRow (history s))
    ]

viewNodes : State -> List (Node Msg)
viewNodes s =
  let needsCreate = not (created (view s)) in
  [ div [ style "min-height:100vh; padding:24px; background:linear-gradient(135deg,#f7efe6 0%, #e6f1ec 48%, #dce9f7 100%); font-family:Georgia,serif; color:#1f2b27;" ]
      [ div [ style "max-width:900px; margin:0 auto;" ]
          [ div [ style "margin-bottom:12px; padding:12px; border-radius:12px; background:#ffffffcc; border:1px solid #c5d9cf; display:flex; gap:12px; flex-wrap:wrap; align-items:center;" ]
              [ Text ("Status: " ++ statusText s)
              , button [ onClick ResyncClicked, disabled (busy s), style "padding:7px 10px; border:1px solid #5d7d70; border-radius:8px; background:#edf5f1;" ] [ Text "Resync" ]
              , div [ style "margin-left:auto; font-size:12px; opacity:0.75;" ] [ Text (liveStatusText s) ]
              ]
          , if needsCreate then createSection s else Text ""
          , counterCard s
          , historySection s
          ]
      ]
  ]

updateView : State -> Cmd Msg
updateView s = children Ref.Body (viewNodes s)

controller : Msg -> State -> (State, Cmd Msg)
controller Initialized s =
  let s' = { busy := True, status := "Connecting live feed..." } s in
  (s', batch [updateView s', requestClientId ClientIdReady])

controller (ClientIdReady cid) s =
  let s' = { clientId := Just cid, busy := True, status := "Connected. Loading counter..." } s in
  (s', batch [updateView s', subscribeEvents cid, loadSnapshot])

controller (SnapshotLoaded (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (SnapshotLoaded (Right snapshot)) s =
  let s' = { version := version snapshot, view := view snapshot, history := history snapshot, busy := False, status := "Counter synced." } s in
  (s', updateView s')

controller (SseEventReceived raw) s =
  case decode {a=CounterLiveEventDto} raw of
    Left _ =>
      let s' = { busy := True, status := "Live decode failed. Resyncing..." } s in
      (s', batch (updateView s' :: resyncCommands s'))
    Right dto =>
      case applyLiveEvent dto s of
        Left err =>
          let s' = { busy := True, status := err ++ " Resyncing..." } s in
          (s', batch (updateView s' :: resyncCommands s'))
        Right s' => (s', updateView s')

controller ResyncClicked s =
  let s' = { busy := True, status := "Resyncing..." } s in
  (s', batch (updateView s' :: resyncCommands s'))

controller (CreateNameChanged value) s = ({ createName := value } s, Cmd.noAction)

controller CreateClicked s =
  let cleanName = trim (createName s) in
  if cleanName == "" then
    let s' = { busy := False, status := "Counter name is required." } s in
    (s', updateView s')
  else
    let s' = { busy := True, status := "Creating counter..." } s in
    (s', batch [updateView s', postCreate cleanName])

controller (CreateFinished (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (CreateFinished (Right response)) s =
  let s' = { busy := False, status := message response ++ if ok response then " Waiting for live event..." else "" } s in
  (s', updateView s')

controller IncrementClicked s =
  let s' = { busy := True, status := "Incrementing counter..." } s in
  (s', batch [updateView s', postIncrement])

controller (IncrementFinished (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (IncrementFinished (Right response)) s =
  let s' = { busy := False, status := message response ++ if ok response then " Waiting for live event..." else "" } s in
  (s', updateView s')

controller DecrementClicked s =
  let s' = { busy := True, status := "Decrementing counter..." } s in
  (s', batch [updateView s', postDecrement])

controller (DecrementFinished (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (DecrementFinished (Right response)) s =
  let s' = { busy := False, status := message response ++ if ok response then " Waiting for live event..." else "" } s in
  (s', updateView s')

onError : JS.Util.JSErr -> IO ()
onError = putStrLn . dispErr

covering
main : IO ()
main = runController {e = Msg, s = State} controller onError Initialized initialState
