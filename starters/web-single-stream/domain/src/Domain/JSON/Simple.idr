module Domain.JSON.Simple

import Domain
import JSON.Simple.Derive

%default total
%language ElabReflection

%runElab derive "Domain.Command" [ToJSON, FromJSON]
%runElab derive "Domain.CounterEvent" [ToJSON, FromJSON]
%runElab derive "Domain.CounterModel" [ToJSON, FromJSON]
%runElab derive "Domain.CounterDetail" [ToJSON, FromJSON]
