module EmKit.Modeling.Pattern.Automation

import Data.List

%default total

public export
record AutomationStep view event command where
  constructor MkAutomationStep
  evolveView : view -> event -> view
  decideCommands : view -> event -> List command

public export
runAutomationEvent :
  AutomationStep view event command ->
  view ->
  event ->
  (view, List command)
runAutomationEvent step view event =
  let nextView = evolveView step view event in
  (nextView, decideCommands step nextView event)

public export
runAutomationEvents :
  AutomationStep view event command ->
  view ->
  List event ->
  (view, List command)
runAutomationEvents _ view [] = (view, [])
runAutomationEvents step view (event :: rest) =
  let (viewAfterEvent, commandsFromEvent) = runAutomationEvent step view event
      (finalView, commandsFromRest) = runAutomationEvents step viewAfterEvent rest in
  (finalView, commandsFromEvent ++ commandsFromRest)
