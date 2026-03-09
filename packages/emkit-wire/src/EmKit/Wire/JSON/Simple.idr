module EmKit.Wire.JSON.Simple

import EmKit.Wire.Contracts
import JSON.Simple.Derive

%default total
%language ElabReflection

%runElab derive "EmKit.Wire.Contracts.ExecutePayload" [ToJSON, FromJSON]
%runElab derive "EmKit.Wire.Contracts.StreamEvent" [ToJSON, FromJSON]
%runElab derive "EmKit.Wire.Contracts.MultiplexedStreamEvent" [ToJSON, FromJSON]
%runElab derive "EmKit.Wire.Contracts.ResyncPayload" [ToJSON, FromJSON]
