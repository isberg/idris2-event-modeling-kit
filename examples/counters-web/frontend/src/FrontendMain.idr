module FrontendMain

import Data.List
import Data.Maybe
import Data.SortedMap as SortedMap
import Data.String
import Domain
import Domain.JSON.Simple
import EmKit.Frontend.Execute as FrontendExecute
import EmKit.Frontend.SSE as FrontendSSE
import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Wire.Contracts
import EmKit.Wire.JSON.Simple
import JS.Util
import JSON.Simple
import Text.HTML.Attribute as HtmlAttr
import Web.MVC
import Web.MVC.Http

%default total

record State where
  constructor MkState
  screen : Screen
  summaries : SortedMap.SortedMap String CounterSummary
  selectedDetail : Maybe CounterDetail
  createName : String
  status : String
  busy : Bool
  clientId : Maybe String

initialState : State
initialState = MkState CountersOverview SortedMap.empty Nothing "Kitchen" "Connecting overview feed..." True Nothing

data Msg : Type where
  Initialized : Msg
  ClientIdReady : String -> Msg
  OverviewLoaded : Either HTTPError (List CounterSummary) -> Msg
  OverviewEventReceived : String -> Msg
  CreateNameChanged : String -> Msg
  CreateCounterClicked : Msg
  CreateCounterFinished : String -> Either HTTPError () -> Msg
  OpenCounterClicked : String -> Msg
  DetailResyncFinished : String -> Either HTTPError (ResyncPayload CounterEvent) -> Msg
  DetailEventReceived : String -> String -> Msg
  BackToCountersClicked : Msg
  IncrementClicked : Msg
  IncrementFinished : String -> Either HTTPError () -> Msg
  DecrementClicked : Msg
  DecrementFinished : String -> Either HTTPError () -> Msg

httpErrorMessage : HTTPError -> String
httpErrorMessage Timeout = "Request timed out."
httpErrorMessage NetworkError = "Network error. Run ./scripts/run.sh and open /static/index.html on the configured port."
httpErrorMessage (BadStatus code) = "Server returned status " ++ show code ++ "."
httpErrorMessage (JSONError _ _) = "Failed to decode JSON response."

overviewEventsUrl : String -> String
overviewEventsUrl clientId = "/api/counters/overview-events/" ++ clientId

detailEventsUrl : String -> String -> String
detailEventsUrl counterId clientId = "/api/counters/events/" ++ counterId ++ "/" ++ clientId

executeUrl : String -> String
executeUrl counterId = "/api/counters/execute/" ++ counterId

resyncUrl : String -> String
resyncUrl counterId = "/api/counters/resync/" ++ counterId

loadSummaries : Cmd Msg
loadSummaries = get "/api/counters" (ExpectJSON OverviewLoaded)

subscribeOverview : String -> Cmd Msg
subscribeOverview clientId = FrontendSSE.subscribe (overviewEventsUrl clientId) OverviewEventReceived

subscribeDetail : String -> String -> Cmd Msg
subscribeDetail counterId clientId = FrontendSSE.subscribe (detailEventsUrl counterId clientId) (DetailEventReceived counterId)

closeDetail : String -> String -> Cmd Msg
closeDetail counterId clientId = FrontendSSE.close (detailEventsUrl counterId clientId)

getDetailResync : String -> Cmd Msg
getDetailResync counterId = FrontendExecute.getResync resyncUrl DetailResyncFinished counterId

postCreateCounter : String -> String -> Cmd Msg
postCreateCounter counterId counterName = FrontendExecute.postExecute executeUrl CreateCounterFinished counterId 0 (CreateCounter counterName)

postIncrement : String -> Nat -> Cmd Msg
postIncrement counterId currentVersion = FrontendExecute.postExecute executeUrl IncrementFinished counterId currentVersion Increment

postDecrement : String -> Nat -> Cmd Msg
postDecrement counterId currentVersion = FrontendExecute.postExecute executeUrl DecrementFinished counterId currentVersion Decrement

statusText : State -> String
statusText s = if busy s then "Working: " ++ status s else status s

summaryList : State -> List CounterSummary
summaryList s = filter exists (SortedMap.values (summaries s))

bundleForState : State -> AppBundle
bundleForState s = bundleForApp (summaryList s) (selectedDetail s)

screenPolicyText : Screen -> String
screenPolicyText currentScreen =
  case dataSourcePolicy (specFor {bundle=AppBundle} currentScreen) of
    QueryOnly => "QueryOnly"
    ClientProjectionOnly => "ClientProjectionOnly"
    HybridProjection => "HybridProjection"

