module Domain.JSON

import Derive.FromJSON
import Derive.ToJSON
import Derive.Prelude
import Domain
import JSON

%default total
%language ElabReflection

%runElab derive "Domain.ItemStatus" [ToJSON, FromJSON]
%runElab derive "Domain.TodoItem" [ToJSON, FromJSON]
%runElab derive "Domain.Command" [ToJSON, FromJSON]
%runElab derive "Domain.TodoEvent" [ToJSON, FromJSON]
