import Array exposing (Array)
import Effects exposing (Effects)
import History
import Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Keyboard
import Location
import Markdown
import StartApp
import String
import Task exposing (Task)
import Window


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
  , size : (Int, Int)
  }


url = "./slides.md"


getContent : Effects Action
getContent =
  Http.getString url
    |> Task.toMaybe
    |> Task.map (Maybe.withDefault "")
    |> Task.map SetContent
    |> Effects.task


getLocation : Effects Action
getLocation =
  Location.location
    |> Task.map (\l -> l.hash)
    |> Task.map (String.dropLeft 1)
    |> Task.map String.toInt
    |> Task.map (Result.withDefault 1)
    |> Task.map (\x -> x - 1)
    |> Task.map SetCurrentPage
    |> Effects.task


app =
  StartApp.start
    { init = init
    , view = view
    , update = update
    , inputs =
      [ Window.dimensions |> Signal.map Resize
      , Keyboard.space |> Signal.map (\s -> if s then NextPage else Nop)
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
  (initialModel, Effects.batch [ getContent, getLocation ])


initialModel : Model
initialModel =
  { content = ""
  , pages = Array.empty
  , currentPage = 0
  , size = (0,0)
  }


type Action
  = Nop
  | SetContent String
  | SetCurrentPage Int
  | NextPage
  | PreviousPage
  | Resize (Int, Int)


noEffects : a -> (a, Effects b)
noEffects m =
  (m, Effects.none)


updateHash : Model -> (Model, Effects Action)
updateHash m =
  ( m
  , History.replacePath ("#" ++ toString (m.currentPage + 1))
    |> Task.map (\x -> Nop)
    |> Effects.task
  )


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
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

view address model =
  Html.div
    [ style
      [ "padding" => "1em"
      , "margin" => "auto"
      , "width" => "40em"
      , "font-family" => "'Ubuntu'"
      , "font-size" =>
        let
          (x,y) = model.size
        in
          if (toFloat x)/(toFloat y) < ratio then "2vw" else "3vh"
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
          [ "height" => "25em"
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
