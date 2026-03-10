module Domain.Project

import Data.String
import Domain.Event
import EmKit.Modeling.Pattern.StateView
import EmKit.Sourcing.Decider
import EmKit.Stream.Version

%default total

public export
data ProjectCommand = CreateProject String

public export
data ProjectRejection
  = ProjectAlreadyCreated
  | EmptyProjectTitle

public export
record ProjectState where
  constructor MkProjectState
  exists : Bool
  title : String

public export
record ProjectView where
  constructor MkProjectView
  exists : Bool
  title : String

public export
record ProjectSummary where
  constructor MkProjectSummary
  projectId : String
  version : Nat
  exists : Bool
  title : String

public export
record ProjectDetail where
  constructor MkProjectDetail
  projectId : String
  version : Nat
  exists : Bool
  title : String

public export
renderProjectRejection : ProjectRejection -> String
renderProjectRejection ProjectAlreadyCreated = "project already exists."
renderProjectRejection EmptyProjectTitle = "project title is required."

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
summaryFromView : String -> Nat -> ProjectView -> ProjectSummary
summaryFromView projectId streamVersion view =
  MkProjectSummary projectId streamVersion (exists view) (title view)

public export
detailFromView : String -> Nat -> ProjectView -> ProjectDetail
detailFromView projectId streamVersion view =
  MkProjectDetail projectId streamVersion (exists view) (title view)

public export
summaryFromDetail : ProjectDetail -> ProjectSummary
summaryFromDetail detail =
  MkProjectSummary (projectId detail) (version detail) (exists detail) (title detail)

public export
emptyProjectSummary : String -> ProjectSummary
emptyProjectSummary projectId = MkProjectSummary projectId 0 False ""

applyProjectSummaryStep : String -> ProjectEvent -> Nat -> ProjectSummary -> ProjectSummary
applyProjectSummaryStep projectId (ProjectCreated projectTitle) nextVersion current =
  MkProjectSummary projectId nextVersion True projectTitle

public export
applyProjectSummaryEvent : String -> Nat -> DomainEvent -> ProjectSummary -> Either String ProjectSummary
applyProjectSummaryEvent projectId streamVersion (ProjectEventRaised event) summary =
  case applyVersionedUpdate projectId (version summary) streamVersion (applyProjectSummaryStep projectId event) summary of
    Left (VersionGap _ expected incoming) =>
      Left ("Project overview gap for " ++ projectId ++ ": expected v" ++ show expected ++ ", got v" ++ show incoming ++ ".")
    Right (IgnoredStale current) => Right current
    Right (Applied next) => Right next
applyProjectSummaryEvent projectId streamVersion (TaskEventRaised _) summary =
  Left ("Unexpected task event on project stream: " ++ projectId ++ ".")

applyProjectDetailStep : String -> ProjectEvent -> Nat -> ProjectDetail -> ProjectDetail
applyProjectDetailStep projectId (ProjectCreated projectTitle) nextVersion current =
  MkProjectDetail projectId nextVersion True projectTitle

public export
applyProjectDetailEvent : Nat -> DomainEvent -> ProjectDetail -> Either String ProjectDetail
applyProjectDetailEvent streamVersion (ProjectEventRaised event) detail =
  let pid = projectId detail in
  case applyVersionedUpdate pid (version detail) streamVersion (applyProjectDetailStep pid event) detail of
    Left (VersionGap _ expected incoming) =>
      Left ("Project detail gap for " ++ pid ++ ": expected v" ++ show expected ++ ", got v" ++ show incoming ++ ".")
    Right (IgnoredStale current) => Right current
    Right (Applied next) => Right next
applyProjectDetailEvent streamVersion (TaskEventRaised _) detail =
  Left ("Unexpected task event on project stream: " ++ projectId detail ++ ".")

data ProjectLegal : ProjectCommand -> ProjectState -> Type where
  CanCreateProject :
    {rawTitle : String} ->
    (cleanTitle : String) ->
    ProjectLegal (CreateProject rawTitle) state

createLegal : (rawTitle : String) -> ProjectState -> Either ProjectRejection (ProjectLegal (CreateProject rawTitle) state)
createLegal rawTitle (MkProjectState False currentTitle) =
  let cleanTitle = trim rawTitle in
    if cleanTitle == ""
      then Left EmptyProjectTitle
      else Right (CanCreateProject cleanTitle)
createLegal _ (MkProjectState True _) = Left ProjectAlreadyCreated

public export
implementation Projection DomainEvent ProjectState where
  initial = MkProjectState False ""
  evolve state (ProjectEventRaised (ProjectCreated projectTitle)) = MkProjectState True projectTitle
  evolve state (TaskEventRaised _) = state

public export
implementation Decider List ProjectCommand ProjectRejection DomainEvent ProjectState where
  Legal = ProjectLegal

  legal (CreateProject rawTitle) state = createLegal rawTitle state

  decide (CreateProject rawTitle) state (CanCreateProject cleanTitle) =
    [ProjectEventRaised (ProjectCreated cleanTitle)]

public export
implementation StateView DomainEvent ProjectView where
  initialView = MkProjectView False ""
  projectEvent _ (ProjectEventRaised (ProjectCreated projectTitle)) = MkProjectView True projectTitle
  projectEvent view (TaskEventRaised _) = view

public export
summaryFromEvents : String -> Nat -> List DomainEvent -> ProjectSummary
summaryFromEvents projectId streamVersion events = summaryFromView projectId streamVersion (projectFromList events)

public export
detailFromEvents : String -> Nat -> List DomainEvent -> ProjectDetail
detailFromEvents projectId streamVersion events = detailFromView projectId streamVersion (projectFromList events)
