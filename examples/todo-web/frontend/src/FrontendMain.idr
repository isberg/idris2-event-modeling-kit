module FrontendMain

import Data.List
import Data.Maybe
import Data.SortedMap as SortedMap
import Data.String
import Domain
import Domain.JSON.Simple
import EmKit.Frontend.Execute as FrontendExecute
import EmKit.Frontend.SSE as FrontendSSE
import EmKit.Modeling.Pattern.StateView
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
  summaries : SortedMap.SortedMap String TodoListSummary
  selectedDetail : Maybe TodoListDetail
  createTitle : String
  addItemText : String
  status : String
  busy : Bool
  clientId : Maybe String

initialState : State
initialState = MkState ListsOverview SortedMap.empty Nothing "Errands" "Buy milk" "Connecting overview feed..." True Nothing

data Msg : Type where
  Initialized : Msg
  ClientIdReady : String -> Msg
  OverviewLoaded : Either HTTPError (List TodoListSummary) -> Msg
  OverviewEventReceived : String -> Msg
  CreateTitleChanged : String -> Msg
  CreateListClicked : Msg
  CreateListFinished : String -> Either HTTPError () -> Msg
  OpenListClicked : String -> Msg
  DetailResyncFinished : String -> Either HTTPError (ResyncPayload TodoEvent) -> Msg
  DetailEventReceived : String -> String -> Msg
  BackToListsClicked : Msg
  AddItemTextChanged : String -> Msg
  AddItemClicked : Msg
  AddItemFinished : String -> Either HTTPError () -> Msg
  ToggleItemClicked : String -> Msg
  ToggleItemFinished : String -> Either HTTPError () -> Msg

httpErrorMessage : HTTPError -> String
httpErrorMessage Timeout = "Request timed out."
httpErrorMessage NetworkError = "Network error. Run ./scripts/run.sh and open /static/index.html on the configured port."
httpErrorMessage (BadStatus code) = "Server returned status " ++ show code ++ "."
httpErrorMessage (JSONError _ _) = "Failed to decode JSON response."

overviewEventsUrl : String -> String
overviewEventsUrl clientId = "/api/todo/overview-events/" ++ clientId

detailEventsUrl : String -> String -> String
detailEventsUrl listId clientId = "/api/todo/events/" ++ listId ++ "/" ++ clientId

executeUrl : String -> String
executeUrl listId = "/api/todo/execute/" ++ listId

resyncUrl : String -> String
resyncUrl listId = "/api/todo/resync/" ++ listId

loadSummaries : Cmd Msg
loadSummaries = get "/api/todo/lists" (ExpectJSON OverviewLoaded)

subscribeOverview : String -> Cmd Msg
subscribeOverview clientId = FrontendSSE.subscribe (overviewEventsUrl clientId) OverviewEventReceived

subscribeDetail : String -> String -> Cmd Msg
subscribeDetail listId clientId = FrontendSSE.subscribe (detailEventsUrl listId clientId) (DetailEventReceived listId)

closeDetail : String -> String -> Cmd Msg
closeDetail listId clientId = FrontendSSE.close (detailEventsUrl listId clientId)

getDetailResync : String -> Cmd Msg
getDetailResync listId = FrontendExecute.getResync resyncUrl DetailResyncFinished listId

postCreateList : String -> String -> Cmd Msg
postCreateList listId title = FrontendExecute.postExecute executeUrl CreateListFinished listId 0 (CreateList title)

postAddItem : String -> Nat -> String -> String -> Cmd Msg
postAddItem listId currentVersion itemId text = FrontendExecute.postExecute executeUrl AddItemFinished listId currentVersion (AddItem itemId text)

postToggleItem : String -> Nat -> String -> Cmd Msg
postToggleItem listId currentVersion itemId = FrontendExecute.postExecute executeUrl ToggleItemFinished listId currentVersion (ToggleItem itemId)

statusText : State -> String
statusText s = if busy s then "Working: " ++ status s else status s

summaryList : State -> List TodoListSummary
summaryList s = filter exists (SortedMap.values (summaries s))

bundleForState : State -> AppBundle
bundleForState s = bundleForApp (summaryList s) (selectedDetail s)

screenPolicyText : Screen -> String
screenPolicyText currentScreen =
  case dataSourcePolicy (specFor {bundle=AppBundle} currentScreen) of
    QueryOnly => "QueryOnly"
    ClientProjectionOnly => "ClientProjectionOnly"
    HybridProjection => "HybridProjection"

