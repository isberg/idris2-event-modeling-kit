module Domain.JSON.Simple

import Domain
import JSON.Simple.Derive

%default total
%language ElabReflection

%runElab derive "Domain.Command" [ToJSON, FromJSON]
%runElab derive "Domain.DoorEvent" [ToJSON, FromJSON]
