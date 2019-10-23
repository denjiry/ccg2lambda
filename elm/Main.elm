module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)


type Model
    = Failure
    | Processing
    | Success


type Msg
    = FetchTable



--init


init : () -> ( Model, Cmd Msg )
init _ =
    ( Success, Cmd.None )



--update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchTable ->
            ( Success, Cmd.none )



-- subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- view


view : Model -> Html Msg
view model =
    case model of
        Success ->
            div []
                [ text "success" ]

        Processing ->
            div []
                [ text "processing" ]

        Failure ->
            div []
                [ text "failure" ]



-- Main


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
