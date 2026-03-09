module EmKit.Stream.Version

%default total

public export
data StreamVersionAdvanceError stream
  = VersionGap stream Nat Nat

public export
data StreamVersionAdvance stream
  = DuplicateOrOld
  | Advanced (List (stream, Nat))

public export
streamKnownVersion : Eq stream => stream -> List (stream, Nat) -> Nat
streamKnownVersion _ [] = 0
streamKnownVersion streamId ((existing, known) :: rest) =
  if existing == streamId then known else streamKnownVersion streamId rest

public export
upsertStreamVersion : Eq stream => stream -> Nat -> List (stream, Nat) -> List (stream, Nat)
upsertStreamVersion streamId incoming [] = [(streamId, incoming)]
upsertStreamVersion streamId incoming ((existing, known) :: rest) =
  if existing == streamId
    then (streamId, incoming) :: rest
    else (existing, known) :: upsertStreamVersion streamId incoming rest

public export
advanceStreamVersion :
  Eq stream =>
  stream ->
  Nat ->
  List (stream, Nat) ->
  Either (StreamVersionAdvanceError stream) (StreamVersionAdvance stream)
advanceStreamVersion streamId incoming knownVersions =
  let known = streamKnownVersion streamId knownVersions in
  if incoming <= known then
    Right DuplicateOrOld
  else
    let expected = S known in
    if incoming == expected then
      Right (Advanced (upsertStreamVersion streamId incoming knownVersions))
    else
      Left (VersionGap streamId expected incoming)

public export
formatAdvanceError : (stream -> String) -> StreamVersionAdvanceError stream -> String
formatAdvanceError renderStream (VersionGap streamId expected incoming) =
  "Live stream version gap on " ++ renderStream streamId ++ ": expected v" ++ show expected ++ ", got v" ++ show incoming ++ "."
