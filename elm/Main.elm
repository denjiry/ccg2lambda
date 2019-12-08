module Main exposing (main)

import Browser
import Debug
import Dict exposing (Dict)
import Element as El exposing (Element, column, el, explain, fill, height, html, layout, row, width)
import Graph.Tree
import Html exposing (Html, button, div, h4, input, map, text)
import Html.Attributes exposing (placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder, field, index, int, string)
import Json.Encode as Encode
import List.Extra
import Table
import Tree as TvTree
import TreeView as Tv
import Url
import Url.Builder as UB


type alias Japanese =
    { id : Int, japanese : String }


type alias Logic =
    { id : Int, jid : Int, formula : String, types : String, good : Int }


type alias Theorem =
    { id : Int, premises : String, conclusion : Int, result : String }


type alias AllTable =
    { jatable : List Japanese, lotable : List Logic, thtable : List Theorem }


type alias Model =
    { jatable : List Japanese
    , jaState : Table.State
    , lotable : List Logic
    , loState : Table.State
    , thtable : List Theorem
    , thState : Table.State
    , message : String
    , msgRefreshTables : String
    , formJa : String
    , formLogic : FormLogic
    , formTheorem : FormTheorem
    , formTransform : String
    , formTryprove : FormTryprove
    , formGood : FormGood
    , formDelete : FormDelete
    , treeModel : Tv.Model Node String Never ()
    }


type alias FormLogic =
    { jid : String, formula : String, types : String }


type alias FormTheorem =
    { premises : String, conclusion : String, result : String }


type alias FormTryprove =
    { premises : String, conclusion : String }


type alias FormGood =
    { id : String, new_good : String }


type alias FormDelete =
    { table : String, id : String }


type Msg
    = RefreshTables
    | GotTables (Result Http.Error AllTable)
    | SetJaTableState Table.State
    | SetLoTableState Table.State
    | SetThTableState Table.State
    | RegJapanese String
    | RegLogic FormLogic
    | RegTheorem FormTheorem
    | Transform String
    | Tryprove FormTryprove
    | UpdateGood FormGood
    | Delete FormDelete
    | Registered (Result Http.Error String)
    | UpdateFormJapanese String
    | UpdateFormLogic FormLogic
    | UpdateFormTheorem FormTheorem
    | UpdateFormTransform String
    | UpdateFormTryprove FormTryprove
    | UpdateFormGood FormGood
    | UpdateFormDelete FormDelete
    | TreeViewMsg (Tv.Msg String)



--init


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model [] (Table.initialSort "id") [] (Table.initialSort "id") [] (Table.initialSort "id") "" "" "" initFormLogic initFormTheorem "" initFormTryprove initFormGood initFormDelete initialTreeModel
    , getAllTable
    )


initFormLogic : FormLogic
initFormLogic =
    { jid = "", formula = "", types = "" }


initFormTheorem : FormTheorem
initFormTheorem =
    { premises = "", conclusion = "", result = "" }


initFormTryprove : FormTryprove
initFormTryprove =
    { premises = "", conclusion = "" }


initFormGood : FormGood
initFormGood =
    { id = "", new_good = "" }


initFormDelete : FormDelete
initFormDelete =
    { table = "", id = "" }


initialTreeModel : Tv.Model Node String Never ()
initialTreeModel =
    Tv.initializeModel configuration []



--update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RefreshTables ->
            ( { model | msgRefreshTables = "Refreshing..." }, getAllTable )

        GotTables result ->
            case result of
                Ok alltable ->
                    let
                        newmodel =
                            { model
                                | jatable = alltable.jatable
                                , lotable = alltable.lotable
                                , thtable = alltable.thtable
                                , msgRefreshTables = "success to fetch alltable"
                            }

                        rootNodes =
                            buildRootNodes newmodel
                    in
                    ( { newmodel
                        | treeModel = Tv.initializeModel configuration rootNodes
                      }
                    , Cmd.none
                    )

                Err err ->
                    ( { model | msgRefreshTables = "Http.Error:" ++ handleHttpError err }
                    , Cmd.none
                    )

        SetJaTableState newState ->
            ( { model | jaState = newState }, Cmd.none )

        SetLoTableState newState ->
            ( { model | loState = newState }, Cmd.none )

        SetThTableState newState ->
            ( { model | thState = newState }, Cmd.none )

        RegJapanese japanese ->
            ( model, registerJapanese japanese )

        RegLogic formLogic ->
            ( model, registerLogic formLogic )

        RegTheorem formTheorem ->
            ( model, registerTheorem formTheorem )

        Transform formTransform ->
            ( model, transform formTransform )

        Tryprove formTryprove ->
            ( model, tryprove formTryprove )

        UpdateGood formGood ->
            ( model, updateGood formGood )

        Delete formDelete ->
            ( model, delete formDelete )

        Registered result ->
            case result of
                Ok message ->
                    ( { model | message = message }
                    , getAllTable
                    )

                Err err ->
                    ( { model | message = "Http.Error:" ++ handleHttpError err }
                    , Cmd.none
                    )

        UpdateFormJapanese japanese ->
            ( { model | formJa = japanese }, Cmd.none )

        UpdateFormLogic formLogic ->
            ( { model | formLogic = formLogic }, Cmd.none )

        UpdateFormTheorem formTheorem ->
            ( { model | formTheorem = formTheorem }, Cmd.none )

        UpdateFormTransform formTransform ->
            ( { model | formTransform = formTransform }, Cmd.none )

        UpdateFormTryprove formTryprove ->
            ( { model | formTryprove = formTryprove }, Cmd.none )

        UpdateFormGood formGood ->
            ( { model | formGood = formGood }, Cmd.none )

        UpdateFormDelete formDelete ->
            ( { model | formDelete = formDelete }, Cmd.none )

        TreeViewMsg tvMsg ->
            ( { model | treeModel = Tv.update tvMsg model.treeModel }, Cmd.none )


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


