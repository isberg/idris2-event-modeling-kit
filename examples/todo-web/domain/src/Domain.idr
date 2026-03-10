module Domain

import Data.List
import Data.String
import EmKit.Modeling.Pattern.StateView
import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Sourcing.Decider
import EmKit.Stream.Version

%default total

public export
itemPrefix : String
itemPrefix = "item-"

public export
listPrefix : String
listPrefix = "todo-"

public export
data ItemStatus = ItemOpen | ItemDone

public export
Eq ItemStatus where
  ItemOpen == ItemOpen = True
  ItemDone == ItemDone = True
  _ == _ = False

public export
record TodoItem where
  constructor MkTodoItem
  itemId : String
  text : String
  status : ItemStatus

public export
record TodoListState where
  constructor MkTodoListState
  exists : Bool
  title : String
  items : List TodoItem

public export
record TodoListView where
  constructor MkTodoListView
  exists : Bool
  title : String
  items : List TodoItem
  openCount : Nat
  doneCount : Nat

public export
record TodoListSummary where
  constructor MkTodoListSummary
  listId : String
  version : Nat
  exists : Bool
  title : String
  openCount : Nat
  doneCount : Nat

public export
record TodoListDetail where
  constructor MkTodoListDetail
  listId : String
  version : Nat
  exists : Bool
  title : String
  items : List TodoItem
  openCount : Nat
  doneCount : Nat

public export
record AppBundle where
  constructor MkAppBundle
  summaries : List TodoListSummary
  selectedDetail : Maybe TodoListDetail

public export
data Screen = ListsOverview | ListDetailScreen

public export
data Action
  = CreateListAction
  | OpenListAction String
  | BackToListsAction
  | AddItemAction
  | ToggleItemAction String

public export
data Intent
  = PromptCreateList
  | ShowListDetail String
  | ShowOverview
  | PromptAddItem
  | RunToggleItem String

public export
data Command
  = CreateList String
  | AddItem String String
  | ToggleItem String

public export
data Rejection
  = ListAlreadyCreated
  | ListMissing
  | EmptyListTitle
  | EmptyItemText
  | ItemAlreadyExists String
  | ItemMissing String

public export
data TodoEvent
  = ListCreated String
  | ItemAdded String String
  | ItemCompleted String
  | ItemReopened String

public export
renderRejection : Rejection -> String
renderRejection ListAlreadyCreated = "list already exists."
renderRejection ListMissing = "list does not exist yet."
renderRejection EmptyListTitle = "list title is required."
renderRejection EmptyItemText = "item text is required."
renderRejection (ItemAlreadyExists itemId) = "item already exists: " ++ itemId
renderRejection (ItemMissing itemId) = "item does not exist: " ++ itemId

public export
renderAction : Action -> String
renderAction CreateListAction = "Create list"
renderAction (OpenListAction listId) = "Open " ++ listId
renderAction BackToListsAction = "Back to lists"
renderAction AddItemAction = "Add item"
renderAction (ToggleItemAction itemId) = "Toggle " ++ itemId

decNat : Nat -> Nat
decNat Z = Z
decNat (S k) = k

dropPrefixChars : List Char -> List Char -> Maybe (List Char)
dropPrefixChars [] xs = Just xs
dropPrefixChars (_ :: _) [] = Nothing
dropPrefixChars (p :: ps) (x :: xs) =
  if p == x
    then dropPrefixChars ps xs
    else Nothing

digitNat : Char -> Maybe Nat
digitNat '0' = Just 0
digitNat '1' = Just 1
digitNat '2' = Just 2
digitNat '3' = Just 3
digitNat '4' = Just 4
digitNat '5' = Just 5
digitNat '6' = Just 6
digitNat '7' = Just 7
digitNat '8' = Just 8
digitNat '9' = Just 9
digitNat _ = Nothing

