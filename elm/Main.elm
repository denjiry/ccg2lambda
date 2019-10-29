module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, field, index, int, string)
import Table
import Url
import Url.Builder as UB


type alias Japanese =
    { id : Int
    , japanese : String
    }


type alias Logic =
    { id : Int
    , jid : Int
    , formula : String
    , types : String
    , good : Int
    }


type alias Theorem =
    { id : Int
    , premises : String
    , conclusion : Int
    , result : String
    }


type alias AllTable =
    { jatable : List Japanese
    , lotable : List Logic
    , thtable : List Theorem
    }


type alias Model =
    { jatable : List Japanese
    , jaState : Table.State
    , lotable : List Logic
    , loState : Table.State
    , thtable : List Theorem
    , thState : Table.State
    , message : String
    }


type Msg
    = RefreshTables
    | GotTables (Result Http.Error AllTable)
    | SetJaTableState Table.State
    | SetLoTableState Table.State
    | SetThTableState Table.State



--init


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model [] (Table.initialSort "id") [] (Table.initialSort "id") [] (Table.initialSort "id") ""
    , getAllTable
    )



--update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RefreshTables ->
            ( { model | message = "Refreshing..." }, getAllTable )

        GotTables result ->
            case result of
                Ok alltable ->
                    ( { model
                        | jatable = alltable.jatable
                        , lotable = alltable.lotable
                        , thtable = alltable.thtable
                        , message = "success to fetch alltable"
                      }
                    , Cmd.none
                    )

                Err httperror ->
                    let
                        retmessage =
                            case httperror of
                                Http.BadUrl str ->
                                    "BadUrl:" ++ str

                                Http.Timeout ->
                                    "Timeout"

                                Http.NetworkError ->
                                    "NetworkError"

                                Http.BadStatus code ->
                                    "BadStatus:" ++ String.fromInt code

                                Http.BadBody str ->
                                    "BadBody:" ++ str
                    in
                    ( { model | message = "Http.Error:" ++ retmessage }
                    , Cmd.none
                    )

        SetJaTableState newState ->
            ( { model | jaState = newState }
            , Cmd.none
            )

        SetLoTableState newState ->
            ( { model | loState = newState }
            , Cmd.none
            )

        SetThTableState newState ->
            ( { model | thState = newState }
            , Cmd.none
            )



-- view


view : Model -> Html Msg
view model =
    div []
        [ text model.message
        , div []
            [ button [ onClick RefreshTables ] [ text "load table" ] ]
        , Table.view jaconfig
            model.jaState
            model.jatable
        , Table.view thconfig
            model.thState
            model.thtable
        , Table.view loconfig
            model.loState
            model.lotable
        ]


jaconfig : Table.Config Japanese Msg
jaconfig =
    Table.config
        { toId = jatoid
        , toMsg = SetJaTableState
        , columns =
            [ Table.intColumn "Id" .id
            , Table.stringColumn "Japanese" .japanese
            ]
        }


jatoid : Japanese -> String
jatoid ja =
    String.fromInt ja.id


loconfig : Table.Config Logic Msg
loconfig =
    Table.config
        { toId = lotoid
        , toMsg = SetLoTableState
        , columns =
            [ Table.intColumn "Id" .id
            , Table.intColumn "Jid" .jid
            , Table.stringColumn "Formula" .formula
            , Table.stringColumn "Types" .types
            , Table.intColumn "Good" .good
            ]
        }


lotoid : Logic -> String
lotoid lo =
    String.fromInt lo.id


thconfig : Table.Config Theorem Msg
thconfig =
    Table.config
        { toId = thtoid
        , toMsg = SetThTableState
        , columns =
            [ Table.intColumn "Id" .id
            , Table.stringColumn "Premises" .premises
            , Table.intColumn "Conclusion" .conclusion
            , Table.stringColumn "Result" .result
            ]
        }


thtoid : Theorem -> String
thtoid th =
    String.fromInt th.id



-- http
-- curl -X POST -H 'Accept:application/json' -H 'Content-Type:application/json' -d '{"task": "映画館に行く"}' localhost:5000/tasks


apiUrl : String
apiUrl =
    "http://localhost:9999/api"


getAllTable : Cmd Msg
getAllTable =
    Http.get
        { url = UB.relative [ apiUrl, "alltable" ] []
        , expect = Http.expectJson GotTables tableDecoder
        }


tableDecoder : Decoder AllTable
tableDecoder =
    Decode.map3 AllTable
        (field "jatable" jatableDecoder)
        (field "lotable" lotableDecoder)
        (field "thtable" thtableDecoder)


jatableDecoder : Decoder (List Japanese)
jatableDecoder =
    Decode.list
        (Decode.map2
            Japanese
            (index 0 int)
            (index 1 string)
        )


lotableDecoder : Decoder (List Logic)
lotableDecoder =
    Decode.list
        (Decode.map5
            Logic
            (index 0 int)
            (index 1 int)
            (index 2 string)
            (index 3 string)
            (index 4 int)
        )


thtableDecoder : Decoder (List Theorem)
thtableDecoder =
    Decode.list
        (Decode.map4
            Theorem
            (index 0 int)
            (index 1 string)
            (index 2 int)
            (index 3 string)
        )



-- Main


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
