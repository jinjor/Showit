module Generate where


import Data.Maybe
import EvaluateAST
import Json


generate :: Module -> String
generate mod =
  render "" $ genModule mod


genModule :: Module -> Json
genModule (Module pages) =
  JObject
    [ ("pages", JList $ map genPage pages)
    ]


genPage :: Page -> Json
genPage (Page nodes) =
  JObject
    [ ("nodes", JList $ map genNode nodes)
    , ("length", JValue $ show $ getAnimationLength (Page nodes))
    ]


genNode :: Node -> Json
genNode node =
  case node of
    ElementNode tagName classes attributes children ->
      JObject
        [ ("tag", JString tagName)
        , ("classes", JList $ map genClass classes)
        , ("attributes", JList $ map genAttribute attributes)
        , ("children", JList $ map genNode children)
        ]

    TextNode s ->
      JString s


genClass :: Class -> Json
genClass (name, animationIndex) =
  JObject
    [ ("name", JString name)
    , ("animationIndex", JValue $ show animationIndex)
    ]


genAttribute :: Attribute -> Json
genAttribute (key, value) =
  JObject
    [ ("key", JString key)
    , ("value", JString value)
    ]
