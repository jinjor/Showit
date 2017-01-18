module EvaluateAST where


data Module
  = Module [Page]
  deriving Show


data Page
  = Page [Node]
  deriving Show


data Value
  = StringValue String
  | Node Node
  | Null
  deriving Show

data Node
  = ElementNode String [Class] [Attribute] [Node]
  | TextNode String
  deriving Show


type Class =
  (String, Int)


type Attribute =
  (String, String)


getAnimationLength :: Page -> Int
getAnimationLength page =
  let
    indices =
      getAnimationLengthHelp page []

    maxIndex =
      foldl max 0 indices
  in
    maxIndex + 1


getAnimationLengthHelp :: Page -> [Int] -> [Int]
getAnimationLengthHelp (Page nodes) indices =
  foldr getAnimationLengthHelp2 indices nodes


getAnimationLengthHelp2 :: Node -> [Int] -> [Int]
getAnimationLengthHelp2 node indices =
  case node of
    ElementNode _ classes _ children ->
      foldr getAnimationLengthHelp2 (foldr getAnimationLengthHelp3 indices classes) children

    TextNode _ ->
      indices


getAnimationLengthHelp3 :: Class -> [Int] -> [Int]
getAnimationLengthHelp3 (_, animationIndex) indices =
  animationIndex : indices
