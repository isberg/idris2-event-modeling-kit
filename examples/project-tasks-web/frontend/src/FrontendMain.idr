module FrontendMain

import Frontend.State
import Frontend.Update
import JS.Util
import Web.MVC

%default total

onError : JS.Util.JSErr -> IO ()
onError = putStrLn . dispErr

covering
main : IO ()
main = runController {e=Msg, s=State} controller onError Initialized initialState