currentCounterId : State -> Maybe String
currentCounterId s = map counterId (selectedDetail s)

replaceSummary : CounterSummary -> State -> State
replaceSummary summary s = { summaries := SortedMap.insert (counterId summary) summary (summaries s) } s

updateSummaryFromDetail : CounterDetail -> State -> State
updateSummaryFromDetail detail s = replaceSummary (summaryFromDetail detail) s

actionsForCurrentScreen : State -> List Action
actionsForCurrentScreen s = availableScreenActions (bundleForState s) (screen s)

overviewActions : State -> List Action
overviewActions s = filter keep (actionsForCurrentScreen s)
  where
    keep : Action -> Bool
    keep CreateCounterAction = True
    keep (OpenCounterAction _) = True
    keep _ = False

detailActions : State -> List Action
detailActions s = filter keep (actionsForCurrentScreen s)
  where
    keep : Action -> Bool
    keep BackToCountersAction = True
    keep IncrementCounterAction = True
    keep DecrementCounterAction = True
    keep _ = False

applyOverviewEvent : MultiplexedStreamEvent String CounterEvent -> State -> State
applyOverviewEvent msg s =
  let sid = streamId msg
      current = fromMaybe (emptySummary sid) (SortedMap.lookup sid (summaries s))
      next = applySummaryEvent sid (event msg) current
  in replaceSummary next s

applyDetailEvent : StreamEvent CounterEvent -> CounterDetail -> Either String CounterDetail
applyDetailEvent msg detail =
  if version msg <= version detail then
    Right detail
  else
    let expected = S (version detail) in
    if version msg /= expected then
      Left ("Detail stream version gap: expected v" ++ show expected ++ ", got v" ++ show (version msg) ++ ".")
    else
      let nextHistory = history detail ++ [event msg]
      in Right (detailFromEvents (counterId detail) (version msg) nextHistory)

nextCounterId : State -> String
nextCounterId s = counterPrefix ++ show (S (length (summaryList s)))

closeCurrentDetail : State -> List (Cmd Msg)
closeCurrentDetail s =
  case (currentCounterId s, clientId s) of
    (Just current, Just cid) => [closeDetail current cid]
    _ => []

openDetailCommands : State -> String -> List (Cmd Msg)
openDetailCommands s counterId =
  case clientId s of
    Nothing => [FrontendSSE.requestClientId ClientIdReady]
    Just cid => closeCurrentDetail s ++ [subscribeDetail counterId cid, getDetailResync counterId]

messageForAction : Action -> Msg
messageForAction CreateCounterAction = CreateCounterClicked
messageForAction (OpenCounterAction counterId) = OpenCounterClicked counterId
messageForAction BackToCountersAction = BackToCountersClicked
messageForAction IncrementCounterAction = IncrementClicked
messageForAction DecrementCounterAction = DecrementClicked

actionButton : Bool -> Action -> Node Msg
actionButton isBusy action =
  button
    [ onClick (messageForAction action)
    , disabled isBusy
    , style "padding:9px 12px; border:1px solid #3b5d7e; border-radius:10px; background:#eef5fb;"
    ]
    [ Text (renderAction action) ]

renderHistoryEvent : CounterEvent -> String
renderHistoryEvent (Created counterName) = "Created (" ++ counterName ++ ")"
renderHistoryEvent Incremented = "Incremented"
renderHistoryEvent Decremented = "Decremented"

overviewCard : State -> CounterSummary -> Node Msg
overviewCard s summary =
  let openAction = OpenCounterAction (counterId summary)
  in div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:18px; padding:18px; min-width:220px; flex:1;" ]
       [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;" ] [ Text (counterId summary) ]
       , h3 [ style "margin:8px 0 6px 0; font-size:26px;" ] [ Text (name summary) ]
       , div [ style "font-size:54px; font-weight:700; color:#1d5b39; line-height:0.95;" ] [ Text (show (value summary)) ]
       , div [ style "font-size:24px; letter-spacing:1px; margin:6px 0 14px 0; color:#406657; min-height:30px;" ] [ Text (roman summary) ]
       , actionButton (busy s) openAction
       ]

createPanel : State -> Node Msg
createPanel s =
  div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:16px; padding:16px; margin-bottom:18px;" ]
    [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px; margin-bottom:4px;" ] [ Text (screenPolicyText CountersOverview) ]
    , h2 [ style "margin:0 0 8px 0; font-size:28px;" ] [ Text "Counters" ]
    , div [ style "display:flex; gap:10px; flex-wrap:wrap;" ]
        [ input [ onInput CreateNameChanged, HtmlAttr.value (createName s), placeholder "new counter name", style "padding:10px; border:1px solid #98aaba; border-radius:10px; min-width:240px;" ] []
        , actionButton (busy s) CreateCounterAction
        ]
    ]

