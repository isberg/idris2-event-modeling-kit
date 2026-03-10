module EmKit.Frontend.Stream

import EmKit.Frontend.SSE
import Web.MVC

%default total

public export
subscribeStream : (stream -> String -> String) -> stream -> String -> (String -> msg) -> Cmd msg
subscribeStream eventsUrl streamId clientId tag =
  subscribe (eventsUrl streamId clientId) tag

public export
subscribeMany :
  (stream -> String -> String) ->
  List stream ->
  String ->
  (stream -> String -> msg) ->
  Cmd msg
subscribeMany eventsUrl streamIds clientId tag =
  batch (map (\streamId => subscribeStream eventsUrl streamId clientId (tag streamId)) streamIds)
