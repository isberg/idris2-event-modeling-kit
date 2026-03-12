module Domain

import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Sourcing.Decider
import EmKit.Sourcing.Projection

%default total

public export
data Command = Open | Close

public export
data Rejection = AlreadyOpen | AlreadyClosed

public export
data DoorEvent = DoorOpened | DoorClosed

public export
record DoorModel where
  constructor MkDoorModel
  isOpen : Bool

public export
data Screen = DoorScreen

public export
record Bundle where
  constructor MkBundle
  model : DoorModel

public export
data Action = OpenDoor | CloseDoor

public export
renderModel : DoorModel -> String
renderModel (MkDoorModel False) = "door{open=false}"
renderModel (MkDoorModel True) = "door{open=true}"

public export
renderRejection : Rejection -> String
renderRejection AlreadyOpen = "door is already open"
renderRejection AlreadyClosed = "door is already closed"

public export
renderEvent : DoorEvent -> String
renderEvent DoorOpened = "DoorOpened"
renderEvent DoorClosed = "DoorClosed"

public export
renderEvents : List DoorEvent -> String
renderEvents [] = "[]"
renderEvents [event] = "[" ++ renderEvent event ++ "]"
renderEvents (event :: rest) = "[" ++ renderEvent event ++ restText rest
  where
    restText : List DoorEvent -> String
    restText [] = "]"
    restText (next :: xs) = ", " ++ renderEvent next ++ restText xs

public export
renderAction : Action -> String
renderAction OpenDoor = "OpenDoor"
renderAction CloseDoor = "CloseDoor"

public export
renderActions : List Action -> String
renderActions [] = "[]"
renderActions [action] = "[" ++ renderAction action ++ "]"
renderActions (action :: rest) = "[" ++ renderAction action ++ restText rest
  where
    restText : List Action -> String
    restText [] = "]"
    restText (next :: xs) = ", " ++ renderAction next ++ restText xs

data DoorLegal : Command -> DoorModel -> Type where
  CanOpen : DoorLegal Open (MkDoorModel False)
  CanClose : DoorLegal Close (MkDoorModel True)

public export
implementation Projection DoorEvent DoorModel where
  initial = MkDoorModel False
  evolve _ DoorOpened = MkDoorModel True
  evolve _ DoorClosed = MkDoorModel False

public export
implementation Decider List Command Rejection DoorEvent DoorModel where
  Legal = DoorLegal

  legal Open (MkDoorModel False) = Right CanOpen
  legal Open (MkDoorModel True) = Left AlreadyOpen
  legal Close (MkDoorModel False) = Left AlreadyClosed
  legal Close (MkDoorModel True) = Right CanClose

  decide Open _ CanOpen = [DoorOpened]
  decide Close _ CanClose = [DoorClosed]

public export
implementation ScreenCatalog Screen Bundle where
  specFor DoorScreen = MkScreenSpec DoorScreen ClientProjectionOnly (const True)

public export
implementation ScreenActions Screen Bundle Action Command where
  screenForAction _ = DoorScreen
  intentForAction OpenDoor = Open
  intentForAction CloseDoor = Close
  availableScreenActions (MkBundle (MkDoorModel False)) DoorScreen = [OpenDoor]
  availableScreenActions (MkBundle (MkDoorModel True)) DoorScreen = [CloseDoor]
