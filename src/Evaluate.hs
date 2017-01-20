module Evaluate where

import Data.List
import Data.Maybe
import qualified Data.Map as Map
import qualified ParseAST as P
import EvaluateAST
import Debug.Trace
import Text.Read
import Control.Arrow
import Data.String.Utils

type Context =
  Map.Map String FunctionDef

data FunctionDef
  = FunctionDef (Context -> [Value] -> Either String Value)

instance Show FunctionDef where
  show _ = "<FunctionDef>"



trace' s a =
  trace (s ++ ": " ++ show a) a


-- PREDEF


initialContext :: Context
initialContext =
  Map.fromList
    [ ("image", FunctionDef defImage)
    , ("list", FunctionDef defList)
    , ("link", FunctionDef defLink)
    , ("pre", FunctionDef defPre)
    , ("text", FunctionDef defText)
    ]


defImage :: (Context -> [Value] -> Either String Value)
defImage _ args =
  case args of
    [] ->
      Left ":image | url | (width)\n\turl is not passed."

    src_ : rest -> do
      src <- castToString src_
      width <- do
        case rest of
          [] ->
            return []

          x : _ -> do
            w <- castToString x
            return [("width", w)]
      return $ Node $ ElementNode "img" [] (("src", src) : width) []


defList :: Context -> [Value] -> Either String Value
defList _ args = do
  children <- mapM makeLi args
  return $ Node $ ElementNode "ul" [] [] children


makeLi :: Value -> Either String Node
makeLi value = do
  node <- castToNode value
  return $ ElementNode "li" [] [] [ node ]


defLink :: Context -> [Value] -> Either String Value
defLink _ args =
  case args of
    [] ->
      Left ":link | href | contents\n\thref is not passed."

    x : xs -> do
      url <- castToString x
      children <- mapM castToNode xs
      return $ Node $ ElementNode "a" [] [("href", url)] children


defPre :: Context -> [Value] -> Either String Value
defPre _ args = do
  textNode <- makePreLines args
  return $ Node $ ElementNode "pre" [] [] [ textNode ]


makePreLines :: [Value] -> Either String Node
makePreLines values = do
  ss <- mapM castToString values
  return $ TextNode (intercalate "\\n" ss)


defText :: Context -> [Value] -> Either String Value
defText context args = do
  strings <- mapM castToString args
  return $ StringValue $ concat strings



-- EVALUATE AND COLLECT DEFS


evaluate :: P.Module -> Either String Module
evaluate mod =
  evalModule initialContext mod


evalModule :: Context -> P.Module -> Either String Module
evalModule context (P.Module pages) = do
  pgs <- mapM (evalPage context) pages
  return $ Module pgs


evalPage :: Context -> P.Page -> Either String Page
evalPage context (P.Page topExpressions) = do
  pageContext <- evalPageDefs context topExpressions
  nodes <- mapM (evalTopExpression pageContext) topExpressions
  return $ Page (catMaybes nodes)


evalPageDefs :: Context -> [P.TopExpression] -> Either String Context
evalPageDefs context topExpressions =
  case topExpressions of
    [] ->
      Right context

    x : xs -> do
      c <- evalDef context x
      evalPageDefs c xs


evalDef :: Context -> P.TopExpression -> Either String Context
evalDef context topExpression =
  case topExpression of
    P.Def args ->
      evalDefFunc context args

    P.Expression expression ->
      Right context


evalDefFunc :: Context -> [P.Expression] -> Either String Context
evalDefFunc context args =
  case args of
    name : definition : _ -> do
      name_ <- evalExpression context name
      name__ <- castToString name_
      return $ Map.insert name__ (makeFunction definition) context

    [] ->
      Left ":def must have 2 arguments, name and definition."


makeFunction :: P.Expression -> FunctionDef
makeFunction definition = FunctionDef (\context args ->
  let
    (_, localMap) =
      foldl
        (\(index, map) arg -> (index + 1, Map.insert (show index) (FunctionDef (\_ _ -> Right arg)) map))
        (1, Map.empty)
        args

    newContext =
      Map.union localMap context
  in
    evalExpression newContext definition
  )


