module Json where


import Data.List


data Json
  = JObject [(String, Json)]
  | JList [Json]
  | JValue String
  | JString String


render :: String -> Json -> String
render indent json =
  case json of
    JObject properties ->
      "{\n" ++
      intercalate ",\n" (map (renderProperty $ indent ++ "  ") properties) ++ "\n" ++
      indent ++ "}"

    JList elements ->
      "[\n" ++
      intercalate ",\n" (map (renderElement $ indent ++ "  ") elements) ++ "\n" ++
      indent ++ "]"

    JValue value ->
      value

    JString str ->
      "\"" ++ escape str ++ "\""


renderProperty indent (key, value) =
  indent ++ "\"" ++ escape key ++ "\": " ++ render indent value


renderElement indent element =
  indent ++ render indent element


escape s = s
