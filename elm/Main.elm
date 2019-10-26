module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type alias JapaneseTable =
    { id : List Int
    , japanese : List String
    }


type alias LogicTable =
    { id : List Int
    , jid : List Int
    , formula : List String
    , types : List String
    , good : List Int
    }


type alias TheoremTable =
    { id : List Int
    , premises : List (List Int)
    , conclusion : List Int
    , result : List String
    }


type alias Model =
    { jatable : JapaneseTable
    , lotable : LogicTable
    , thtable : TheoremTable
    }


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


maptable =
    table []
        [ thead []
            [ th [] [ text "Product" ]
            , th [] [ text "Amount" ]
            ]
        , tr []
            [ td [] [ text "Total" ]
            , td [] [ text (String.fromInt 42) ]
            ]
        ]


view : Model -> Html Msg
view model =
    case model of
        Success ->
            div []
                [ text "success!"
                , div []
                    [ button [ onClick FetchTable ] [ text "load table" ] ]
                , maptable
                ]

        Processing ->
            div []
                [ text "processing" ]

        Failure ->
            div []
                [ text "failure" ]



-- http
-- curl -X POST -H 'Accept:application/json' -H 'Content-Type:application/json' -d '{"task": "映画館に行く"}' localhost:5000/tasks


getJapaneseTable =
    [ "id", "ja" ]


getLogicTable =
    [ "id", "logic" ]


getTheoremTable =
    [ "id", "th" ]



-- Main


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
