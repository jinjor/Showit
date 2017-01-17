module ParseAST where


data Module
  = Module [Page]
  deriving Show

data Page
  = Page [TopExpression]
  deriving Show


data TopExpression
  = Def [Expression]
  | Expression Expression
  deriving Show


data Expression
  = Func FuncName [Expression]
  | Text String
  deriving Show


data FuncName
  = NormalFuncName String
  | NodeFuncName String [Property]
  deriving Show


data Property
  = Class String (Maybe Expression)
  | Attribute String Expression
  deriving Show
