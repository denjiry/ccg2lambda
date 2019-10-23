module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type Model
    = Failure
    | Processing
    | Success


type Msg
    = FetchTable



--init


init : () -> ( Model, Cmd Msg )
init _ =
    ( Success, Cmd.none )



--update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchTable ->
            ( Processing, Cmd.none )



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
                [ text "success!"
                , button [ onClick FetchTable ] [ text "load table" ]
                ]

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