parseNatDigits : List Char -> Nat -> Maybe Nat
parseNatDigits [] acc = Just acc
parseNatDigits (c :: cs) acc =
  case digitNat c of
    Nothing => Nothing
    Just d => parseNatDigits cs (acc * 10 + d)

suffixNat : String -> String -> Maybe Nat
suffixNat idPrefix raw =
  case dropPrefixChars (unpack idPrefix) (unpack raw) of
    Nothing => Nothing
    Just [] => Nothing
    Just digits => parseNatDigits digits 0

maxNat : Nat -> Nat -> Nat
maxNat x y = if x < y then y else x

maxSuffixFor : String -> List String -> Nat
maxSuffixFor idPrefix [] = 0
maxSuffixFor idPrefix (raw :: rest) =
  let tailMax = maxSuffixFor idPrefix rest in
  case suffixNat idPrefix raw of
    Nothing => tailMax
    Just n => maxNat n tailMax

public export
nextListIdFromSummaries : List TodoListSummary -> String
nextListIdFromSummaries summaries =
  let ids = map listId summaries
      next = S (maxSuffixFor listPrefix ids)
  in listPrefix ++ show next

public export
nextItemIdFromItems : List TodoItem -> String
nextItemIdFromItems items =
  let ids = map itemId items
      next = S (maxSuffixFor itemPrefix ids)
  in itemPrefix ++ show next

findItemById : String -> List TodoItem -> Maybe TodoItem
findItemById _ [] = Nothing
findItemById wanted (item :: rest) =
  if itemId item == wanted
    then Just item
    else findItemById wanted rest

itemExists : String -> List TodoItem -> Bool
itemExists wanted items =
  case findItemById wanted items of
    Just _ => True
    Nothing => False

setStatus : String -> ItemStatus -> List TodoItem -> List TodoItem
setStatus _ _ [] = []
setStatus wanted newStatus (item :: rest) =
  if itemId item == wanted
    then MkTodoItem (itemId item) (text item) newStatus :: rest
    else item :: setStatus wanted newStatus rest

countOpen : List TodoItem -> Nat
countOpen [] = Z
countOpen (item :: rest) =
  case status item of
    ItemOpen => S (countOpen rest)
    ItemDone => countOpen rest

countDone : List TodoItem -> Nat
countDone [] = Z
countDone (item :: rest) =
  case status item of
    ItemOpen => countDone rest
    ItemDone => S (countDone rest)

public export
summaryFromView : String -> Nat -> TodoListView -> TodoListSummary
summaryFromView listId streamVersion view =
  MkTodoListSummary listId streamVersion (exists view) (title view) (openCount view) (doneCount view)

public export
detailFromView : String -> Nat -> TodoListView -> TodoListDetail
detailFromView listId version view =
  MkTodoListDetail listId version (exists view) (title view) (items view) (openCount view) (doneCount view)

public export
summaryFromDetail : TodoListDetail -> TodoListSummary
summaryFromDetail detail =
  MkTodoListSummary (listId detail) (version detail) (exists detail) (title detail) (openCount detail) (doneCount detail)

public export
applySummaryEvent : String -> Nat -> TodoEvent -> TodoListSummary -> Either String TodoListSummary
applySummaryEvent listId streamVersion event summary =
  case applyVersionedUpdate listId (version summary) streamVersion step summary of
    Left (VersionGap _ expected incoming) =>
      Left ("Overview summary gap for " ++ listId ++ ": expected v" ++ show expected ++ ", got v" ++ show incoming ++ ".")
    Right (IgnoredStale current) => Right current
    Right (Applied next) => Right next
  where
    step : Nat -> TodoListSummary -> TodoListSummary
    step nextVersion current =
      case event of
        ListCreated title => MkTodoListSummary listId nextVersion True title 0 0
        ItemAdded _ _ => { version := nextVersion, exists := True, openCount := S (openCount current) } current
        ItemCompleted _ => { version := nextVersion, openCount := decNat (openCount current), doneCount := S (doneCount current) } current
        ItemReopened _ => { version := nextVersion, openCount := S (openCount current), doneCount := decNat (doneCount current) } current