view : Model -> Element Msg
view model =
    column []
        [ row []
            [ column []
                [ El.text model.msgRefreshTables
                , html <| button [ onClick RefreshTables ] [ text "Refresh tables" ]
                , El.text <| "Server Response -> " ++ model.message
                , html <| viewRegJa model.formJa
                , html <| viewRegLo model.formLogic
                , html <| viewRegTh model.formTheorem
                , html <| viewTrans model.formTransform
                , html <| viewProve model.formTryprove
                , html <| viewGood model.formGood
                , html <| viewDelete model.formDelete
                ]
            , column []
                [ html <| viewTree model.treeModel model.thtable ]
            ]
        , column
            [ width fill, height fill, El.scrollbarY ]
            [ row [ width fill ]
                [ column []
                    [ El.text "日本語テーブル(japanese)"
                    , html <|
                        Table.view jaconfig
                            model.jaState
                            model.jatable
                    ]
                , column [ height fill ]
                    [ El.text "定理テーブル(theorem)"
                    , html <|
                        Table.view thconfig
                            model.thState
                            model.thtable
                    ]
                ]
            , column [ width fill, El.clip ]
                [ El.text "論理式テーブル(logic)"
                , el [ El.clip ] <|
                    El.html <|
                        Table.view loconfig
                            model.loState
                            model.lotable
                ]
            ]
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


viewTrans : String -> Html Msg
viewTrans formTransform =
    div []
        [ input
            [ type_ "text"
            , placeholder "日本語の ID"
            , value formTransform
            , onInput UpdateFormTransform
            ]
            []
        , button [ onClick <| Transform formTransform ] [ text "日本語 -> 論理式" ]
        ]


viewProve : FormTryprove -> Html Msg
viewProve formTryprove =
    div []
        [ input
            [ type_ "text"
            , placeholder "前提のID(id1 & id2 & …)"
            , value formTryprove.premises
            , onInput (\v -> UpdateFormTryprove { formTryprove | premises = v })
            ]
            []
        , input
            [ type_ "text"
            , placeholder "結論のID"
            , value formTryprove.conclusion
            , onInput (\v -> UpdateFormTryprove { formTryprove | conclusion = v })
            ]
            []
        , button [ onClick <| Tryprove formTryprove ] [ text "含意関係認識" ]
        ]


viewGood : FormGood -> Html Msg
viewGood formGood =
    div []
        [ input
            [ type_ "text"
            , placeholder "論理式のID"
            , value formGood.id
            , onInput (\v -> UpdateFormGood { formGood | id = v })
            ]
            []
        , input
            [ type_ "text"
            , placeholder "良さの度合い（数字）"
            , value formGood.new_good
            , onInput (\v -> UpdateFormGood { formGood | new_good = v })
            ]
            []
        , button [ onClick <| UpdateGood formGood ] [ text "Update Good" ]
        ]


viewDelete : FormDelete -> Html Msg
viewDelete formDelete =
    div []
        [ input
            [ type_ "text"
            , placeholder "tableの名前"
            , value formDelete.table
            , onInput (\v -> UpdateFormDelete { formDelete | table = v })
            ]
            []
        , input
            [ type_ "text"
            , placeholder "消したいID"
            , value formDelete.id
            , onInput (\v -> UpdateFormDelete { formDelete | id = v })
            ]
            []
        , button [ onClick <| Delete formDelete ] [ text "Delete a row" ]
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
            , Table.stringColumn "Formula" (\l -> prettifyFormula l.formula)
            , Table.intColumn "Good" .good
            ]
        }


lotoid : Logic -> String
lotoid lo =
    String.fromInt lo.id


prettifyFormula : String -> String
prettifyFormula formula =
    let
        replaceList =
            [ ( "exists", "∃" )
            , ( "all", "∀" )
            , ( "True & ", "" )
            , ( " & True", "" )
            ]
    in
    List.foldl uncurriedReplace formula replaceList


