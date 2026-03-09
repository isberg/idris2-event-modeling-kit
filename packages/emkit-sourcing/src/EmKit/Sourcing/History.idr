module EmKit.Sourcing.History

import Data.List

%default total

public export
interface History (h : Type -> Type) where
  empty : h e
  append : h e -> h e -> h e
  replay : (s -> e -> s) -> s -> h e -> s

  appendAssoc : (a, b, c : h e) -> a `append` (b `append` c) = (a `append` b) `append` c
  appendLeftId : {right : h e} -> empty `append` right = right
  appendRightId : (left : h e) -> left `append` empty = left
  replayEmpty : {start : s} -> {step : s -> e -> s} -> replay step start empty = start
  replayAppend :
    {start : s} ->
    {step : s -> e -> s} ->
    (x, y : h e) ->
    replay step start (append x y) = replay step (replay step start x) y

public export
implementation {h : Type -> Type} -> History h => Semigroup (h e) where
  (<+>) = append

public export
implementation {h : Type -> Type} -> History h => Monoid (h e) where
  neutral = empty

foldlAppend :
  (step : s -> e -> s) ->
  (start : s) ->
  (xs : List e) ->
  (ys : List e) ->
  foldl step (foldl step start xs) ys = foldl step start (xs ++ ys)
foldlAppend step start [] ys = Refl
foldlAppend {s} {e} step start (x :: xs) ys =
  rewrite (foldlAppend {s} {e} step (step start x) xs ys) in Refl

public export
implementation History List where
  empty = []
  append = (++)
  replay = foldl

  appendAssoc = appendAssociative
  appendLeftId = Refl
  appendRightId = appendNilRightNeutral
  replayEmpty = Refl
  replayAppend {start} {step} x y = sym (foldlAppend step start x y)