currentListId : State -> Maybe String
currentListId s = map listId (selectedDetail s)

replaceSummary : TodoListSummary -> State -> State
replaceSummary summary s = { summaries := SortedMap.insert (listId summary) summary (summaries s) } s

detailToView : TodoListDetail -> TodoListView
detailToView detail = MkTodoListView (exists detail) (title detail) (items detail) (openCount detail) (doneCount detail)

updateSummaryFromDetail : TodoListDetail -> State -> State
updateSummaryFromDetail detail s = replaceSummary (summaryFromView (listId detail) (version detail) (detailToView detail)) s

actionsForCurrentScreen : State -> List Action
actionsForCurrentScreen s = availableScreenActions (bundleForState s) (screen s)

overviewActions : State -> List Action
overviewActions s = filter keep (actionsForCurrentScreen s)
  where
    keep : Action -> Bool
    keep CreateListAction = True
    keep (OpenListAction _) = True
    keep _ = False

detailActions : State -> List Action
detailActions s = filter keep (actionsForCurrentScreen s)
  where
    keep : Action -> Bool
    keep BackToListsAction = True
    keep AddItemAction = True
    keep (ToggleItemAction _) = True
    keep _ = False

applyOverviewEvent : MultiplexedStreamEvent String TodoEvent -> State -> State
applyOverviewEvent msg s =
  let sid = streamId msg
      current = fromMaybe (emptySummary sid) (SortedMap.lookup sid (summaries s))
  in case applySummaryEvent sid (streamVersion msg) (event msg) current of
       Left _ => s
       Right next => replaceSummary next s

applyDetailEvent : StreamEvent TodoEvent -> TodoListDetail -> Either String TodoListDetail
applyDetailEvent msg detail =
  if version msg <= version detail then
    Right detail
  else
    let expected = S (version detail) in
    if version msg /= expected then
      Left ("Detail stream version gap: expected v" ++ show expected ++ ", got v" ++ show (version msg) ++ ".")
    else
      let nextView = projectEvent (detailToView detail) (event msg)
      in Right (detailFromView (listId detail) (version msg) nextView)

nextListId : State -> String
nextListId s = listPrefix ++ show (S (length (summaryList s)))

nextItemId : TodoListDetail -> String
nextItemId detail = itemPrefix ++ show (S (length (items detail)))

closeCurrentDetail : State -> List (Cmd Msg)
closeCurrentDetail s =
  case (currentListId s, clientId s) of
    (Just current, Just cid) => [closeDetail current cid]
    _ => []

openDetailCommands : State -> String -> List (Cmd Msg)
openDetailCommands s listId =
  case clientId s of
    Nothing => [FrontendSSE.requestClientId ClientIdReady]
    Just cid => closeCurrentDetail s ++ [subscribeDetail listId cid, getDetailResync listId]

messageForAction : Action -> Msg
messageForAction CreateListAction = CreateListClicked
messageForAction (OpenListAction listId) = OpenListClicked listId
messageForAction BackToListsAction = BackToListsClicked
messageForAction AddItemAction = AddItemClicked
messageForAction (ToggleItemAction itemId) = ToggleItemClicked itemId

actionButton : Bool -> Action -> Node Msg
actionButton isBusy action =
  button
    [ onClick (messageForAction action)
    , disabled isBusy
    , style "padding:9px 12px; border:1px solid #3b5d7e; border-radius:10px; background:#eef5fb;"
    ]
    [ Text (renderAction action) ]

overviewCard : State -> TodoListSummary -> Node Msg
overviewCard s summary =
  let openAction = OpenListAction (listId summary)
  in div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:18px; padding:18px; min-width:220px; flex:1;" ]
       [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;" ] [ Text (listId summary) ]
       , h3 [ style "margin:8px 0 6px 0; font-size:26px;" ] [ Text (title summary) ]
       , div [ style "font-size:42px; font-weight:700; color:#1d5b39; line-height:0.95;" ] [ Text (show (openCount summary)) ]
       , div [ style "font-size:13px; opacity:0.78; margin:6px 0 14px 0;" ] [ Text (show (doneCount summary) ++ " done") ]
       , actionButton (busy s) openAction
       ]

createPanel : State -> Node Msg
createPanel s =
  div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:16px; padding:16px; margin-bottom:18px;" ]
    [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px; margin-bottom:4px;" ] [ Text (screenPolicyText ListsOverview) ]
    , h2 [ style "margin:0 0 8px 0; font-size:28px;" ] [ Text "Todo Lists" ]
    , div [ style "display:flex; gap:10px; flex-wrap:wrap;" ]
        [ input [ onInput CreateTitleChanged, HtmlAttr.value (createTitle s), placeholder "new list title", style "padding:10px; border:1px solid #98aaba; border-radius:10px; min-width:240px;" ] []
        , actionButton (busy s) CreateListAction
        ]
    ]