public export
detailToView : TodoListDetail -> TodoListView
detailToView detail =
  MkTodoListView (exists detail) (title detail) (items detail) (openCount detail) (doneCount detail)

public export
applyDetailEvent : Nat -> TodoEvent -> TodoListDetail -> Either String TodoListDetail
applyDetailEvent streamVersion event detail =
  let lid = listId detail in
  case applyVersionedUpdate lid (version detail) streamVersion step detail of
    Left (VersionGap _ expected incoming) =>
      Left ("Detail stream version gap: expected v" ++ show expected ++ ", got v" ++ show incoming ++ ".")
    Right (IgnoredStale current) => Right current
    Right (Applied next) => Right next
  where
    step : Nat -> TodoListDetail -> TodoListDetail
    step nextVersion current =
      case event of
        ListCreated createdTitle =>
          MkTodoListDetail (listId current) nextVersion True createdTitle [] 0 0
        ItemAdded itemId text =>
          let nextItems = items current ++ [MkTodoItem itemId text ItemOpen]
          in MkTodoListDetail (listId current) nextVersion True (title current) nextItems (S (openCount current)) (doneCount current)
        ItemCompleted itemId =>
          let nextItems = setStatus itemId ItemDone (items current)
          in MkTodoListDetail (listId current) nextVersion True (title current) nextItems (decNat (openCount current)) (S (doneCount current))
        ItemReopened itemId =>
          let nextItems = setStatus itemId ItemOpen (items current)
          in MkTodoListDetail (listId current) nextVersion True (title current) nextItems (S (openCount current)) (decNat (doneCount current))

public export
emptySummary : String -> TodoListSummary
emptySummary listId = MkTodoListSummary listId 0 False "" 0 0

public export
bundleForApp : List TodoListSummary -> Maybe TodoListDetail -> AppBundle
bundleForApp = MkAppBundle

data CommandLegal : Command -> TodoListState -> Type where
  CanCreateMissing :
    {rawTitle : String} ->
    (cleanTitle : String) ->
    CommandLegal (CreateList rawTitle) state
  CanAddFreshItem :
    {itemId : String} ->
    {rawText : String} ->
    (cleanText : String) ->
    CommandLegal (AddItem itemId rawText) state
  CanToggleOpenItem :
    {itemId : String} ->
    CommandLegal (ToggleItem itemId) state
  CanToggleDoneItem :
    {itemId : String} ->
    CommandLegal (ToggleItem itemId) state

createLegal : (rawTitle : String) -> (state : TodoListState) -> Either Rejection (CommandLegal (CreateList rawTitle) state)
createLegal rawTitle (MkTodoListState False currentTitle items) =
  let cleanTitle = trim rawTitle in
    if cleanTitle == ""
      then Left EmptyListTitle
      else Right (CanCreateMissing cleanTitle)
createLegal _ (MkTodoListState True _ _) = Left ListAlreadyCreated

addItemLegal : (itemId : String) -> (rawText : String) -> (state : TodoListState) -> Either Rejection (CommandLegal (AddItem itemId rawText) state)
addItemLegal _ _ (MkTodoListState False _ _) = Left ListMissing
addItemLegal itemId rawText (MkTodoListState True currentTitle items) =
  let cleanText = trim rawText in
    if cleanText == ""
      then Left EmptyItemText
      else if itemExists itemId items
        then Left (ItemAlreadyExists itemId)
        else Right (CanAddFreshItem cleanText)

toggleLegal : (itemId : String) -> (state : TodoListState) -> Either Rejection (CommandLegal (ToggleItem itemId) state)
toggleLegal _ (MkTodoListState False _ _) = Left ListMissing
toggleLegal itemId (MkTodoListState True currentTitle items) =
  case findItemById itemId items of
    Nothing => Left (ItemMissing itemId)
    Just item =>
      case status item of
        ItemOpen => Right CanToggleOpenItem
        ItemDone => Right CanToggleDoneItem

