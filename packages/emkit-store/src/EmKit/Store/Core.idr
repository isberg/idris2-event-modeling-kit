module EmKit.Store.Core

%default total

public export
data LoadErr = NoStream | Corrupt | IOLoadError

public export
data AppendErr = Conflict | IOAppendError

public export
data ListStreamsErr = IOListStreamsError

public export
interface EventStore (m : Type -> Type) (stream : Type) (ev : Type) where
  load : stream -> m (Either LoadErr (Nat, List ev))
  loadFrom : stream -> (from : Nat) -> m (Either LoadErr (Nat, List ev))
  append : stream -> (expected : Nat) -> List ev -> m (Either AppendErr Nat)

public export
interface StreamCatalog (m : Type -> Type) (stream : Type) where
  listStreams : m (Either ListStreamsErr (List stream))

public export
interface Observable (m : Type -> Type) (stream : Type) (ev : Type) where
  subscribe : stream -> (Nat -> List ev -> m ()) -> m (m ())

public export
interface ObservableCategory (m : Type -> Type) (stream : Type) (ev : Type) where
  subscribeCategory : (stream -> Bool) -> (stream -> Nat -> List ev -> m ()) -> m (m ())
