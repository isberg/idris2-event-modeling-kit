module WebApiTypes

import Domain
import JSON.Simple
import JSON.Simple.Derive

%language ElabReflection
%default total

public export
record EventHistoryDto where
  constructor MkEventHistoryDto
  streamVersion : Nat
  eventType : String
  detail : Maybe String

%runElab derive "EventHistoryDto" [ToJSON, FromJSON]

public export
record CounterSnapshotDto where
  constructor MkCounterSnapshotDto
  version : Nat
  view : CounterView
  history : List EventHistoryDto

%runElab derive "CounterSnapshotDto" [ToJSON, FromJSON]

public export
record CounterLiveEventDto where
  constructor MkCounterLiveEventDto
  streamVersion : Nat
  eventType : String
  detail : Maybe String

%runElab derive "CounterLiveEventDto" [ToJSON, FromJSON]

public export
record CreatePayload where
  constructor MkCreatePayload
  name : String

%runElab derive "CreatePayload" [ToJSON, FromJSON]

public export
record CommandResponseDto where
  constructor MkCommandResponseDto
  ok : Bool
  message : String
  version : Maybe Nat

%runElab derive "CommandResponseDto" [ToJSON, FromJSON]

public export
eventTypeText : CounterEvent -> String
eventTypeText (Created _) = "Created"
eventTypeText Incremented = "Incremented"
eventTypeText Decremented = "Decremented"

public export
eventDetailText : CounterEvent -> Maybe String
eventDetailText (Created title) = Just title
eventDetailText _ = Nothing

public export
toHistoryRow : Nat -> CounterEvent -> EventHistoryDto
toHistoryRow version event = MkEventHistoryDto version (eventTypeText event) (eventDetailText event)

historyRowsFrom : List CounterEvent -> List EventHistoryDto
historyRowsFrom = go Z
  where
    go : Nat -> List CounterEvent -> List EventHistoryDto
    go _ [] = []
    go version (event :: rest) =
      let next = S version in
        toHistoryRow next event :: go next rest

public export
toLiveEvent : Nat -> CounterEvent -> CounterLiveEventDto
toLiveEvent version event = MkCounterLiveEventDto version (eventTypeText event) (eventDetailText event)

public export
toSnapshot : Nat -> CounterView -> List CounterEvent -> CounterSnapshotDto
toSnapshot version view history = MkCounterSnapshotDto version view (historyRowsFrom history)

public export
decodeLiveEvent : CounterLiveEventDto -> Either String CounterEvent
decodeLiveEvent dto =
  case eventType dto of
    "Created" =>
      case detail dto of
        Just title => Right (Created title)
        Nothing => Left "Created event missing detail."
    "Incremented" => Right Incremented
    "Decremented" => Right Decremented
    other => Left ("Unknown live event type: " ++ other)
