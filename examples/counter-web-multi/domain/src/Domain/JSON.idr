module Domain.JSON

import Derive.FromJSON
import Derive.Prelude
import Derive.ToJSON
import Domain
import JSON

%default total
%language ElabReflection

%runElab derive "Domain.Command" [ToJSON, FromJSON]
%runElab derive "Domain.CounterEvent" [ToJSON, FromJSON]
