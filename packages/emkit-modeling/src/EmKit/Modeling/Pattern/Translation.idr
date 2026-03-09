module EmKit.Modeling.Pattern.Translation

%default total

public export
interface Translation (signal, command, rejection : Type) where
  translate : signal -> Either rejection command

public export
translateMany :
  {signal, command, rejection : Type} ->
  Translation signal command rejection =>
  List signal ->
  List (Either rejection command)
translateMany = map translate
