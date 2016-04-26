import Array exposing (Array)
import Effects exposing (Effects)
import Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Keyboard
import Markdown
import StartApp
import String
import Task exposing (Task)


main : Signal Html.Html
main =
  app.html


port tasks : Signal (Task Effects.Never ())
port tasks =
  app.tasks

type alias Model =
  { content : String
  , pages : Array String
  , currentPage : Int
  }


url = "./slides.md"


getContent : Effects Action
getContent =
  Http.getString url
    |> Task.toMaybe
    |> Task.map (Maybe.withDefault "")
    |> Task.map SetContent
    |> Effects.task


app =
  StartApp.start
    { init = init
    , view = view
    , update = update
    , inputs =
      [ Keyboard.space |> Signal.map (\s -> if s then NextPage else Nop)
      , Keyboard.enter |> Signal.map (\s -> if s then NextPage else Nop)
      , Keyboard.arrows |> Signal.map
        (\s ->
          case s.x of
            -1 -> PreviousPage
            1 -> NextPage
            _ -> Nop)
      ]
    }

const x _ = x

init : (Model, Effects Action)
init =
  (initialModel, getContent)


initialModel : Model
initialModel =
  { content = ""
  , pages = Array.empty
  , currentPage = 0
  }


type Action
  = Nop
  | SetContent String
  | NextPage
  | PreviousPage


noEffects : a -> (a, Effects b)
noEffects m =
  (m, Effects.none)


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    Nop ->
      noEffects model

    SetContent s ->
      noEffects { model | pages = Array.fromList <| String.split "\n--\n" s }

    NextPage ->
      let
        newPage = model.currentPage + 1
      in
        if newPage < Array.length model.pages
        then noEffects { model | currentPage = newPage }
        else noEffects model

    PreviousPage ->
      let
        newPage = model.currentPage - 1
      in
        if newPage >= 0
        then noEffects { model | currentPage = newPage }
        else noEffects model


view address model =
  Html.div
    [ style
      [ "padding" => "30px"
      , "width" => "80vw"
      , "font-family" => "'Ubuntu'"
      , "font-size" => "1.5vw"
      ]
    ]
    [ Html.node "script" [ src "./highlight/highlight.pack.js" ] []
    , Html.node "link" [ rel "stylesheet", href "http://fonts.googleapis.com/css?family=Ubuntu" ] []
    , Html.node "link" [ rel "stylesheet", href "./highlight/styles/solarized-light.css" ] []
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
          [ "height" => "40vw"
          , "overflow" => "auto"
          ]
        ]
        [ Markdown.toHtml <| Maybe.withDefault "" <| Array.get model.currentPage model.pages ]
      , Html.div -- Footer.
        [ style
          [ "border-top" => "solid black" ]
        ]
        [ Html.a
          [ onClick address PreviousPage
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
          [ onClick address NextPage
          , href "#"
          ]
          [ Html.text ">>>" ]
        ]
      ]
    ]


(=>) : String -> String -> (String, String)
(=>) = (,)
