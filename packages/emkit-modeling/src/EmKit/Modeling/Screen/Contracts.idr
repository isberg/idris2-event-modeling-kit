module EmKit.Modeling.Screen.Contracts

%default total

public export
data DataSourcePolicy
  = QueryOnly
  | ClientProjectionOnly
  | HybridProjection

public export
record ScreenSpec screen bundle where
  constructor MkScreenSpec
  screenId : screen
  dataSourcePolicy : DataSourcePolicy
  visible : bundle -> Bool

public export
interface ScreenCatalog screen bundle where
  specFor : screen -> ScreenSpec screen bundle

public export
isVisible :
  ScreenCatalog screen bundle =>
  screen ->
  bundle ->
  Bool
isVisible screen bundle = visible (specFor screen) bundle
