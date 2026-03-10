module Domain.JSON.Simple

import Domain
import JSON.Simple.Derive

%default total
%language ElabReflection

%runElab derive "Domain.ItemStatus" [ToJSON, FromJSON]
%runElab derive "Domain.TodoItem" [ToJSON, FromJSON]
%runElab derive "Domain.Command" [ToJSON, FromJSON]
%runElab derive "Domain.TodoEvent" [ToJSON, FromJSON]
%runElab derive "Domain.TodoListSummary" [ToJSON, FromJSON]
%runElab derive "Domain.TodoListDetail" [ToJSON, FromJSON]