overviewSection : State -> Node Msg
overviewSection s =
  let cards = map (overviewCard s) (filter keepSummary (summaryList s))
  in div []
       [ createPanel s
       , if null cards
           then div [ style "padding:18px; background:#ffffffd9; border:1px dashed #bcc9d5; border-radius:16px;" ] [ Text "No counters yet." ]
           else div [ style "display:flex; gap:14px; flex-wrap:wrap;" ] cards
       ]
  where
    keepSummary : CounterSummary -> Bool
    keepSummary summary = any matches (overviewActions s)
      where
        matches : Action -> Bool
        matches (OpenCounterAction current) = current == counterId summary
        matches _ = False

historyRow : Nat -> CounterEvent -> Node Msg
historyRow idx event =
  li [ style "margin-bottom:6px;" ] [ Text ("v" ++ show idx ++ " " ++ renderHistoryEvent event) ]

detailSection : State -> CounterDetail -> Node Msg
detailSection s detail =
  let visibleActions = detailActions s
      showIncrement = any isIncrement visibleActions
      showDecrement = any isDecrement visibleActions
      historyNodes = zipWith historyRow [1..length (history detail)] (history detail)
  in div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:18px; padding:18px;" ]
       [ div [ style "display:flex; gap:10px; flex-wrap:wrap; align-items:center; margin-bottom:12px;" ]
           [ actionButton (busy s) BackToCountersAction
           , div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px; margin-left:auto;" ] [ Text (screenPolicyText CounterDetailScreen ++ " · v" ++ show (version detail)) ]
           ]
       , h2 [ style "margin:0 0 4px 0; font-size:30px;" ] [ Text (name detail) ]
       , div [ style "font-size:84px; font-weight:700; line-height:0.9; color:#1b4f3e;" ] [ Text (show (value detail)) ]
       , div [ style "font-size:28px; letter-spacing:1px; margin-top:6px; color:#406657; min-height:34px;" ] [ Text (roman detail) ]
       , div [ style "display:flex; gap:10px; flex-wrap:wrap; margin:14px 0 16px 0;" ]
           ( (if showIncrement then [actionButton (busy s) IncrementCounterAction] else [])
             ++ (if showDecrement then [actionButton (busy s) DecrementCounterAction] else [])
           )
       , h3 [ style "margin:0 0 8px 0;" ] [ Text "Event History" ]
       , if null historyNodes
           then Text "No events yet."
           else ul [ style "margin:0; padding-left:20px;" ] historyNodes
       ]
  where
    isIncrement : Action -> Bool
    isIncrement IncrementCounterAction = True
    isIncrement _ = False

    isDecrement : Action -> Bool
    isDecrement DecrementCounterAction = True
    isDecrement _ = False

overviewStatusText : State -> String
overviewStatusText s =
  case clientId s of
    Nothing => "Overview feed: disconnected"
    Just _ => "Overview feed: connected"

detailStatusText : State -> String
detailStatusText s =
  case currentCounterId s of
    Nothing => "Detail feed: idle"
    Just current => "Detail feed: " ++ current

viewNodes : State -> List (Node Msg)
viewNodes s =
  let body =
        case (screen s, selectedDetail s) of
          (CountersOverview, _) => overviewSection s
          (CounterDetailScreen, Just detail) => detailSection s detail
          (CounterDetailScreen, Nothing) => overviewSection s
  in
  [ div [ style "min-height:100vh; padding:24px; background:linear-gradient(135deg,#f4efe5 0%, #e7eef6 55%, #dde7d7 100%); font-family:Georgia,serif; color:#20303b;" ]
      [ div [ style "max-width:1100px; margin:0 auto;" ]
          [ div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:14px; padding:12px 14px; margin-bottom:18px; display:flex; gap:12px; flex-wrap:wrap;" ]
              [ Text ("Status: " ++ statusText s)
              , div [ style "margin-left:auto; font-size:12px; opacity:0.72;" ] [ Text (overviewStatusText s ++ " · " ++ detailStatusText s) ]
              ]
          , body
          ]
      ]
  ]

updateView : State -> Cmd Msg
updateView s = children Ref.Body (viewNodes s)

controller : Msg -> State -> (State, Cmd Msg)
controller Initialized s =
  let s' = { busy := True, status := "Connecting overview feed..." } s in
  (s', batch [updateView s', FrontendSSE.requestClientId ClientIdReady])

