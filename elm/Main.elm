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
    , formTheorem : FormTheorem
    , formTryprove : FormTryprove
    , formGood : FormGood
    , formDelete : FormDelete
    , treeModel : Tv.Model Node String Never ()
    , hideDetailForm : Bool
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
    | RegTheorem FormTheorem
    | Tryprove FormTryprove
    | UpdateGood FormGood
    | Delete FormDelete
    | Registered (Result Http.Error String)
    | UpdateFormJapanese String
    | UpdateFormTheorem FormTheorem
    | UpdateFormTryprove FormTryprove
    | UpdateFormGood FormGood
    | UpdateFormDelete FormDelete
    | TreeViewMsg (Tv.Msg String)
    | ToggleHideDetail



--init


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model [] (Table.initialSort "id") [] (Table.initialSort "id") [] (Table.initialSort "id") "" "" "" initFormTheorem initFormTryprove initFormGood initFormDelete initialTreeModel True
    , getAllTable
    )


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

        RegTheorem formTheorem ->
            ( model, registerTheorem formTheorem )

        Tryprove formTryprove ->
            ( model, tryprove formTryprove )

        UpdateGood formGood ->
            ( model, updateGood formGood )

        Delete formDelete ->
            ( model, delete formDelete )

        Registered result ->
            registeredHelper model result

        UpdateFormJapanese japanese ->
            ( { model | formJa = japanese }, Cmd.none )

        UpdateFormTheorem formTheorem ->
            ( { model | formTheorem = formTheorem }, Cmd.none )

        UpdateFormTryprove formTryprove ->
            ( { model | formTryprove = formTryprove }, Cmd.none )

        UpdateFormGood formGood ->
            ( { model | formGood = formGood }, Cmd.none )

        UpdateFormDelete formDelete ->
            ( { model | formDelete = formDelete }, Cmd.none )

        TreeViewMsg tvMsg ->
            ( { model | treeModel = Tv.update tvMsg model.treeModel }, Cmd.none )

        ToggleHideDetail ->
            ( { model | hideDetailForm = not model.hideDetailForm }, Cmd.none )


registeredHelper : Model -> Result Http.Error String -> ( Model, Cmd Msg )
registeredHelper model result =
    case result of
        Ok message ->
            ( { model | message = message }
            , getAllTable
            )

        Err err ->
            ( { model | message = "Http.Error:" ++ handleHttpError err }
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


view : Model -> Element Msg
view model =
    column []
        [ row []
            [ column []
                [ El.text model.msgRefreshTables
                , html <| button [ onClick RefreshTables ] [ text "Refresh tables" ]
                , html <|
                    button [ onClick ToggleHideDetail ]
                        [ text <|
                            if model.hideDetailForm then
                                "expand forms"

                            else
                                "hide detail"
                        ]
                , El.text <| "Server Response -> " ++ model.message
                , html <| viewRegJa model.formJa
                , if model.hideDetailForm then
                    El.text ""

                  else
                    html <| viewRegTh model.formTheorem
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
        , button [ onClick (RegJapanese formJa) ] [ text "日本語 -> 論理式" ]
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
    { uid : Int
    , ja : String
    , lo : String
    , result : String
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
            let
                prefix =
                    if node.data.result == "proved" then
                        ""

                    else
                        "[" ++ node.data.result ++ "]"
            in
            prefix ++ node.data.ja ++ "|> " ++ prettifyFormula node.data.lo


nodeUid : TvTree.Node Node -> Tv.NodeUid String
nodeUid n =
    case n of
        TvTree.Node node ->
            let
                uidString node_ =
                    String.fromInt <| node_.uid

                childrenUid =
                    List.map (\child -> uidString <| TvTree.dataOf child) node.children
            in
            Tv.NodeUid <| uidString node.data ++ "_" ++ String.concat childrenUid


buildRootNodes : Model -> List (TvTree.Node Node)
buildRootNodes model =
    let
        convert =
            convertGraphTreeToTvTree model
    in
    List.map convert <| buildForest model.thtable


convertGraphTreeToTvTree : Model -> Graph.Tree.Tree Theorem -> TvTree.Node Node
convertGraphTreeToTvTree model gtree =
    let
        leafPrefix =
            "認"

        createNode id result =
            createNodeFromTables model.jatable model.lotable id result

        createLeaf premise =
            TvTree.Node { data = createNode premise leafPrefix, children = [] }
    in
    case Graph.Tree.root gtree of
        Nothing ->
            TvTree.Node { data = { uid = 0, ja = "", lo = "", result = "" }, children = [] }

        Just ( label, [] ) ->
            TvTree.Node
                { data = createNode label.conclusion label.result
                , children = List.map createLeaf <| toListInt label.premises
                }

        Just ( label, childForest ) ->
            let
                branchChildren =
                    List.map (\gt -> convertGraphTreeToTvTree model gt) childForest

                uidOfBranchChildren =
                    List.map (.uid << TvTree.dataOf) branchChildren

                leafs =
                    toListInt label.premises
                        |> List.filter (\p -> not <| List.member p uidOfBranchChildren)
                        |> List.map (\p -> createNode p leafPrefix)
                        |> List.map
                            (\node ->
                                TvTree.Node
                                    { data = node, children = [] }
                            )
            in
            TvTree.Node
                { data = createNode label.conclusion label.result
                , children = branchChildren ++ leafs
                }


createNodeFromTables : List Japanese -> List Logic -> Int -> String -> Node
createNodeFromTables jatable lotable i result =
    let
        logic =
            case List.Extra.find (\l -> i == l.id) lotable of
                Just l ->
                    l

                Nothing ->
                    Logic 0 0 ("Not found:" ++ String.fromInt i) "" 0

        japanese =
            case List.Extra.find (\j -> logic.jid == j.id) jatable of
                Just j ->
                    j

                Nothing ->
                    Japanese 0 ("Not found:" ++ String.fromInt i)
    in
    { uid = i, ja = japanese.japanese, lo = logic.formula, result = result }


buildForest : List Theorem -> List (Graph.Tree.Tree Theorem)
buildForest thtable =
    let
        roots =
            findRoot thtable
    in
    List.map (\r -> Graph.Tree.unfoldTree (unfolder thtable) r) roots


unfolder : List Theorem -> Theorem -> ( Theorem, List Theorem )
unfolder thtable seed =
    let
        premisesNumbers =
            toListInt seed.premises
    in
    ( seed, List.filter (\th -> List.member th.conclusion premisesNumbers) thtable )


findRoot : List Theorem -> List Theorem
findRoot thtable =
    let
        allleaf =
            List.foldl (\th l -> toListInt th.premises ++ l) [] thtable
    in
    List.filter (\v -> not <| List.member v.conclusion allleaf) thtable


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
