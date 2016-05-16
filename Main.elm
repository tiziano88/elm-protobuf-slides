import Array exposing (Array)
import Char
-- import History
import Html
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Keyboard
-- import Location
import Markdown
import String
import Task exposing (Task)
import Window


main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions =
      \_ -> Sub.batch
        [ Window.resizes Resize
        , Keyboard.downs (\k ->
          case k of
            -- http://keycode.info/
            13 -> NextPage -- enter
            32 -> NextPage -- space
            37 -> PreviousPage -- left arrow
            38 -> PreviousPage -- up arrow
            39 -> NextPage -- right arrow
            40 -> NextPage -- down arrow
            _ -> Nop
          )
        ]
    }


type alias Model =
  { content : String
  , pages : Array String
  , currentPage : Int
  , size : Window.Size
  }


url = "./slides.md"


getContent : Cmd Msg
getContent =
  Http.getString url
    |> Task.perform (always Nop) SetContent


getLocation : Cmd Msg
getLocation =
  Cmd.none
  --Location.location
    --|> Task.map (\l -> l.hash)
    --|> Task.map (String.dropLeft 1)
    --|> Task.map String.toInt
    --|> Task.map (Result.withDefault 1)
    --|> Task.map (\x -> x - 1)
    --|> Task.perform (always Nop) SetCurrentPage

const x _ = x

init : (Model, Cmd Msg)
init =
  (initialModel, Cmd.batch [ getContent, getLocation ])


initialModel : Model
initialModel =
  { content = ""
  , pages = Array.empty
  , currentPage = 0
  , size = { width = 0, height = 0 }
  }


type Msg
  = Nop
  | SetContent String
  | SetCurrentPage Int
  | NextPage
  | PreviousPage
  | Resize Window.Size


noEffects : a -> (a, Cmd b)
noEffects m =
  (m, Cmd.none)


updateHash : Model -> (Model, Cmd Msg)
updateHash m =
  (m, Cmd.none)
  --( m
  --, History.replacePath ("#" ++ toString (m.currentPage + 1))
    --|> Task.map (\x -> Nop)
    --|> Effects.task
  --)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Nop ->
      noEffects model

    SetContent s ->
      noEffects { model | pages = Array.fromList <| String.split "\n--\n" s }

    SetCurrentPage p ->
      noEffects { model | currentPage = p }

    NextPage ->
      let
        newPage = model.currentPage + 1
      in
        if newPage < Array.length model.pages
        then updateHash { model | currentPage = newPage }
        else noEffects model

    PreviousPage ->
      let
        newPage = model.currentPage - 1
      in
        if newPage >= 0
        then updateHash { model | currentPage = newPage }
        else noEffects model

    Resize s ->
      noEffects { model | size = s }


ratio = 3/2


markdownOptions : Markdown.Options
markdownOptions =
  { githubFlavored = Just { tables = True, breaks = False }
  , defaultHighlighting = Nothing
  , sanitize = False
  , smartypants = True
  }


view model =
  Html.div
    [ style
      [ "padding" => "1em"
      , "margin" => "auto"
      , "width" => "40em"
      , "font-family" => "'Ubuntu'"
      , "font-size" =>
        if (toFloat model.size.width)/(toFloat model.size.height) < ratio then "2vw" else "3vh"
      ]
    ]
    [ Html.node "script" [ src "./highlight/highlight.pack.js" ] []
    , Html.node "link" [ rel "stylesheet", href "http://fonts.googleapis.com/css?family=Ubuntu" ] []
    , Html.node "link" [ rel "stylesheet", href "http://fonts.googleapis.com/css?family=Ubuntu Mono" ] []
    , Html.node "link" [ rel "stylesheet", href "./highlight/styles/solarized-light.css" ] []
    , Html.node "link" [ rel "stylesheet", href "./style.css" ] []
    , Html.div
      [ style
        [ "background-color" => "white"
        , "box-shadow" => "0 0 10px"
        , "border-radius" => "10px"
        , "padding" => "2em 3em"
        ]
      ]
      [ Html.div -- Content.
        [ style
          [ "height" => "25em"
          , "overflow" => "auto"
          ]
        ]
        [ Markdown.toHtmlWith markdownOptions [] <| Maybe.withDefault "" <| Array.get model.currentPage model.pages ]
      , Html.div -- Footer.
        [ style
          [ "border-top" => "solid black" ]
        ]
        [ Html.a
          [ onClick PreviousPage
          , href "#"
          ]
          [ Html.text "<<<" ]
        , Html.span
          [ style
            [ "width" => "5em"
            , "display" => "inline-block"
            , "text-align" => "right"
            ]
          ]
          [ Html.text (toString <| model.currentPage + 1) ]
        , Html.span []
          [ Html.text "/" ]
        , Html.span []
          [ Html.text (toString <| Array.length model.pages) ]
        , Html.a
          [ onClick NextPage
          , href "#"
          ]
          [ Html.text ">>>" ]
        ]
      ]
    ]


(=>) : String -> String -> (String, String)
(=>) = (,)
