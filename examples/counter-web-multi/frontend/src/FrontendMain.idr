module FrontendMain

import Data.List
import Data.Maybe
import Data.SortedMap as SortedMap
import Domain
import Domain.JSON.Simple
import EmKit.Wire.Contracts
import EmKit.Wire.JSON.Simple
import FrontendSSE
import JS.Util
import JSON.Simple
import Text.HTML.Attribute as HtmlAttr
import Web.MVC
import Web.MVC.Http

%default total

record StreamState where
  constructor MkStreamState
  version : Nat
  count : Nat

record AppState where
  constructor MkAppState
  streams : SortedMap.SortedMap String StreamState
  streamIds : List String
  status : String
  clientId : Maybe String

streamIds0 : List String
streamIds0 = ["counter-a", "counter-b", "counter-c"]

initialStreamState : StreamState
initialStreamState = MkStreamState 0 0

initialStreams : SortedMap.SortedMap String StreamState
initialStreams = foldl (\acc, streamId => SortedMap.insert streamId initialStreamState acc) SortedMap.empty streamIds0

initialState : AppState
initialState = MkAppState initialStreams streamIds0 "Connecting live feeds..." Nothing

data Msg : Type where
  Initialized : Msg
  ClientIdReady : String -> Msg
  IncrementClicked : String -> Msg
  IncrementFinished : String -> Either HTTPError () -> Msg
  ResyncClicked : String -> Msg
  ResyncFinished : String -> Either HTTPError (ResyncPayload CounterEvent) -> Msg
  EventReceived : String -> String -> Msg

httpErrorMessage : HTTPError -> String
httpErrorMessage Timeout = "Request timed out."
httpErrorMessage NetworkError = "Network error. Run ./scripts/run.sh and open http://127.0.0.1:3000/static/index.html"
httpErrorMessage (BadStatus code) = "Server returned status " ++ show code ++ "."
httpErrorMessage (JSONError _ _) = "Failed to decode JSON response."

eventsUrl : String -> String -> String
eventsUrl streamId clientId = "/api/counter/events/" ++ streamId ++ "/" ++ clientId

executeUrl : String -> String
executeUrl streamId = "/api/counter/execute/" ++ streamId

resyncUrl : String -> String
resyncUrl streamId = "/api/counter/resync/" ++ streamId

subscribeStream : String -> String -> Cmd Msg
subscribeStream streamId clientId =
  FrontendSSE.subscribe (eventsUrl streamId clientId) (EventReceived streamId)

subscribeAll : List String -> String -> Cmd Msg
subscribeAll streamIds clientId =
  batch (map (\streamId => subscribeStream streamId clientId) streamIds)

postIncrement : String -> Nat -> Cmd Msg
postIncrement streamId currentVersion =
  post (executeUrl streamId)
    (JSONBody (MkExecutePayload currentVersion Increment))
    (ExpectAny (IncrementFinished streamId))

getResync : String -> Cmd Msg
getResync streamId =
  get (resyncUrl streamId) (ExpectJSON (ResyncFinished streamId))

sumCounts : SortedMap.SortedMap String StreamState -> Nat
sumCounts streams = foldl (\acc, (_, st) => acc + count st) 0 (SortedMap.toList streams)

applyStreamEvent : StreamEvent CounterEvent -> StreamState -> Either String StreamState
applyStreamEvent msg st =
  if version msg <= version st then
    Right st
  else
    let expected = S (version st) in
    if version msg /= expected then
      Left ("Stream version gap: expected v" ++ show expected ++ ", got v" ++ show (version msg) ++ ".")
    else
      Right (MkStreamState (version msg) (evolve (count st) (event msg)))

replayEvents : List CounterEvent -> Nat
replayEvents = foldl evolve 0

applyResyncPayload : ResyncPayload CounterEvent -> StreamState
applyResyncPayload payload = MkStreamState (version payload) (replayEvents (events payload))

streamCard : AppState -> String -> Node Msg
streamCard s streamId =
  let st = fromMaybe initialStreamState (SortedMap.lookup streamId (streams s)) in
  div [ style "background:#ffffffcc; border:1px solid #c4d4e5; border-radius:16px; padding:18px; min-width:220px; flex:1;" ]
    [ div [ style "font-size:12px; opacity:0.7; text-transform:uppercase; letter-spacing:1px;" ] [ Text streamId ]
    , div [ style "font-size:72px; line-height:0.95; color:#163c64; font-weight:700; margin:12px 0;" ] [ Text (show (count st)) ]
    , div [ style "font-size:13px; opacity:0.7; margin-bottom:12px;" ] [ Text ("version " ++ show (version st)) ]
    , div [ style "display:flex; gap:8px; flex-wrap:wrap;" ]
        [ button [ onClick (IncrementClicked streamId), style "padding:10px 14px; border:1px solid #4b7398; border-radius:10px; background:#eef5fb;" ] [ Text "Increment" ]
        , button [ onClick (ResyncClicked streamId), style "padding:10px 14px; border:1px solid #7d8893; border-radius:10px; background:#f5f7f9;" ] [ Text "Resync" ]
        ]
    ]

