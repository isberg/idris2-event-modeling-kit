module Domain.Project

import Data.String
import Domain.Event
import EmKit.Sourcing.Projection
import EmKit.Sourcing.Decider
import EmKit.Stream.Version

%default total

public export
data ProjectCommand
  = CreateProject String
  | CompleteProject

public export
data ProjectRejection
  = ProjectAlreadyCreated
  | EmptyProjectTitle
  | ProjectMissing
  | ProjectAlreadyCompleted

public export
record ProjectModel where
  constructor MkProjectModel
  exists : Bool
  title : String
  completed : Bool

public export
record ProjectSummary where
  constructor MkProjectSummary
  projectId : String
  version : Nat
  exists : Bool
  title : String
  completed : Bool

public export
record ProjectDetail where
  constructor MkProjectDetail
  projectId : String
  version : Nat
  exists : Bool
  title : String
  completed : Bool

public export
renderProjectRejection : ProjectRejection -> String
renderProjectRejection ProjectAlreadyCreated = "project already exists."
renderProjectRejection EmptyProjectTitle = "project title is required."
renderProjectRejection ProjectMissing = "project does not exist yet."
renderProjectRejection ProjectAlreadyCompleted = "project is already completed."

dropPrefixChars : List Char -> List Char -> Maybe (List Char)
dropPrefixChars [] xs = Just xs
dropPrefixChars (_ :: _) [] = Nothing
dropPrefixChars (p :: ps) (x :: xs) =
  if p == x then dropPrefixChars ps xs else Nothing

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
nextProjectIdFromSummaries : List ProjectSummary -> String
nextProjectIdFromSummaries summaries =
  let ids = map projectId summaries
      next = S (maxSuffixFor projectPrefix ids)
  in projectPrefix ++ show next

public export
summaryFromModel : String -> Nat -> ProjectModel -> ProjectSummary
summaryFromModel projectId streamVersion model =
  MkProjectSummary projectId streamVersion (exists model) (title model) (completed model)

public export
detailFromModel : String -> Nat -> ProjectModel -> ProjectDetail
detailFromModel projectId streamVersion model =
  MkProjectDetail projectId streamVersion (exists model) (title model) (completed model)

public export
summaryFromDetail : ProjectDetail -> ProjectSummary
summaryFromDetail detail =
  MkProjectSummary (projectId detail) (version detail) (exists detail) (title detail) (completed detail)

public export
emptyProjectSummary : String -> ProjectSummary
emptyProjectSummary projectId = MkProjectSummary projectId 0 False "" False

applyProjectSummaryStep : String -> ProjectEvent -> Nat -> ProjectSummary -> ProjectSummary
applyProjectSummaryStep projectId (ProjectCreated projectTitle) nextVersion current =
  MkProjectSummary projectId nextVersion True projectTitle False
applyProjectSummaryStep projectId ProjectCompleted nextVersion current =
  { version := nextVersion, completed := True } current

public export
applyProjectSummaryEvent : String -> Nat -> ProjectEvent -> ProjectSummary -> Either String ProjectSummary
applyProjectSummaryEvent projectId streamVersion event summary =
  case applyVersionedUpdate projectId (version summary) streamVersion (applyProjectSummaryStep projectId event) summary of
    Left (VersionGap _ expected incoming) =>
      Left ("Project overview gap for " ++ projectId ++ ": expected v" ++ show expected ++ ", got v" ++ show incoming ++ ".")
    Right (IgnoredStale current) => Right current
    Right (Applied next) => Right next

applyProjectDetailStep : String -> ProjectEvent -> Nat -> ProjectDetail -> ProjectDetail
applyProjectDetailStep projectId (ProjectCreated projectTitle) nextVersion current =
  MkProjectDetail projectId nextVersion True projectTitle False
applyProjectDetailStep projectId ProjectCompleted nextVersion current =
  { version := nextVersion, completed := True } current

public export
applyProjectDetailEvent : Nat -> ProjectEvent -> ProjectDetail -> Either String ProjectDetail
applyProjectDetailEvent streamVersion event detail =
  let pid = projectId detail in
  case applyVersionedUpdate pid (version detail) streamVersion (applyProjectDetailStep pid event) detail of
    Left (VersionGap _ expected incoming) =>
      Left ("Project detail gap for " ++ pid ++ ": expected v" ++ show expected ++ ", got v" ++ show incoming ++ ".")
    Right (IgnoredStale current) => Right current
    Right (Applied next) => Right next

data ProjectLegal : ProjectCommand -> ProjectModel -> Type where
  CanCreateProject :
    {rawTitle : String} ->
    (cleanTitle : String) ->
    ProjectLegal (CreateProject rawTitle) state
  CanCompleteProject : ProjectLegal CompleteProject state

createLegal : (rawTitle : String) -> ProjectModel -> Either ProjectRejection (ProjectLegal (CreateProject rawTitle) state)
createLegal rawTitle (MkProjectModel False _ _) =
  let cleanTitle = trim rawTitle in
    if cleanTitle == ""
      then Left EmptyProjectTitle
      else Right (CanCreateProject cleanTitle)
createLegal _ (MkProjectModel True _ _) = Left ProjectAlreadyCreated

completeLegal : ProjectModel -> Either ProjectRejection (ProjectLegal CompleteProject state)
completeLegal (MkProjectModel False _ _) = Left ProjectMissing
completeLegal (MkProjectModel True _ True) = Left ProjectAlreadyCompleted
completeLegal (MkProjectModel True _ False) = Right CanCompleteProject

public export
implementation Projection ProjectEvent ProjectModel where
  initial = MkProjectModel False "" False
  evolve _ (ProjectCreated projectTitle) = MkProjectModel True projectTitle False
  evolve model ProjectCompleted = { completed := True } model

public export
implementation Decider List ProjectCommand ProjectRejection ProjectEvent ProjectModel where
  Legal = ProjectLegal

  legal (CreateProject rawTitle) state = createLegal rawTitle state
  legal CompleteProject state = completeLegal state

  decide (CreateProject rawTitle) state (CanCreateProject cleanTitle) =
    [ProjectCreated cleanTitle]
  decide CompleteProject state CanCompleteProject = [ProjectCompleted]

public export
summaryFromEvents : String -> Nat -> List ProjectEvent -> ProjectSummary
summaryFromEvents projectId streamVersion events = summaryFromModel projectId streamVersion (project events)

public export
detailFromEvents : String -> Nat -> List ProjectEvent -> ProjectDetail
detailFromEvents projectId streamVersion events = detailFromModel projectId streamVersion (project events)
