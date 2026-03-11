module Frontend.View

import Data.List
import Domain.Event as Event
import Domain.Project as Project
import Domain.Screens as Screens
import Domain.Task as Task
import Frontend.State
import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import Text.HTML.Attribute as HtmlAttr
import Web.MVC

%default total

renderTaskEvent : Event.TaskEvent -> String
renderTaskEvent (Event.TaskCreated projectId title) = "Created for " ++ projectId ++ ": " ++ title
renderTaskEvent Event.TaskStarted = "Started"
renderTaskEvent Event.TaskCompleted = "Completed"

projectStatusLabel : Bool -> String
projectStatusLabel = Event.renderProjectStatus

messageForAction : Action -> Msg
messageForAction CreateProjectAction = CreateProjectClicked
messageForAction (OpenProjectAction projectId) = OpenProjectClicked projectId
messageForAction BackToProjectsAction = BackToProjectsClicked
messageForAction CreateTaskAction = CreateTaskClicked
messageForAction (OpenTaskAction taskId) = OpenTaskClicked taskId
messageForAction BackToProjectAction = BackToProjectClicked
messageForAction StartTaskAction = StartTaskClicked
messageForAction CompleteTaskAction = CompleteTaskClicked

actionButton : Bool -> Action -> Node Msg
actionButton isBusy action =
  button
    [ onClick (messageForAction action)
    , disabled isBusy
    , style "padding:9px 12px; border:1px solid #3b5d7e; border-radius:10px; background:#eef5fb;"
    ]
    [ Text (renderAction action) ]

screenPolicyText : Screen -> String
screenPolicyText currentScreen =
  case dataSourcePolicy (specFor {bundle=AppBundle} currentScreen) of
    QueryOnly => "QueryOnly"
    ClientProjectionOnly => "ClientProjectionOnly"
    HybridProjection => "HybridProjection"

projectCard : State -> Project.ProjectSummary -> Node Msg
projectCard s summary =
  div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:18px; padding:18px; min-width:220px; flex:1;" ]
    [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;" ] [ Text (projectId summary) ]
    , h3 [ style "margin:8px 0 8px 0; font-size:26px;" ] [ Text (title summary) ]
    , div [ style "font-size:13px; opacity:0.78; margin:8px 0 14px 0;" ] [ Text (projectStatusLabel (completed summary)) ]
    , actionButton (busy s) (OpenProjectAction (projectId summary))
    ]

projectsOverviewSection : State -> Node Msg
projectsOverviewSection s =
  let cards = map (projectCard s) (projectSummaryList s) in
  div []
    [ div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:16px; padding:16px; margin-bottom:18px;" ]
        [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px; margin-bottom:4px;" ] [ Text (screenPolicyText ProjectsOverview) ]
        , h2 [ style "margin:0 0 8px 0; font-size:28px;" ] [ Text "Projects" ]
        , div [ style "display:flex; gap:10px; flex-wrap:wrap;" ]
            [ input [ onInput CreateProjectTitleChanged, HtmlAttr.value (createProjectTitle s), placeholder "new project title", style "padding:10px; border:1px solid #98aaba; border-radius:10px; min-width:240px;" ] []
            , actionButton (busy s) CreateProjectAction
            ]
        ]
    , if null cards
        then div [ style "padding:18px; background:#ffffffd9; border:1px dashed #bcc9d5; border-radius:16px;" ] [ Text "No projects yet." ]
        else div [ style "display:flex; gap:14px; flex-wrap:wrap;" ] cards
    ]

taskRow : State -> Task.TaskSummary -> Node Msg
taskRow s summary =
  div [ style "display:flex; gap:10px; align-items:center; justify-content:space-between; padding:12px 0; border-top:1px solid #e1e8ef;" ]
    [ div []
        [ div [ style "font-weight:600;" ] [ Text (title summary) ]
        , div [ style "font-size:12px; opacity:0.7;" ] [ Text (taskId summary ++ " · " ++ renderTaskStatus (status summary)) ]
        ]
    , actionButton (busy s) (OpenTaskAction (taskId summary))
    ]

