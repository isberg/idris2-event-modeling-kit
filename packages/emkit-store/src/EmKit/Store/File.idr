module EmKit.Store.File

import Control.Monad.Reader
import Control.Monad.Trans
import Data.IORef as IORef
import Data.List
import Data.SortedMap
import Data.String
import EmKit.Store.Core
import JSON.Simple
import JSON.Simple.ToJSON as SimpleToJSON
import System.Directory
import System.File.ReadWrite

%default partial

public export
record Env ev where
  constructor MkEnv
  dataDir : String
  subs : IORef.IORef (SortedMap String (SortedMap Int (Nat -> List ev -> IO ())))
  catSubs : IORef.IORef (SortedMap Int (String -> Bool, String -> Nat -> List ev -> IO ()))
  nextId : IORef.IORef Int

public export
mkEnv : String -> IO (Env ev)
mkEnv dir = do
  subs <- IORef.newIORef empty
  catSubs <- IORef.newIORef empty
  nextId <- IORef.newIORef 0
  pure (MkEnv dir subs catSubs nextId)

public export
App : Type -> Type -> Type
App ev a = ReaderT (Env ev) IO a

joinWith : String -> List String -> String
joinWith _ [] = ""
joinWith sep (x :: xs) = foldl (\acc, item => acc ++ sep ++ item) x xs

dropPrefixChars : List Char -> List Char -> Maybe (List Char)
dropPrefixChars [] xs = Just xs
dropPrefixChars _ [] = Nothing
dropPrefixChars (p :: ps) (x :: xs) =
  if p == x
    then dropPrefixChars ps xs
    else Nothing

hasSuffixChars : List Char -> List Char -> Bool
hasSuffixChars suffix xs = isPrefixOf (reverse suffix) (reverse xs)

dropSuffixChars : List Char -> List Char -> Maybe (List Char)
dropSuffixChars suffix xs =
  if hasSuffixChars suffix xs
    then Just (reverse (drop (length suffix) (reverse xs)))
    else Nothing

splitUnderscore : List Char -> List (List Char)
splitUnderscore [] = [[]]
splitUnderscore (c :: cs) =
  if c == '_'
    then [] :: splitUnderscore cs
    else
      case splitUnderscore cs of
        [] => [[c]]
        token :: rest => (c :: token) :: rest

digitNat : Char -> Maybe Nat
digitNat '0' = Just 0
digitNat '1' = Just 1
digitNat '2' = Just 2
digitNat '3' = Just 3
digitNat '4' = Just 4
digitNat '5' = Just 5
digitNat '6' = Just 6
digitNat '7' = Just 7
digitNat '8' = Just 8
digitNat '9' = Just 9
digitNat _ = Nothing

parseNatDigits : List Char -> Nat -> Maybe Nat
parseNatDigits [] acc = Just acc
parseNatDigits (c :: cs) acc =
  case digitNat c of
    Nothing => Nothing
    Just d => parseNatDigits cs (acc * 10 + d)

decodeCodeToken : List Char -> Maybe Char
decodeCodeToken [] = Nothing
decodeCodeToken token =
  case parseNatDigits token 0 of
    Nothing => Nothing
    Just n => Just (cast {to=Char} n)

decodeCodeTokens : List (List Char) -> Maybe (List Char)
decodeCodeTokens [] = Just []
decodeCodeTokens (token :: rest) =
  case decodeCodeToken token of
    Nothing => Nothing
    Just c =>
      case decodeCodeTokens rest of
        Nothing => Nothing
        Just cs => Just (c :: cs)

decodeStreamFileName : String -> Maybe String
decodeStreamFileName fileName =
  let chars = unpack fileName in
  case dropPrefixChars (unpack "sid-") chars of
    Nothing => Nothing
    Just afterPrefix =>
      case dropSuffixChars (unpack ".jsonl") afterPrefix of
        Nothing => Nothing
        Just [] => Just ""
        Just codeChars =>
          case decodeCodeTokens (splitUnderscore codeChars) of
            Nothing => Nothing
            Just streamChars => Just (pack streamChars)

decodeStreamFileNames : List String -> List String
decodeStreamFileNames [] = []
decodeStreamFileNames (entry :: rest) =
  case decodeStreamFileName entry of
    Nothing => decodeStreamFileNames rest
    Just streamId => streamId :: decodeStreamFileNames rest

encodeStreamId : String -> String
encodeStreamId sid =
  let codes = map (\c => show (cast {to=Nat} c)) (unpack sid)
   in "sid-" ++ joinWith "_" codes

fileNameFor : String -> String
fileNameFor streamId = encodeStreamId streamId ++ ".jsonl"

pathFor : String -> String -> String
pathFor dataDir streamId = dataDir ++ "/" ++ fileNameFor streamId