controller (ClientIdReady cid) s =
  let s' = { clientId := Just cid, busy := True, status := "Loading counters..." } s in
  (s', batch [updateView s', subscribeOverview cid, loadSummaries])

controller (OverviewLoaded (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (OverviewLoaded (Right loaded)) s =
  let summaryMap = SortedMap.fromList (map (\summary => (counterId summary, summary)) loaded)
      s' = { summaries := summaryMap, busy := False, status := "Counters synced." } s in
  (s', updateView s')

controller (OverviewEventReceived raw) s =
  case decode {a=MultiplexedStreamEvent String CounterEvent} raw of
    Left _ =>
      let s' = { busy := True, status := "Overview feed decode failed. Reloading counters..." } s in
      (s', batch [updateView s', loadSummaries])
    Right msg =>
      let s' = { busy := False, status := "Overview updated from " ++ streamId msg ++ "." } (applyOverviewEvent msg s) in
      (s', updateView s')

controller (CreateNameChanged value) s = ({ createName := value } s, Cmd.noAction)

controller CreateCounterClicked s =
  let cleanName = trim (createName s) in
  if cleanName == "" then
    let s' = { busy := False, status := "Counter name is required." } s in
    (s', updateView s')
  else
    let freshId = nextCounterId s
        s' = { busy := True, status := "Creating counter " ++ freshId ++ "..." } s in
    (s', batch [updateView s', postCreateCounter freshId cleanName])

controller (CreateCounterFinished counterId (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (CreateCounterFinished counterId (Right _)) s =
  let s' = { screen := CounterDetailScreen, selectedDetail := Nothing, createName := "", busy := True, status := "Counter created. Opening " ++ counterId ++ "..." } s in
  (s', batch (updateView s' :: openDetailCommands s counterId))

controller (OpenCounterClicked counterId) s =
  let s' = { screen := CounterDetailScreen, selectedDetail := Nothing, busy := True, status := "Opening " ++ counterId ++ "..." } s in
  (s', batch (updateView s' :: openDetailCommands s counterId))

controller (DetailResyncFinished counterId (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (DetailResyncFinished counterId (Right payload)) s =
  let detail = detailFromEvents counterId (version payload) (events payload)
      s' = updateSummaryFromDetail detail ({ selectedDetail := Just detail, busy := False, status := "Counter synced: " ++ counterId } s) in
  (s', updateView s')

controller (DetailEventReceived streamId raw) s =
  case selectedDetail s of
    Nothing => (s, Cmd.noAction)
    Just detail =>
      if streamId /= counterId detail then
        (s, Cmd.noAction)
      else
        case decode {a=StreamEvent CounterEvent} raw of
          Left _ =>
            let s' = { busy := True, status := "Detail feed decode failed. Resyncing..." } s in
            (s', batch [updateView s', getDetailResync streamId])
          Right msg =>
            case applyDetailEvent msg detail of
              Left err =>
                let s' = { busy := True, status := err ++ " Resyncing..." } s in
                (s', batch [updateView s', getDetailResync streamId])
              Right nextDetail =>
                let s' = updateSummaryFromDetail nextDetail ({ selectedDetail := Just nextDetail, busy := False, status := "Live update for " ++ streamId ++ "." } s) in
                (s', updateView s')

controller BackToCountersClicked s =
  let s' = { screen := CountersOverview, selectedDetail := Nothing, busy := False, status := "Back on overview." } s in
  (s', batch (updateView s' :: closeCurrentDetail s))

controller IncrementClicked s =
  case selectedDetail s of
    Nothing => (s, Cmd.noAction)
    Just detail =>
      let s' = { busy := True, status := "Incrementing " ++ counterId detail ++ "..." } s in
      (s', batch [updateView s', postIncrement (counterId detail) (version detail)])

controller (IncrementFinished _ (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (IncrementFinished counterId (Right _)) s =
  let s' = { busy := False, status := "Increment command accepted for " ++ counterId ++ "." } s in
  (s', updateView s')

controller DecrementClicked s =
  case selectedDetail s of
    Nothing => (s, Cmd.noAction)
    Just detail =>
      let s' = { busy := True, status := "Decrementing " ++ counterId detail ++ "..." } s in
      (s', batch [updateView s', postDecrement (counterId detail) (version detail)])

controller (DecrementFinished _ (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (DecrementFinished counterId (Right _)) s =
  let s' = { busy := False, status := "Decrement command accepted for " ++ counterId ++ "." } s in
  (s', updateView s')

onError : JS.Util.JSErr -> IO ()
onError = putStrLn . dispErr

covering
main : IO ()
main = runController {e=Msg, s=State} controller onError Initialized initialState
