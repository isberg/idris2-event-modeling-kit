module EmKit.Stream.SSE

%default total

public export
sseHeaders : List (String, String)
sseHeaders =
  [ ("content-type", "text/event-stream")
  , ("cache-control", "no-cache")
  , ("connection", "keep-alive")
  ]

public export
sseFrameText : Maybe String -> Maybe String -> String -> String
sseFrameText maybeId maybeEvent payload =
  let idLine =
        case maybeId of
          Nothing => ""
          Just value => "id: " ++ value ++ "\n"
      eventLine =
        case maybeEvent of
          Nothing => ""
          Just value => "event: " ++ value ++ "\n"
  in idLine ++ eventLine ++ "data: " ++ payload ++ "\n\n"

public export
sseCommentText : String -> String
sseCommentText comment = ": " ++ comment ++ "\n\n"

public export
sseConnectedCommentText : String
sseConnectedCommentText = sseCommentText "connected"
