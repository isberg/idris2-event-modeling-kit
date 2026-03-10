module EmKit.Frontend.Execute

import EmKit.Wire.Contracts
import EmKit.Wire.JSON.Simple
import JSON.Simple
import Web.MVC
import Web.MVC.Http

%default total

public export
postExecute :
  {auto _ : ToJSON commandT} ->
  (executeUrl : stream -> String) ->
  (tag : stream -> Either HTTPError () -> msg) ->
  stream ->
  Nat ->
  commandT ->
  Cmd msg
postExecute executeUrl tag streamId expectedVersion commandValue =
  post (executeUrl streamId)
    (JSONBody (MkExecutePayload expectedVersion commandValue))
    (ExpectAny (tag streamId))

public export
postExecuteSingle :
  {auto _ : ToJSON commandT} ->
  (executeUrl : stream -> String) ->
  (tag : Either HTTPError () -> msg) ->
  stream ->
  Nat ->
  commandT ->
  Cmd msg
postExecuteSingle executeUrl tag streamId expectedVersion commandValue =
  post (executeUrl streamId)
    (JSONBody (MkExecutePayload expectedVersion commandValue))
    (ExpectAny tag)

public export
getResync :
  {auto _ : FromJSON (ResyncPayload ev)} ->
  (resyncUrl : stream -> String) ->
  (tag : stream -> Either HTTPError (ResyncPayload ev) -> msg) ->
  stream ->
  Cmd msg
getResync resyncUrl tag streamId =
  get (resyncUrl streamId) (ExpectJSON (tag streamId))