overviewSection : State -> Node Msg
overviewSection s =
  let cards = map (overviewCard s) (filter keepSummary (summaryList s))
  in div []
       [ createPanel s
       , if null cards
           then div [ style "padding:18px; background:#ffffffd9; border:1px dashed #bcc9d5; border-radius:16px;" ] [ Text "No lists yet." ]
           else div [ style "display:flex; gap:14px; flex-wrap:wrap;" ] cards
       ]
  where
    keepSummary : TodoListSummary -> Bool
    keepSummary summary = any matches (overviewActions s)
      where
        matches : Action -> Bool
        matches (OpenListAction current) = current == listId summary
        matches _ = False

itemRow : State -> TodoItem -> Node Msg
itemRow s item =
  let toggleAction = ToggleItemAction (itemId item)
      itemStateText = case status item of
        ItemOpen => "open"
        ItemDone => "done"
      lineStyle = case status item of
        ItemOpen => "font-size:18px;"
        ItemDone => "font-size:18px; text-decoration:line-through; opacity:0.65;"
  in li [ style "display:flex; gap:10px; align-items:center; margin-bottom:10px;" ]
       [ actionButton (busy s) toggleAction
       , div [ style lineStyle ] [ Text (text item) ]
       , div [ style "font-size:12px; opacity:0.6; margin-left:auto;" ] [ Text (itemId item ++ " · " ++ itemStateText) ]
       ]

detailSection : State -> TodoListDetail -> Node Msg
detailSection s detail =
  let visibleActions = detailActions s
      showAdd = any isAdd visibleActions
      itemsNode = if null (items detail)
        then [Text "No items yet."]
        else [ul [ style "margin:14px 0 0 0; padding-left:0; list-style:none;" ] (map (itemRow s) (items detail))]
  in div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:18px; padding:18px;" ]
       ( [ div [ style "display:flex; gap:10px; flex-wrap:wrap; align-items:center; margin-bottom:12px;" ]
             [ actionButton (busy s) BackToListsAction
             , div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px; margin-left:auto;" ] [ Text (screenPolicyText ListDetailScreen ++ " · v" ++ show (version detail)) ]
             ]
         , h2 [ style "margin:0 0 4px 0; font-size:30px;" ] [ Text (title detail) ]
         , div [ style "font-size:14px; opacity:0.76; margin-bottom:12px;" ] [ Text (show (openCount detail) ++ " open · " ++ show (doneCount detail) ++ " done") ]
         , if showAdd
             then div [ style "display:flex; gap:10px; flex-wrap:wrap; margin-bottom:12px;" ]
                    [ input [ onInput AddItemTextChanged, HtmlAttr.value (addItemText s), placeholder "new item text", style "padding:10px; border:1px solid #98aaba; border-radius:10px; min-width:240px;" ] []
                    , actionButton (busy s) AddItemAction
                    ]
             else Text ""
         ] ++ itemsNode
       )
  where
    isAdd : Action -> Bool
    isAdd AddItemAction = True
    isAdd _ = False

overviewStatusText : State -> String
overviewStatusText s =
  case clientId s of
    Nothing => "Overview feed: disconnected"
    Just _ => "Overview feed: connected"

detailStatusText : State -> String
detailStatusText s =
  case currentListId s of
    Nothing => "Detail feed: idle"
    Just current => "Detail feed: " ++ current

viewNodes : State -> List (Node Msg)
viewNodes s =
  let body =
        case (screen s, selectedDetail s) of
          (ListsOverview, _) => overviewSection s
          (ListDetailScreen, Just detail) => detailSection s detail
          (ListDetailScreen, Nothing) => overviewSection s
  in
  [ div [ style "min-height:100vh; padding:24px; background:linear-gradient(135deg,#f5ecde 0%, #e7eef7 55%, #dfe8dc 100%); font-family:Georgia,serif; color:#21303a;" ]
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
  let s' = { clientId := Just cid, busy := True, status := "Loading todo lists..." } s in
  (s', batch [updateView s', subscribeOverview cid, loadSummaries])

