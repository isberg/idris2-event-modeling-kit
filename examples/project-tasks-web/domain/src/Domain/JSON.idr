module Domain.JSON

import Derive.FromJSON
import Derive.Prelude
import Derive.ToJSON
import Domain.Event
import Domain.Project
import Domain.Task
import JSON

%default total
%language ElabReflection

%runElab derive "Domain.Event.ProjectEvent" [ToJSON, FromJSON]
%runElab derive "Domain.Event.TaskStatus" [ToJSON, FromJSON]
%runElab derive "Domain.Event.TaskEvent" [ToJSON, FromJSON]
%runElab derive "Domain.Event.DomainEvent" [ToJSON, FromJSON]
%runElab derive "Domain.Project.ProjectCommand" [ToJSON, FromJSON]
%runElab derive "Domain.Task.TaskCommand" [ToJSON, FromJSON]
%runElab derive "Domain.Project.ProjectSummary" [ToJSON, FromJSON]
%runElab derive "Domain.Project.ProjectDetail" [ToJSON, FromJSON]
%runElab derive "Domain.Task.TaskSummary" [ToJSON, FromJSON]
%runElab derive "Domain.Task.TaskDetail" [ToJSON, FromJSON]
