module EmKit.Modeling.Screen.Actions

%default total

public export
interface ScreenActions (screen, bundle, action, intent : Type) | action where
  screenForAction : action -> screen
  intentForAction : action -> intent
  availableScreenActions : bundle -> screen -> List action