controller (OverviewLoaded (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (OverviewLoaded (Right loaded)) s =
  let summaryMap = SortedMap.fromList (map (\summary => (listId summary, summary)) loaded)
      s' = { summaries := summaryMap, busy := False, status := "Todo lists synced." } s in
  (s', updateView s')

controller (OverviewEventReceived raw) s =
  case decode {a=MultiplexedStreamEvent String TodoEvent} raw of
    Left _ =>
      let s' = { busy := True, status := "Overview feed decode failed. Reloading lists..." } s in
      (s', batch [updateView s', loadSummaries])
    Right msg =>
      case applySummaryEvent (streamId msg)
             (streamVersion msg)
             (event msg)
             (fromMaybe (emptySummary (streamId msg)) (SortedMap.lookup (streamId msg) (summaries s))) of
        Left err =>
          let s' = { busy := True, status := err ++ " Reloading lists..." } s in
          (s', batch [updateView s', loadSummaries])
        Right nextSummary =>
          let s' = { busy := False, status := "Overview updated from " ++ streamId msg ++ "." } (replaceSummary nextSummary s) in
          (s', updateView s')

controller (CreateTitleChanged value) s = ({ createTitle := value } s, Cmd.noAction)

controller CreateListClicked s =
  let cleanTitle = trim (createTitle s) in
  if cleanTitle == "" then
    let s' = { busy := False, status := "List title is required." } s in
    (s', updateView s')
  else
    let freshId = nextListId s
        s' = { busy := True, status := "Creating list " ++ freshId ++ "..." } s in
    (s', batch [updateView s', postCreateList freshId cleanTitle])

controller (CreateListFinished listId (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (CreateListFinished listId (Right _)) s =
  let s' = { screen := ListDetailScreen, selectedDetail := Nothing, createTitle := "", busy := True, status := "List created. Opening " ++ listId ++ "..." } s in
  (s', batch (updateView s' :: openDetailCommands s listId))

controller (OpenListClicked listId) s =
  let s' = { screen := ListDetailScreen, selectedDetail := Nothing, busy := True, status := "Opening " ++ listId ++ "..." } s in
  (s', batch (updateView s' :: openDetailCommands s listId))

controller (DetailResyncFinished listId (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (DetailResyncFinished listId (Right payload)) s =
  let detail = detailFromEvents listId (version payload) (events payload)
      s' = updateSummaryFromDetail detail ({ selectedDetail := Just detail, busy := False, status := "List synced: " ++ listId } s) in
  (s', updateView s')

controller (DetailEventReceived streamId raw) s =
  case selectedDetail s of
    Nothing => (s, Cmd.noAction)
    Just detail =>
      if streamId /= listId detail then
        (s, Cmd.noAction)
      else
        case decode {a=StreamEvent TodoEvent} raw of
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

controller BackToListsClicked s =
  let s' = { screen := ListsOverview, selectedDetail := Nothing, busy := False, status := "Back on overview." } s in
  (s', batch (updateView s' :: closeCurrentDetail s))

controller (AddItemTextChanged value) s = ({ addItemText := value } s, Cmd.noAction)

controller AddItemClicked s =
  case selectedDetail s of
    Nothing => (s, Cmd.noAction)
    Just detail =>
      let cleanText = trim (addItemText s) in
      if cleanText == "" then
        let s' = { busy := False, status := "Item text is required." } s in
        (s', updateView s')
      else
        let freshItemId = nextItemId detail
            s' = { busy := True, status := "Adding item " ++ freshItemId ++ "..." } s in
        (s', batch [updateView s', postAddItem (listId detail) (version detail) freshItemId cleanText])

controller (AddItemFinished _ (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (AddItemFinished listId (Right _)) s =
  let s' = { busy := False, addItemText := "", status := "Item command accepted for " ++ listId ++ "." } s in
  (s', updateView s')

controller (ToggleItemClicked itemId) s =
  case selectedDetail s of
    Nothing => (s, Cmd.noAction)
    Just detail =>
      let s' = { busy := True, status := "Toggling " ++ itemId ++ "..." } s in
      (s', batch [updateView s', postToggleItem (listId detail) (version detail) itemId])

controller (ToggleItemFinished _ (Left err)) s =
  let s' = { busy := False, status := httpErrorMessage err } s in
  (s', updateView s')

controller (ToggleItemFinished listId (Right _)) s =
  let s' = { busy := False, status := "Toggle command accepted for " ++ listId ++ "." } s in
  (s', updateView s')

onError : JS.Util.JSErr -> IO ()
onError = putStrLn . dispErr

covering
main : IO ()
main = runController {e=Msg, s=State} controller onError Initialized initialState
