port module Editor exposing (..)

import Html exposing (..)
import WebSocket
import Platform
import Time exposing (Time, second)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E

type alias Json = E.Value


main : Program String Model Msg
main =
  Platform.programWithFlags
    { init = init
    , update = update
    , subscriptions = subscriptions
    }



-- PORT


port onText : (String -> msg) -> Sub msg


port requestText : () -> Cmd msg


port initialSource : String -> Cmd msg


port receivedModule : Json -> Cmd msg



-- MODEL


type alias Model =
  { waiting : Bool
  , id : String
  }



-- UPDATE


type Msg
  = GotText String
  | Tick Time
  | ServerMessage String



wsRoot : String -> String
wsRoot id =
  "ws://localhost:3001/" ++ id


send : String -> String -> Cmd Msg
send id data =
  WebSocket.send (wsRoot id) data


init : String -> (Model, Cmd Msg)
init id =
  { waiting = True
  , id = id
  } ! [ send id "init" ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Tick _ ->
      model ! [ requestText () ]

    GotText source ->
      { model | waiting = True } ! [ send model.id source ]

    ServerMessage data ->
      case D.decodeString decodeMessage data of
        Ok (InitialData source) ->
          { model | waiting = False } ! [ initialSource source ]

        Ok (CompiledData data) ->
          { model | waiting = False } ! [ receivedModule data ]

        Ok (CompileError err) ->
          { model | waiting = False } ! []

        Err s ->
          Debug.crash s


type Message
  = InitialData String
  | CompiledData Json
  | CompileError String


decodeMessage : Decoder Message
decodeMessage =
  D.field "type" D.string
    |> D.andThen (\t ->
      if t == "initialSource" then
        D.field "data" D.string |> D.map InitialData
      else if t == "compiledData" then
        D.field "data" D.value |> D.map CompiledData
      else if t == "compileError" then
        D.field "data" D.string |> D.map CompileError
      else
        D.fail "unknown message"
      )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ WebSocket.listen (wsRoot model.id) ServerMessage
    , if model.waiting then
        Sub.none
      else
        Time.every (1 * second) Tick
    , onText GotText
    ]