evalTopExpression :: Context -> P.TopExpression -> Either String (Maybe Node)
evalTopExpression context topExpression =
  case topExpression of
    P.Def _ ->
      Right Nothing

    P.Expression expression -> do
      exp <- evalExpression context expression
      node <- castToNode exp
      return $ Just node


evalExpression :: Context -> P.Expression -> Either String Value
evalExpression context expression =
  case expression of
    P.Func funcName args ->
      evalFunc context funcName args

    P.Text s ->
      case s of
        '#' : name ->
          evalNormalFunc context name []

        _ ->
          Right $ StringValue s


evalFunc :: Context -> P.FuncName -> [P.Expression] -> Either String Value
evalFunc context funcName args = do
  case funcName of
    P.NormalFuncName name ->
      if name == "def" then
        Left ":def must be used at top level"
      else
        evalNormalFunc context name args

    P.NodeFuncName tagName attrs -> do
      node <- evalNodeFunc context tagName attrs args
      return $ Node node


evalNormalFunc :: Context -> String -> [P.Expression] -> Either String Value
evalNormalFunc context name args =
  case Map.lookup name context of
    Nothing ->
      Right Null

    Just (FunctionDef f) -> do
      args_ <- mapM (evalExpression context) args
      f context args_


evalNodeFunc :: Context -> String -> [P.Property] -> [P.Expression] -> Either String Node
evalNodeFunc context tagName attrs children = do
  (classes, attrs_) <- evalProperties context attrs ([], [])
  children_ <- mapM (evalExpression context) children
  children__ <- mapM castToNode children_
  Right $ ElementNode tagName classes attrs_ children__


evalProperties :: Context -> [P.Property] -> ([Class], [Attribute]) -> Either String ([Class], [Attribute])
evalProperties context property (classes, attrs) =
  case property of
    [] ->
      Right (classes, attrs)

    x : xs ->
      case x of
        P.Class name aniIndex -> do
          indexInt <-
            case aniIndex of
              Just aniIndex -> do
                value <- evalExpression context aniIndex
                maybeInt <- castToMaybeInt value
                return $ fromMaybe 0 maybeInt

              Nothing ->
                Right 0
          evalProperties context xs ((name, indexInt) : classes, attrs)

        P.Attribute key value -> do
          valueValue <- evalExpression context value
          valueMaybeString <- castToMaybeString valueValue
          case valueMaybeString of
            Just valueString ->
              evalProperties context xs (classes, (key, valueString) : attrs)
            Nothing ->
              Right (classes, attrs)


-- CAST


castToNode :: Value -> Either String Node
castToNode value =
  case value of
    StringValue s ->
      Right (TextNode s)

    Node node ->
      Right node

    Null ->
      Left "expected Node but got Null"


castToString :: Value -> Either String String
castToString value =
  case value of
    StringValue s ->
      Right s

    Node (ElementNode _ _ _ _) ->
      Left "expected String but got ElementNode"

    Node (TextNode s) ->
      Right s

    Null ->
      Left "expected String but got Null"


castToMaybeString :: Value -> Either String (Maybe String)
castToMaybeString value =
  case value of
    Null ->
      Right $ Nothing

    _ -> do
      s <- castToString value
      return $ Just s


castToInt :: Value -> Either String Int
castToInt value =
  case value of
    StringValue s ->
      left (\_ -> "expected Int but got " ++ s) $ readEither s

    Node (ElementNode _ _ _ _) ->
      Left "expected Int but got ElementNode"

    Node (TextNode s) ->
      left (\_ -> "expected Int but got " ++ s) $ readEither s

    Null ->
      Left "expected Int but got Null"


castToMaybeInt :: Value -> Either String (Maybe Int)
castToMaybeInt value =
  case value of
    Null ->
      Right $ Nothing

    _ -> do
      s <- castToInt value
      return $ Just s
