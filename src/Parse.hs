module Parse
  ( Parse.parse
  , module'
  , nodeFuncName
  , animationIndex
  , text
  , expression
  ) where


import Text.ParserCombinators.Parsec as Parsec
import ParseAST
import Data.Maybe


module' :: Parser Module
module' = do
  many newline
  pages <- sepBy page pageSeparator
  eof
  return $ Module pages


pageSeparator :: Parser String
pageSeparator = do
  string "----"
  many (char '-')


page :: Parser Page
page = do
  many emptyLine
  topExpressions <- many topExpression
  spaces
  return $ Page topExpressions
  <?> "page"


emptyLine :: Parser String
emptyLine = do
  newline
  many (char ' ')


topExpression :: Parser TopExpression
topExpression =
  (try def <|> do
    exp <- try expressionWithIndent
    return $ Expression exp
  ) <?> "top expression"


def :: Parser TopExpression
def = do
  string ":def"
  many (char ' ')
  args <- arguments ""
  many newline
  return $ Def args
  <?> "def"


expressionWithIndent :: Parser Expression
expressionWithIndent = do
  indent <- many (char ' ')
  exp <- expression indent
  many newline
  return exp
  <?> "expression with indent"


expression :: String -> Parser Expression
expression indent =
  func indent <|> text
  <?> "expression"


func :: String -> Parser Expression
func indent = do
  name <- funcName
  many (char ' ')
  args <- arguments indent
  return $ Func name args
  <?> "function"


arguments :: String -> Parser [Expression]
arguments indent = do
  args1 <- many inlineArgument
  args2 <- childLines indent
  return $ args1 ++ args2


inlineArgument :: Parser Expression
inlineArgument = do
  char '|'
  text
  <?> "inline argument"


childLines :: String -> Parser [Expression]
childLines parentIndent =
  many (try $ childLine parentIndent)
  <?> "child lines"


childLine :: String -> Parser Expression
childLine parentIndent = do
  many1 newline
  string parentIndent
  additionalIndent <- many1 (char ' ')
  expression (parentIndent ++ additionalIndent)
  <?> "child line"


funcName :: Parser FuncName
funcName =
  normalFuncName <|> try nodeFuncName
  <?> "function name"


normalFuncName :: Parser FuncName
normalFuncName = do
  char ':'
  name <- many1 (letter <|> digit)
  return $ NormalFuncName name
  <?> "normal func name"


nodeFuncName :: Parser FuncName
nodeFuncName = do
  tag <- optionMaybe (try tagName)
  attrs <- (if tag == Nothing then many1 else many) property
  return $ NodeFuncName (fromMaybe "div" tag) attrs
  <?> "node func name"


tagName :: Parser String
tagName = do
  char '$'
  c <- letter
  cs <- many (letter <|> digit)
  return $ c : cs
  <?> "tag name"


property :: Parser Property
property =
  class' <|> attribute <?> "property"


class' :: Parser Property
class' = do
  char '.'
  name <- many1 (letter <|> char '-')
  aIndex <- optionMaybe animationIndex
  return $ Class name aIndex
  <?> "class"


attribute :: Parser Property
attribute = do
  char '['
  many (char ' ')
  name <- many1 (letter <|> char '-')
  many (char ' ')
  char '='
  many (char ' ')
  exp <- attrValueHelp
  many (char ' ')
  char ']'
  return $ Attribute name exp
  <?> "attribute"


attrValueHelp :: Parser Expression
attrValueHelp = do
  s <- many1 (noneOf ['\n', '|', '-', ']'])
  return $ Text (trim s)


animationIndex :: Parser Expression
animationIndex = do
  char '('
  many (char ' ')
  index <- animationIndexHelp
  many (char ' ')
  char ')'
  return index
  <?> "animation index"


animationIndexHelp :: Parser Expression
animationIndexHelp = do
  s <- many1 (noneOf ['\n', '|', '-', ')'])
  return $ Text (trim s)


text :: Parser Expression
text = do
  s <- many1 (noneOf ['\n', '|', '-'])
  return $ Text (trim s)
  <?> "text"


trim = unwords . words


parse s =
  Parsec.parse module' "" s