viewNodes : AppState -> List (Node Msg)
viewNodes s =
  [ div [ style "min-height:100vh; padding:24px; background:linear-gradient(135deg,#f4efe5 0%, #e7eef6 55%, #dde7d7 100%); font-family:Georgia,serif; color:#20303b;" ]
      [ div [ style "max-width:1100px; margin:0 auto;" ]
          [ div [ style "background:#ffffffcc; border:1px solid #c4d4e5; border-radius:18px; padding:18px; margin-bottom:18px; display:flex; align-items:end; gap:18px; flex-wrap:wrap;" ]
              [ div []
                  [ div [ style "font-size:13px; opacity:0.7; text-transform:uppercase; letter-spacing:1px;" ] [ Text "SSE First" ]
                  , h1 [ style "margin:4px 0 0 0; font-size:34px;" ] [ Text "Multi-Stream Counter Web" ]
                  ]
              , div [ style "margin-left:auto; text-align:right;" ]
                  [ div [ style "font-size:13px; opacity:0.7; text-transform:uppercase; letter-spacing:1px;" ] [ Text "Total" ]
                  , div [ style "font-size:56px; line-height:0.95; color:#1d5b39; font-weight:700;" ] [ Text (show (sumCounts (streams s))) ]
                  ]
              ]
          , div [ style "background:#ffffffcc; border:1px solid #c4d4e5; border-radius:12px; padding:12px 14px; margin-bottom:18px; display:flex; gap:12px; flex-wrap:wrap;" ]
              [ Text ("Status: " ++ status s)
              , div [ style "margin-left:auto; font-size:12px; opacity:0.75;" ] [ Text (case clientId s of
                    Nothing => "Live feeds: connecting"
                    Just _ => "Live feeds: connected") ]
              ]
          , div [ style "display:flex; gap:14px; flex-wrap:wrap;" ] (map (streamCard s) (streamIds s))
          ]
      ]
  ]

updateView : AppState -> Cmd Msg
updateView s = children Ref.Body (viewNodes s)

controller : Msg -> AppState -> (AppState, Cmd Msg)
controller Initialized s = (s, batch [updateView s, requestClientId ClientIdReady])
controller (ClientIdReady clientId) s =
  let s' = { clientId := Just clientId, status := "Connected. Waiting for stream replay..." } s in
  (s', batch [updateView s', subscribeAll (streamIds s) clientId])
controller (IncrementClicked streamId) s =
  case SortedMap.lookup streamId (streams s) of
    Nothing => ({ status := "Unknown stream: " ++ streamId } s, updateView ({ status := "Unknown stream: " ++ streamId } s))
    Just st =>
      let s' = { status := "Incrementing " ++ streamId ++ "..." } s in
      (s', batch [updateView s', postIncrement streamId (version st)])
controller (IncrementFinished _ (Left err)) s =
  let s' = { status := httpErrorMessage err } s in
  (s', updateView s')
controller (IncrementFinished streamId (Right _)) s =
  let s' = { status := "Command accepted for " ++ streamId ++ "." } s in
  (s', updateView s')
controller (ResyncClicked streamId) s =
  let s' = { status := "Resyncing " ++ streamId ++ "..." } s in
  (s', batch [updateView s', getResync streamId])
controller (ResyncFinished streamId (Left err)) s =
  let s' = { status := httpErrorMessage err } s in
  (s', updateView s')
controller (ResyncFinished streamId (Right payload)) s =
  let next = applyResyncPayload payload
      s' = { streams := SortedMap.insert streamId next (streams s), status := "Resynced " ++ streamId ++ "." } s in
  (s', updateView s')
controller (EventReceived streamId raw) s =
  case decode {a=StreamEvent CounterEvent} raw of
    Left _ =>
      let s' = { status := "Failed to decode live event for " ++ streamId ++ ". Resyncing..." } s in
      (s', batch [updateView s', getResync streamId])
    Right msg =>
      case SortedMap.lookup streamId (streams s) of
        Nothing =>
          let s' = { status := "Unknown stream: " ++ streamId } s in
          (s', updateView s')
        Just st =>
          case applyStreamEvent msg st of
            Left err =>
              let s' = { status := err ++ " Resyncing..." } s in
              (s', batch [updateView s', getResync streamId])
            Right next =>
              let s' = { streams := SortedMap.insert streamId next (streams s), status := "Live event applied for " ++ streamId ++ "." } s in
              (s', updateView s')

onError : JS.Util.JSErr -> IO ()
onError = putStrLn . dispErr

covering
main : IO ()
main = runController {e=Msg, s=AppState} controller onError Initialized initialState