public export
implementation Projection TodoEvent TodoListState where
  initial = MkTodoListState False "" []
  evolve _ (ListCreated createdTitle) = MkTodoListState True createdTitle []
  evolve state (ItemAdded newItemId newText) =
    { items := items state ++ [MkTodoItem newItemId newText ItemOpen] } state
  evolve state (ItemCompleted targetItemId) =
    { items := setStatus targetItemId ItemDone (items state) } state
  evolve state (ItemReopened targetItemId) =
    { items := setStatus targetItemId ItemOpen (items state) } state

public export
implementation Decider List Command Rejection TodoEvent TodoListState where
  Legal = CommandLegal

  legal (CreateList rawTitle) state = createLegal rawTitle state
  legal (AddItem itemId rawText) state = addItemLegal itemId rawText state
  legal (ToggleItem itemId) state = toggleLegal itemId state

  decide (CreateList rawTitle) state (CanCreateMissing cleanTitle) = [ListCreated cleanTitle]
  decide (AddItem itemId rawText) state (CanAddFreshItem cleanText) = [ItemAdded itemId cleanText]
  decide (ToggleItem itemId) state CanToggleOpenItem = [ItemCompleted itemId]
  decide (ToggleItem itemId) state CanToggleDoneItem = [ItemReopened itemId]

public export
implementation StateView TodoEvent TodoListView where
  initialView = MkTodoListView False "" [] 0 0
  projectEvent _ (ListCreated createdTitle) = MkTodoListView True createdTitle [] 0 0
  projectEvent view (ItemAdded newItemId newText) =
    let nextItems = items view ++ [MkTodoItem newItemId newText ItemOpen]
     in MkTodoListView True (title view) nextItems (S (openCount view)) (doneCount view)
  projectEvent view (ItemCompleted targetItemId) =
    let nextItems = setStatus targetItemId ItemDone (items view)
     in MkTodoListView True (title view) nextItems (decNat (openCount view)) (S (doneCount view))
  projectEvent view (ItemReopened targetItemId) =
    let nextItems = setStatus targetItemId ItemOpen (items view)
     in MkTodoListView True (title view) nextItems (S (openCount view)) (decNat (doneCount view))

public export
summaryFromEvents : String -> Nat -> List TodoEvent -> TodoListSummary
summaryFromEvents listId streamVersion events = summaryFromView listId streamVersion (projectFromList events)

public export
detailFromEvents : String -> Nat -> List TodoEvent -> TodoListDetail
detailFromEvents listId version events = detailFromView listId version (projectFromList events)

public export
implementation ScreenCatalog Screen AppBundle where
  specFor ListsOverview = MkScreenSpec ListsOverview HybridProjection (\_ => True)
  specFor ListDetailScreen = MkScreenSpec ListDetailScreen HybridProjection (\bundle => case selectedDetail bundle of
    Nothing => False
    Just _ => True)

public export
implementation ScreenActions Screen AppBundle Action Intent where
  screenForAction CreateListAction = ListsOverview
  screenForAction (OpenListAction _) = ListsOverview
  screenForAction BackToListsAction = ListDetailScreen
  screenForAction AddItemAction = ListDetailScreen
  screenForAction (ToggleItemAction _) = ListDetailScreen

  intentForAction CreateListAction = PromptCreateList
  intentForAction (OpenListAction listId) = ShowListDetail listId
  intentForAction BackToListsAction = ShowOverview
  intentForAction AddItemAction = PromptAddItem
  intentForAction (ToggleItemAction itemId) = RunToggleItem itemId

  availableScreenActions bundle ListsOverview =
    CreateListAction :: map (OpenListAction . listId) (filter exists (summaries bundle))
  availableScreenActions bundle ListDetailScreen =
    case selectedDetail bundle of
      Nothing => []
      Just detail =>
        BackToListsAction :: AddItemAction :: map (ToggleItemAction . itemId) (items detail)
