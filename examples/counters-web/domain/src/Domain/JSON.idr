module Domain.JSON

import Domain
import JSON.Derive

%default total
%language ElabReflection

%runElab derive "Domain.Command" [ToJSON, FromJSON]
%runElab derive "Domain.CounterEvent" [ToJSON, FromJSON]
%runElab derive "Domain.CounterSummary" [ToJSON, FromJSON]
%runElab derive "Domain.CounterDetail" [ToJSON, FromJSON]