parseEvents : FromJSON ev => List String -> Either LoadErr (List ev)
parseEvents rawLines =
  let lines' = filter (\line => length line > 0) rawLines
   in traverse decodeLine lines'
  where
    decodeLine : String -> Either LoadErr ev
    decodeLine line =
      case decode {a=ev} line of
        Left _ => Left Corrupt
        Right ev => Right ev

versionOf : List ev -> Nat
versionOf = length

getSubs : Ord stream => stream -> SortedMap stream (SortedMap Int cb) -> SortedMap Int cb
getSubs sid m = maybe empty id (lookup sid m)

loadFile : FromJSON ev => Env ev -> String -> IO (Either LoadErr (Nat, List ev))
loadFile env streamId = do
  let path = pathFor (dataDir env) streamId
  let fname = fileNameFor streamId
  Right entries <- listDir (dataDir env) | Left _ => pure (Left IOLoadError)
  case elem fname entries of
    True => do
      content <- readFile path
      case content of
        Left _ => pure (Left IOLoadError)
        Right txt =>
          case parseEvents (lines txt) of
            Left err => pure (Left err)
            Right evs => pure (Right (versionOf evs, evs))
    False =>
      pure (Left NoStream)

appendNew : ToJSON ev => Env ev -> String -> Nat -> List ev -> App ev (Either AppendErr Nat)
appendNew env streamId version newEvents = do
  let path = pathFor (dataDir env) streamId
  let encoded = map SimpleToJSON.encode newEvents
  let content = if length encoded == 0 then "" else unlines encoded
  case content of
    "" => pure (Right version)
    _ => do
      res <- lift $ appendFile path content
      case res of
        Left _ => pure (Left IOAppendError)
        Right () => do
          subsMap <- lift $ IORef.readIORef env.subs
          let byStream = getSubs streamId subsMap
          let startVersion = version
          lift $ traverse_ (\cb => cb startVersion newEvents) (values byStream)
          catSubsMap <- lift $ IORef.readIORef env.catSubs
          lift $
            traverse_
              (\(matches, cb) =>
                if matches streamId
                  then cb streamId startVersion newEvents
                  else pure ())
              (values catSubsMap)
          pure (Right (version + length newEvents))

loadKnownStreams : Env ev -> IO (Either ListStreamsErr (List String))
loadKnownStreams env = do
  Right entries <- listDir (dataDir env) | Left _ => pure (Left IOListStreamsError)
  pure (Right (sort (decodeStreamFileNames entries)))

public export
implementation {ev : Type} -> (FromJSON ev, ToJSON ev) => EventStore (ReaderT (Env ev) IO) String ev where
  load streamId = do
    env <- ask
    lift $ loadFile env streamId

  loadFrom streamId from = do
    env <- ask
    res <- lift $ loadFile env streamId
    case res of
      Left err => pure (Left err)
      Right (v, evs) => pure (Right (v, drop from evs))

  append streamId expected newEvents = do
    env <- ask
    loadRes <- lift $ loadFile env streamId
    case loadRes of
      Left NoStream =>
        if expected /= 0
          then pure (Left Conflict)
          else appendNew env streamId 0 newEvents
      Left _ =>
        pure (Left IOAppendError)
      Right (v, _) =>
        if expected /= v
          then pure (Left Conflict)
          else appendNew env streamId v newEvents

public export
implementation {ev : Type} -> Observable (ReaderT (Env ev) IO) String ev where
  subscribe streamId cb = do
    env <- ask
    i <- lift $ IORef.readIORef env.nextId
    lift $ IORef.writeIORef env.nextId (i + 1)

    let cbIO : Nat -> List ev -> IO ()
        cbIO from es = runReaderT env (cb from es)

    lift $ IORef.modifyIORef env.subs $ \m =>
      let byStream = getSubs streamId m
          byStream' = insert i cbIO byStream
       in insert streamId byStream' m

    pure $ do
      env2 <- ask
      lift $ IORef.modifyIORef env2.subs $ \m =>
        let byStream = getSubs streamId m
            byStream' = delete i byStream
         in insert streamId byStream' m

public export
implementation {ev : Type} -> ObservableCategory (ReaderT (Env ev) IO) String ev where
  subscribeCategory matches cb = do
    env <- ask
    i <- lift $ IORef.readIORef env.nextId
    lift $ IORef.writeIORef env.nextId (i + 1)

    let cbIO : String -> Nat -> List ev -> IO ()
        cbIO sid from es = runReaderT env (cb sid from es)

    lift $ IORef.modifyIORef env.catSubs (insert i (matches, cbIO))

    pure $ do
      env2 <- ask
      lift $ IORef.modifyIORef env2.catSubs (delete i)

public export
implementation {ev : Type} -> StreamCatalog (ReaderT (Env ev) IO) String where
  listStreams = do
    env <- ask
    lift $ loadKnownStreams env
