module Domain.JSON.Simple

import Domain.Event
import Domain.Project
import Domain.Task
import Domain.Translation
import JSON.Simple.Derive

%default total
%language ElabReflection

%runElab derive "Domain.Event.ProjectEvent" [ToJSON, FromJSON]
%runElab derive "Domain.Event.TaskStatus" [ToJSON, FromJSON]
%runElab derive "Domain.Event.TaskEvent" [ToJSON, FromJSON]
%runElab derive "Domain.Event.StoredEvent" [ToJSON, FromJSON]
%runElab derive "Domain.Project.ProjectCommand" [ToJSON, FromJSON]
%runElab derive "Domain.Task.TaskCommand" [ToJSON, FromJSON]
%runElab derive "Domain.Project.ProjectSummary" [ToJSON, FromJSON]
%runElab derive "Domain.Project.ProjectDetail" [ToJSON, FromJSON]
%runElab derive "Domain.Task.TaskSummary" [ToJSON, FromJSON]
%runElab derive "Domain.Task.TaskDetail" [ToJSON, FromJSON]
%runElab derive "Domain.Translation.TaskIntakeSignal" [ToJSON, FromJSON]
%runElab derive "Domain.Translation.TaskIntakeAccepted" [ToJSON, FromJSON]