projectDetailSection : State -> Project.ProjectDetail -> Node Msg
projectDetailSection s detail =
  let tasks = projectTaskList s in
  div []
    [ div [ style "display:flex; justify-content:space-between; align-items:end; gap:14px; flex-wrap:wrap; margin-bottom:18px;" ]
        [ div []
            [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;" ] [ Text (screenPolicyText ProjectDetailScreen ++ " · " ++ projectId detail) ]
            , h2 [ style "margin:6px 0 0 0; font-size:30px;" ] [ Text (title detail) ]
            , div [ style "font-size:13px; opacity:0.78; margin-top:6px;" ] [ Text (projectStatusLabel (completed detail)) ]
            ]
        , actionButton (busy s) BackToProjectsAction
        ]
    , div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:16px; padding:16px; margin-bottom:18px;" ]
        [ h3 [ style "margin:0 0 8px 0;" ] [ Text "Add Task" ]
        , div [ style "display:flex; gap:10px; flex-wrap:wrap;" ]
            [ input [ onInput CreateTaskTitleChanged, HtmlAttr.value (createTaskTitle s), placeholder "new task title", style "padding:10px; border:1px solid #98aaba; border-radius:10px; min-width:260px;" ] []
            , actionButton (busy s) CreateTaskAction
            ]
        ]
    , div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:16px; padding:16px;" ]
        [ h3 [ style "margin:0 0 4px 0;" ] [ Text "Tasks" ]
        , div [ style "font-size:12px; opacity:0.7; margin-bottom:8px;" ] [ Text (show (length tasks) ++ " visible task streams") ]
        , if null tasks
            then div [ style "padding:10px 0; opacity:0.75;" ] [ Text "No tasks yet for this project." ]
            else div [] (map (taskRow s) tasks)
        ]
    ]

historyRow : Nat -> Event.TaskEvent -> Node Msg
historyRow version event =
  div [ style "display:flex; gap:12px; padding:8px 0; border-top:1px solid #e4e9ee;" ]
    [ div [ style "font-size:12px; opacity:0.65; min-width:44px;" ] [ Text ("v" ++ show version) ]
    , div [] [ Text (renderTaskEvent event) ]
    ]

taskDetailSection : State -> Task.TaskDetail -> Node Msg
taskDetailSection s detail =
  let actions =
        BackToProjectAction
          :: (if Task.canStart detail then [StartTaskAction] else [])
          ++ (if Task.canComplete detail then [CompleteTaskAction] else [])
      rows = zipWith historyRow [1 .. length (history detail)] (history detail)
      projectLine = case selectedProject s of
        Nothing => projectId detail
        Just projectDetail => projectId detail ++ " · project " ++ projectStatusLabel (completed projectDetail)
  in div []
      [ div [ style "display:flex; justify-content:space-between; align-items:end; gap:14px; flex-wrap:wrap; margin-bottom:18px;" ]
          [ div []
              [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;" ] [ Text (screenPolicyText TaskDetailScreen ++ " · " ++ taskId detail) ]
              , h2 [ style "margin:6px 0 0 0; font-size:30px;" ] [ Text (title detail) ]
              , div [ style "font-size:13px; opacity:0.78; margin-top:6px;" ] [ Text (projectLine ++ " · " ++ renderTaskStatus (status detail)) ]
              ]
          , div [ style "display:flex; gap:10px; flex-wrap:wrap;" ] (map (actionButton (busy s)) actions)
          ]
      , div [ style "background:#ffffffd9; border:1px solid #ced8e2; border-radius:16px; padding:16px;" ]
          [ h3 [ style "margin:0 0 8px 0;" ] [ Text "Task History" ]
          , if null rows
              then div [ style "padding:10px 0; opacity:0.75;" ] [ Text "No task events yet." ]
              else div [] rows
          ]
      ]

export
viewNodes : State -> List (Node Msg)
viewNodes s =
  [ div [ style "min-height:100vh; padding:24px; background:linear-gradient(180deg,#f6fbff 0%,#edf4f8 100%); color:#16324f; font-family:Georgia, serif;" ]
      [ div [ style "max-width:980px; margin:0 auto;" ]
          [ div [ style "display:flex; justify-content:space-between; align-items:end; gap:16px; flex-wrap:wrap; margin-bottom:18px;" ]
              [ div []
                  [ div [ style "font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;" ] [ Text "Project/Task Example" ]
                  , h1 [ style "margin:6px 0 0 0; font-size:38px;" ] [ Text "Project Tracker" ]
                  ]
              , div [ style "font-size:13px; opacity:0.78; max-width:420px; text-align:right;" ]
                  [ Text (statusText s) ]
              ]
          , case screen s of
              ProjectsOverview => projectsOverviewSection s
              ProjectDetailScreen => case selectedProject s of
                Nothing => div [ style "padding:18px; background:#ffffffd9; border:1px dashed #bcc9d5; border-radius:16px;" ] [ Text "Loading project..." ]
                Just detail => projectDetailSection s detail
              TaskDetailScreen => case selectedTask s of
                Nothing => div [ style "padding:18px; background:#ffffffd9; border:1px dashed #bcc9d5; border-radius:16px;" ] [ Text "Loading task..." ]
                Just detail => taskDetailSection s detail
          ]
      ]
  ]

export
updateView : State -> Cmd Msg
updateView s = children Ref.Body (viewNodes s)
