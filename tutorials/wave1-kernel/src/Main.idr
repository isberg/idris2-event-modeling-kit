module Main

import Domain
import Domain.JSON.Simple
import EmKit.Modeling.Screen.Actions
import EmKit.Modeling.Screen.Contracts
import EmKit.Sourcing.Decider
import EmKit.Sourcing.Projection
import EmKit.Stream.SSE
import EmKit.Wire.Contracts
import EmKit.Wire.JSON.Simple
import JSON.Simple.ToJSON as SimpleToJSON

%default total

history : List DoorEvent
history = [DoorOpened]

currentModel : DoorModel
currentModel = project history

bundle : Bundle
bundle = MkBundle currentModel

main : IO ()
main = do
  putStrLn "Tutorial: wave1-kernel"
  putStrLn ("Model: " ++ renderModel currentModel)
  putStrLn ("Visible: " ++ show (isVisible DoorScreen bundle))
  putStrLn ("Actions: " ++ renderActions (availableScreenActions bundle DoorScreen))
  case update Close currentModel of
    Left rejection => putStrLn ("Decision: rejected -> " ++ renderRejection rejection)
    Right (nextModel, events) =>
      putStrLn ("Decision: accepted -> model=" ++ renderModel nextModel ++ "; events=" ++ renderEvents events)
  let executePayload : ExecutePayload Command
      executePayload = MkExecutePayload 1 Close
  putStrLn ("Execute JSON: " ++ SimpleToJSON.encode executePayload)
  let liveEvent : StreamEvent DoorEvent
      liveEvent = MkStreamEvent 2 DoorClosed
  let eventJson = SimpleToJSON.encode liveEvent
  putStrLn ("Stream JSON: " ++ eventJson)
  putStrLn "SSE frame:"
  putStr (sseFrameText (Just "2") (Just "door-event") eventJson)
