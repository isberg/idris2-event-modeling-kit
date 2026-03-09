module EmKit.Wire.JSON

import Derive.FromJSON
import Derive.ToJSON
import Derive.Prelude
import EmKit.Wire.Contracts
import JSON

%default total
%language ElabReflection

%runElab derive "EmKit.Wire.Contracts.ExecutePayload" [ToJSON, FromJSON]
%runElab derive "EmKit.Wire.Contracts.StreamEvent" [ToJSON, FromJSON]
%runElab derive "EmKit.Wire.Contracts.MultiplexedStreamEvent" [ToJSON, FromJSON]
%runElab derive "EmKit.Wire.Contracts.ResyncPayload" [ToJSON, FromJSON]
