module EmKit.Modeling.Traceability.Slice

%default total

public export
record CommandLink action command where
  constructor MkCommandLink
  fromAction : action
  toCommand : command

public export
record EventLink command event where
  constructor MkEventLink
  fromCommand : command
  toEvent : event

public export
record ViewLink event view where
  constructor MkViewLink
  fromEvent : event
  toView : view

public export
record SliceTrace action command event view where
  constructor MkSliceTrace
  commandLinks : List (CommandLink action command)
  eventLinks : List (EventLink command event)
  viewLinks : List (ViewLink event view)

public export
commandsForAction :
  Eq action =>
  SliceTrace action command event view ->
  action ->
  List command
commandsForAction trace action =
  map toCommand $ filter (\link => fromAction link == action) (commandLinks trace)

public export
eventsForCommand :
  Eq command =>
  SliceTrace action command event view ->
  command ->
  List event
eventsForCommand trace command =
  map toEvent $ filter (\link => fromCommand link == command) (eventLinks trace)

public export
viewsForEvent :
  Eq event =>
  SliceTrace action command event view ->
  event ->
  List view
viewsForEvent trace event =
  map toView $ filter (\link => fromEvent link == event) (viewLinks trace)

public export
hasCommandLink :
  (Eq action, Eq command) =>
  SliceTrace action command event view ->
  action ->
  command ->
  Bool
hasCommandLink trace action command =
  elem command (commandsForAction trace action)

public export
hasEventLink :
  (Eq command, Eq event) =>
  SliceTrace action command event view ->
  command ->
  event ->
  Bool
hasEventLink trace command event =
  elem event (eventsForCommand trace command)

public export
hasViewLink :
  (Eq event, Eq view) =>
  SliceTrace action command event view ->
  event ->
  view ->
  Bool
hasViewLink trace event view =
  elem view (viewsForEvent trace event)
