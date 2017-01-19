port module Viewer exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import Array exposing (Array)
import Keyboard
import Json.Encode as E
import Json.Decode as D exposing (Decoder)
import Window exposing (Size)
import Task


type alias Json = E.Value


main : Program Bool Model Msg
main =
  programWithFlags
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }



port onData : (Json -> msg) -> Sub msg


port onPage : (Int -> msg) -> Sub msg


-- MODEL


type alias Model =
  { editMode : Bool
  , module_ : Module
  , selectedAddress : Address
  , windowSize : Size
  }


type alias Module =
  { pages : Array Page
  }


type alias Page =
  { nodes : List Node
  , animationLength : Int
  }


type Node
  = ElementNode Element
  | TextNode String


type alias Element =
  { tag : String
  , classes : List Class
  , attributes : List Attribute
  , children : List Node
  }


type alias Class =
  { name : String
  , animationIndex : Int
  }


type alias Attribute =
  { key : String
  , value : String
  }


type alias Address =
  { page : Int
  , animation : Int
  }


emptyModule : Module
emptyModule =
  Module Array.empty


decodeModule : Decoder Module
decodeModule =
  D.map (Array.fromList >> Module)
    (D.field "pages" (D.list decodePage))


decodePage : Decoder Page
decodePage =
  D.map2 Page
    (D.field "nodes" (D.list decodeNode))
    (D.field "length" D.int)


decodeNode : Decoder Node
decodeNode =
  D.oneOf
    [ D.map ElementNode (D.lazy <| \_ -> decodeElement)
    , D.map TextNode D.string
    ]


decodeElement : Decoder Element
decodeElement =
  D.map4 Element
    (D.field "tag" D.string)
    (D.field "classes" (D.list decodeClass))
    (D.field "attributes" (D.list decodeAttribute))
    (D.field "children" (D.list decodeNode))


decodeClass : Decoder Class
decodeClass =
  D.map2 Class
    (D.field "name" D.string)
    (D.field "animationIndex" D.int)


decodeAttribute : Decoder Attribute
decodeAttribute =
  D.map2 Attribute
    (D.field "key" D.string)
    (D.field "value" D.string)


nextAddress : Bool -> Array Page -> Address -> Address
nextAddress forward pages address =
  let
    next =
      if forward then
        { address | animation = address.animation + 1 }
      else
        { address | animation = address.animation - 1 }
  in
    validateAddress pages next
      |> Maybe.withDefault address


validateAddress : Array Page -> Address -> Maybe Address
validateAddress pages address =
  if address.animation == -1 then
    validateAddress pages { page = address.page - 1, animation = -2 }
  else
    Array.get address.page pages
      |> Maybe.andThen (\page ->
        if address.animation == -2 then
          Just <| { address | animation = page.animationLength - 1 }
        else if address.animation >= page.animationLength then
          validateAddress pages { page = address.page + 1, animation = 0 }
        else
          Just address
        )



-- UPDATE


type Msg
  = NoOp
  | Data Json
  | Resize Size
  | Prev
  | Next
  | PageChanged Int


init : Bool -> (Model, Cmd Msg)
init editMode =
  { editMode = editMode
  , module_ = Module Array.empty
  , selectedAddress = Address 0 0
  , windowSize = Size 0 0
  } ! [ Window.size |> Task.perform Resize ]


toModule : Json -> Module
toModule flags =
  case D.decodeValue decodeModule flags of
    Ok mod -> mod
    Err s ->
      Debug.crash s


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      model ! []

    Data data ->
      { model | module_ = toModule data } ! []

    Resize size ->
      { model | windowSize = size } ! []

    Prev ->
      { model
        | selectedAddress =
            nextAddress False model.module_.pages model.selectedAddress
      } ! []

    Next ->
      { model
        | selectedAddress =
            nextAddress True model.module_.pages model.selectedAddress
      } ! []

    PageChanged index ->
      { model
        | selectedAddress = { page = index, animation = 0 }
      } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [ Window.resizes Resize
  , if model.editMode then
      Sub.none
    else
      Keyboard.downs (\keyCode ->
        if keyCode == 37 || keyCode == 38 then
          Prev
        else if keyCode == 39 || keyCode == 40 then
          Next
        else
          NoOp
      )
  , onData Data
  , onPage PageChanged
  ]




-- VIEW

view : Model -> Html Msg
view model =
  if model.windowSize.width == 0 then
    text ""
  else if Array.isEmpty model.module_.pages then
    div [] [ viewPage model.editMode model.windowSize model.selectedAddress 0 (Page [] 1) ]
  else
    model.module_.pages
      |> Array.toList
      |> List.indexedMap (viewPage model.editMode model.windowSize model.selectedAddress)
      |> div []


viewPage : Bool -> Size -> Address -> Int -> Page -> Html Msg
viewPage editMode windowSize selectedAddress index page =
  page.nodes
    |> List.map (lazy2 viewNode selectedAddress.animation)
    |> div
      [ class ("page" ++
        if index > selectedAddress.page then
          " page-future"
        else if index < selectedAddress.page then
          " page-past"
        else
          " page-selected"
        )
      , style (if editMode then [] else [ ("transform", "scale(" ++ toString (toFloat windowSize.height / 480) ++ ")") ])
      , onClick Next
      ]


viewNode : Int -> Node -> Html msg
viewNode selectedAnimationIndex node =
  case node of
    ElementNode e ->
      Html.node e.tag
        (  makeClasses selectedAnimationIndex e.classes
        ++ (e.attributes |> List.map (\attr -> attribute attr.key attr.value))
        )
        (e.children |> List.map (viewNode selectedAnimationIndex))

    TextNode s ->
      text s


makeClasses : Int -> List Class -> List (Html.Attribute msg)
makeClasses selectedAnimationIndex classes =
  classes
    |> List.filter (\c -> c.animationIndex <= selectedAnimationIndex)
    |> List.map (.name >> class)
