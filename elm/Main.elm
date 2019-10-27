module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Table


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
    , Cmd RefreshTables
    )



--update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RefreshTables ->
            ( model, getAllTable )

        GotTables result ->
            case result of
                Ok alltable ->
                    ( { model
                        | jatable = alltable.jatable
                        , lotable = alltable.lotable
                        , thtable = alltable.thtable
                        , message = "success to fetch alltable"
                      }
                    , Cmd SetjaTableState
                    )

                Err _ ->
                    ( { model | message = "failed to fetch alltable" }
                    , Cmd.none
                    )

        SetJaTableState newState ->
            ( { model | jaState = newState }
            , Cmd SetLoTableState
            )

        SetLoTableState newState ->
            ( { model | loState = newState }
            , Cmd SetThTableState
            )

        SetThTableState newState ->
            ( { model | thState = newState }
            , Cmd.None
            )



-- view


view : Model -> Html Msg
view model =
    div []
        [ text model.message
        , div []
            [ button [ onClick RefreshTables ] [ text "load table" ] ]
        , Table.view jaconfig model.jaState
        , model.jatable
        , Table.view loconfig model.loState
        , model.loatable
        , Table.view thconfig model.thState
        , model.thtable
        ]


jaconfig : Table.Config Japanese Msg
jaconfig =
    Table.config
        { toId = .id
        , toMsg = SetJaTableState
        , columns =
            [ Table.intColumn "Id" .id
            , Table.stringColumn "Japanese" .japanese
            ]
        }


loconfig : Table.Config Logic Msg
loconfig =
    Table.config
        { toId = .id
        , toMsg = SetLoTableState
        , columns =
            [ Table
            , intColumn "Id" .id
            , Table.intColumn "Jid" .jid
            , Table.stringColumn "Formula" .formula
            , Table.stringColumn "Types" .types
            , Table.intColumn "Good" .good
            ]
        }


thconfig : Table.Config Theorem Msg
thconfig =
    Table.config
        { toId = .id
        , toMsg = SetThTableState
        , columns =
            [ Table.intColumn "Id" .id
            , Table.stringColumn "Premises" .premises
            , Table.intColumn "Conclusion" .conclusion
            , Table.stringColumn "Result" .result
            ]
        }



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
        , subscriptions = \_ -> Sub.none
        , view = view
        }
