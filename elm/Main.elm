module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, field, index, int, string)
import Json.Encode as Encode
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
    , formJa : String
    , formLogic : FormLogic
    , formTheorem : FormTheorem
    }


type alias FormLogic =
    { jid : String
    , formula : String
    , types : String
    }


type alias FormTheorem =
    { premises : String
    , conclusion : String
    , result : String
    }


type Msg
    = RefreshTables
    | GotTables (Result Http.Error AllTable)
    | SetJaTableState Table.State
    | SetLoTableState Table.State
    | SetThTableState Table.State
    | RegJapanese String
    | RegLogic FormLogic
    | RegTheorem FormTheorem
    | Registered (Result Http.Error String)
    | UpdateFormJapanese String
    | UpdateFormLogic FormLogic
    | UpdateFormTheorem FormTheorem



--init


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model [] (Table.initialSort "id") [] (Table.initialSort "id") [] (Table.initialSort "id") "" "" initFormLogic initFormTheorem
    , getAllTable
    )


initFormLogic : FormLogic
initFormLogic =
    { jid = "", formula = "", types = "" }


initFormTheorem : FormTheorem
initFormTheorem =
    { premises = "", conclusion = "", result = "" }



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

                Err err ->
                    ( { model | message = "Http.Error:" ++ handleHttpError err }
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

        RegJapanese japanese ->
            ( model
            , registerJapanese japanese
            )

        RegLogic formLogic ->
            ( model
            , registerLogic formLogic
            )

        RegTheorem formTheorem ->
            ( model
            , registerTheorem formTheorem
            )

        Registered result ->
            case result of
                Ok message ->
                    ( { model | message = message }
                    , Cmd.none
                    )

                Err err ->
                    ( { model | message = "Http.Error:" ++ handleHttpError err }
                    , Cmd.none
                    )

        UpdateFormJapanese japanese ->
            ( { model | formJa = japanese }
            , Cmd.none
            )

        UpdateFormLogic formLogic ->
            ( { model | formLogic = formLogic }
            , Cmd.none
            )

        UpdateFormTheorem formTheorem ->
            ( { model | formTheorem = formTheorem }
            , Cmd.none
            )


handleHttpError : Http.Error -> String
handleHttpError httperror =
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



-- view


view : Model -> Html Msg
view model =
    div []
        [ text model.message
        , div []
            [ button [ onClick RefreshTables ] [ text "Refresh tables" ] ]
        , text "RegisterしたらRefresh tablesしてください"
        , viewRegJa model.formJa
        , viewRegLo model.formLogic
        , viewRegTh model.formTheorem
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


viewRegJa : String -> Html Msg
viewRegJa formJa =
    div []
        [ input
            [ type_ "text"
            , placeholder "まずここに日本語を入力"
            , value formJa
            , onInput UpdateFormJapanese
            ]
            []
        , button [ onClick (RegJapanese formJa) ] [ text "Reg Japanese" ]
        ]


viewRegLo : FormLogic -> Html Msg
viewRegLo formLogic =
    div []
        [ input
            [ type_ "text"
            , placeholder "元の日本語のID"
            , value formLogic.jid
            , onInput (\v -> UpdateFormLogic { formLogic | jid = v })
            ]
            []
        , input
            [ type_ "text"
            , placeholder "論理式"
            , value formLogic.formula
            , onInput (\v -> UpdateFormLogic { formLogic | formula = v })
            ]
            []
        , input
            [ type_ "text"
            , placeholder "types"
            , value formLogic.types
            , onInput (\v -> UpdateFormLogic { formLogic | types = v })
            ]
            []
        , button [ onClick (RegLogic formLogic) ] [ text "Reg Logic" ]
        ]


viewRegTh : FormTheorem -> Html Msg
viewRegTh formTheorem =
    div []
        [ input
            [ type_ "text"
            , placeholder "前提のID(id1 & id2 & …)"
            , value formTheorem.premises
            , onInput (\v -> UpdateFormTheorem { formTheorem | premises = v })
            ]
            []
        , input
            [ type_ "text"
            , placeholder "結論のID"
            , value formTheorem.conclusion
            , onInput (\v -> UpdateFormTheorem { formTheorem | conclusion = v })
            ]
            []
        , input
            [ type_ "text"
            , placeholder "含意してる?"
            , value formTheorem.result
            , onInput (\v -> UpdateFormTheorem { formTheorem | result = v })
            ]
            []
        , button [ onClick (RegTheorem formTheorem) ] [ text "Reg Theorem" ]
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


registerJapanese : String -> Cmd Msg
registerJapanese japanese =
    Http.post
        { url = UB.relative [ apiUrl, "reg_ja" ] []
        , body = Http.jsonBody (Encode.object [ ( "japanese", Encode.string japanese ) ])
        , expect = Http.expectJson Registered messageDecoder
        }


registerLogic : FormLogic -> Cmd Msg
registerLogic formLogic =
    Http.post
        { url = UB.relative [ apiUrl, "reg_lo" ] []
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "jid", Encode.int <| stringToInt formLogic.jid )
                    , ( "formula", Encode.string formLogic.formula )
                    , ( "types", Encode.string formLogic.types )
                    ]
        , expect = Http.expectJson Registered messageDecoder
        }


registerTheorem : FormTheorem -> Cmd Msg
registerTheorem formTheorem =
    Http.post
        { url = UB.relative [ apiUrl, "reg_th" ] []
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "premises_id", Encode.string formTheorem.premises )
                    , ( "conclusion_id", Encode.int <| stringToInt formTheorem.conclusion )
                    , ( "result", Encode.string formTheorem.result )
                    ]
        , expect = Http.expectJson Registered messageDecoder
        }


stringToInt : String -> Int
stringToInt str =
    Maybe.withDefault -1 <| String.toInt str


messageDecoder : Decoder String
messageDecoder =
    field "message" string


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
