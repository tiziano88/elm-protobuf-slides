import Array exposing (Array)
import Effects exposing (Effects)
import Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
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
    , inputs = []
    }


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
      noEffects { model | currentPage = model.currentPage + 1 }

    PreviousPage ->
      noEffects { model | currentPage = model.currentPage - 1 }


view address model =
  Html.div
    [ style
      [ "background-color" => "black"
      , "padding" => "30px"
      ]
    ]
    [ Html.node "script" [ src "/highlight/highlight.pack.js" ] []
    , Html.node "link" [ rel "stylesheet", href "/highlight/styles/solarized-light.css" ] []
    , Html.div
      [ style
        [ "background-color" => "white"
        , "width" => "600px"
        , "padding" => "30px 40px"
        ]
      ]
      [ Html.div -- Content.
        [ style
          [ "height" => "400px" ]
        ]
        [ Markdown.toHtml <| Maybe.withDefault "" <| Array.get model.currentPage model.pages ]
      , Html.div [] -- Footer.
        [ Html.a
          [ onClick address PreviousPage ]
          [ Html.text "<<<" ]
        , Html.text (toString model.currentPage)
        , Html.a
          [ onClick address NextPage ]
          [ Html.text ">>>" ]
        ]
      ]
    ]


(=>) : String -> String -> (String, String)
(=>) = (,)
