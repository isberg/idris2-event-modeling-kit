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

public export
closeStream : (stream -> String -> String) -> stream -> String -> Cmd msg
closeStream eventsUrl streamId clientId =
  close (eventsUrl streamId clientId)

public export
closeCurrent :
  Maybe stream ->
  Maybe String ->
  (stream -> String -> Cmd msg) ->
  List (Cmd msg)
closeCurrent maybeStream maybeClientId closeCmd =
  case (maybeStream, maybeClientId) of
    (Just streamId, Just clientId) => [closeCmd streamId clientId]
    _ => []

public export
withClientId :
  Maybe String ->
  Cmd msg ->
  (String -> List (Cmd msg)) ->
  List (Cmd msg)
withClientId maybeClientId requestClientId whenReady =
  case maybeClientId of
    Nothing => [requestClientId]
    Just clientId => whenReady clientId
