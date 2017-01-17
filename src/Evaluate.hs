module Evaluate where


import Data.Maybe
import qualified Data.Map as Map
import qualified ParseAST as P
import EvaluateAST
import Debug.Trace


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
        (\(index, map) arg -> (index + 1, Map.insert ("$" ++ show index) (FunctionDef (\_ _ -> Right arg)) map))
        (1, Map.empty)
        args

    newContext = trace' "makeFunction" $
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
    P.Func funcName args -> do
      node <- evalFunc context funcName args
      Right $ Node node

    P.Text s ->
      case s of
        '$' : name -> do
          node <- evalNormalFunc context s []
          Right $ Node node

        _ ->
          Right $ String s


evalFunc :: Context -> P.FuncName -> [P.Expression] -> Either String Node
evalFunc context funcName args = do
  case funcName of
    P.NormalFuncName name ->
      if name == "def" then
        Left ":def must be used at top level"
      else
        evalNormalFunc context name args

    P.NodeFuncName tagName attrs ->
      evalNodeFunc context tagName attrs args


evalNormalFunc :: Context -> String -> [P.Expression] -> Either String Node
evalNormalFunc context name args =
  case Map.lookup name (trace' ("evalNormalFunc: " ++ name) $ context) of
    Nothing ->
      error $ ":" ++ name ++ " is not defined."

    Just (FunctionDef f) -> do
      args_ <- mapM (evalExpression context) args
      value <- f context args_
      castToNode value


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
                indexValue <- evalExpression context aniIndex
                castToInt indexValue

              Nothing ->
                Right 0
          evalProperties context xs ((name, indexInt) : classes, attrs)

        P.Attribute key value -> do
          valueValue <- evalExpression context value
          valueString <- castToString valueValue
          evalProperties context xs (classes, (key, valueString) : attrs)



-- CAST


castToNode :: Value -> Either String Node
castToNode value =
  case value of
    String s ->
      Right (TextNode s)

    Node node ->
      Right node


castToString :: Value -> Either String String
castToString value =
  case value of
    String s ->
      Right s

    Node (ElementNode _ _ _ _) ->
      Left "expected String but got ElementNode"

    Node (TextNode s) ->
      Right s


castToInt :: Value -> Either String Int
castToInt value =
  case value of
    String s ->
      Right (read s)

    Node (ElementNode _ _ _ _) ->
      Left "expected Int but got ElementNode"

    Node (TextNode s) ->
      Right (read s)