uncurriedReplace : ( String, String ) -> String -> String
uncurriedReplace ( a, b ) c =
    String.replace a b c


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


transform : String -> Cmd Msg
transform formTransform =
    Http.post
        { url = UB.relative [ apiUrl, "transform" ] []
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "jid", Encode.int <| stringToInt formTransform )
                    ]
        , expect = Http.expectJson Registered messageDecoder
        }


tryprove : FormTryprove -> Cmd Msg
tryprove formTryprove =
    Http.post
        { url = UB.relative [ apiUrl, "try_prove" ] []
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "premises_id", Encode.string formTryprove.premises )
                    , ( "conclusion_id", Encode.int <| stringToInt formTryprove.conclusion )
                    ]
        , expect = Http.expectJson Registered messageDecoder
        }


updateGood : FormGood -> Cmd Msg
updateGood formGood =
    Http.post
        { url = UB.relative [ apiUrl, "update_good" ] []
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "id", Encode.int <| stringToInt formGood.id )
                    , ( "new_good", Encode.int <| stringToInt formGood.new_good )
                    ]
        , expect = Http.expectJson Registered messageDecoder
        }


delete : FormDelete -> Cmd Msg
delete formDelete =
    Http.post
        { url = UB.relative [ apiUrl, "delete" ] []
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "table", Encode.string formDelete.table )
                    , ( "id", Encode.int <| stringToInt formDelete.id )
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



-- Tree


type alias Node =
    { uid : String
    , ja : String
    , lo : String
    }


configuration : Tv.Configuration Node String
configuration =
    Tv.Configuration nodeUid nodeLabel Tv.defaultCssClasses


viewTree : Tv.Model Node String Never () -> List Theorem -> Html Msg
viewTree treeModel thtable =
    div []
        [ map TreeViewMsg <| Tv.view treeModel ]


nodeLabel : TvTree.Node Node -> String
nodeLabel n =
    case n of
        TvTree.Node node ->
            node.data.ja ++ "|> " ++ node.data.lo


nodeUid : TvTree.Node Node -> Tv.NodeUid String
nodeUid n =
    case n of
        TvTree.Node node ->
            -- if duplication occur, please use children's uid
            Tv.NodeUid node.data.uid


buildRootNodes : Model -> List (TvTree.Node Node)
buildRootNodes model =
    let
        convert =
            convertGraphTreeToTvTree model
    in
    List.map convert <| buildForest model.thtable


convertGraphTreeToTvTree : Model -> Graph.Tree.Tree Int -> TvTree.Node Node
convertGraphTreeToTvTree model gtree =
    let
        createNode id =
            createNodeFromTables model.jatable model.lotable id
    in
    case Graph.Tree.root gtree of
        Nothing ->
            TvTree.Node { data = { uid = "", ja = "", lo = "" }, children = [] }

        Just ( label, [] ) ->
            TvTree.Node { data = createNode label, children = [] }

        Just ( label, childForest ) ->
            TvTree.Node
                { data = createNode label
                , children = List.map (\gt -> convertGraphTreeToTvTree model gt) childForest
                }


createNodeFromTables : List Japanese -> List Logic -> Int -> Node
createNodeFromTables jatable lotable i =
    let
        logic =
            case List.Extra.find (\l -> i == l.id) lotable of
                Just l ->
                    l

                Nothing ->
                    Logic 0 0 "" "" 0

        japanese =
            case List.Extra.find (\j -> logic.jid == j.id) jatable of
                Just j ->
                    j

                Nothing ->
                    Japanese 0 ""
    in
    { uid = String.fromInt i, ja = japanese.japanese, lo = logic.formula }


buildForest : List Theorem -> List (Graph.Tree.Tree Int)
buildForest thtable =
    let
        roots =
            findRoot thtable

        dthtable =
            dictThTable thtable
    in
    List.map (\r -> Graph.Tree.unfoldTree (unfolder dthtable) r) roots


unfolder : Dict Int (List Int) -> Int -> ( Int, List Int )
unfolder dthtable seed =
    case Dict.get seed dthtable of
        Just premises ->
            ( seed, premises )

        Nothing ->
            ( seed, [] )


dictThTable : List Theorem -> Dict Int (List Int)
dictThTable thtable =
    let
        extract th =
            ( th.conclusion, toListInt th.premises )
    in
    Dict.fromList <| List.map extract thtable


findRoot : List Theorem -> List Int
findRoot thtable =
    let
        allleaf =
            List.foldl (\th l -> toListInt th.premises ++ l) [] thtable
    in
    List.filter (\v -> not <| List.member v.conclusion allleaf) thtable
        |> List.map (\th -> th.conclusion)


toListInt : String -> List Int
toListInt str =
    let
        splitList =
            List.map String.trim <|
                List.filter ((/=) "") <|
                    String.split "&" str
    in
    List.map (\s -> Maybe.withDefault -1 <| String.toInt s) splitList



-- Main


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = \m -> layout [] <| view m
        }
