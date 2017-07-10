module Polls.View exposing (index, new, show)

import Dict
import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Events
import Html.Lazy as Z
import Maybe.Extra as ME exposing (isNothing)
import List.Extra as LE
import Bootstrap.Button as Button
import Utils exposing (ite)
import Grasp
import Grasp.BooleanResponder as GBR exposing (BooleanResponder, Predicate(..))
import Grasp.StringResponder as GSR exposing (StringResponder, StringMaker(..))
import Repo exposing (Repo, Entity, EntityId, EntityDict, Audit, AuditId, AuditEntry(..))
import Repo.Messages exposing (Msg(..))
import Repo.ViewParts exposing (navigate, submitButton, textInputRequired)
import Polls exposing (Poll, Aux, Condition, Material)
import Actions exposing (Action)
import Actions.ViewParts
import Authentications exposing (Authentication)
import Authentications.ViewParts exposing (authSelect)
import Styles
import ViewParts exposing (none, stdBtn)


-- Index


index : Repo Aux Poll -> Html Polls.Msg
index { dict, sort } =
    -- Must Html.map on subcomponent's call; Workaround for possibly https://github.com/elm-lang/html/issues/119
    dict
        |> Repo.dictToSortedList sort
        |> List.map (Z.lazy card >> Html.map Polls.RepoMsg)
        |> (::) (createCard |> Html.map Polls.RepoMsg)
        |> List.map (List.singleton >> Html.div [ class "col-lg-3 col-md-4 col-sm-6 my-2" ])
        |> Html.div [ class "row" ]


card : Entity Poll -> Html (Msg Poll)
card { id, updatedAt, data } =
    let
        ( titleClass, titleText ) =
            ite data.isEnabled ( "bg-success", "Enabled" ) ( "bg-faded", "Disabled" )
    in
        Html.div
            (List.append
                (navigate ("/polls/" ++ id))
                [ class "card text-center btn-secondary"
                , Styles.fakeLink
                ]
            )
            [ Html.div [ class "card-header" ] [ Html.h4 [] [ text (Utils.shortenUrl data.url) ] ]
            , Html.div [ class ("card-block " ++ titleClass) ]
                [ Html.h4 [ class "card-title" ] [ text titleText ]
                , Html.p [ class "card-text" ] [ text ("Run: " ++ (Polls.intervalToString data.interval)) ]
                ]
            , Html.div [ class "card-footer" ]
                [ Html.small [ Styles.xSmall ]
                    [ text "Last run at: "
                    , text (data.lastRunAt |> ME.unwrap "(Not yet)" Utils.timestampToString)
                    ]
                ]
            ]


createCard : Html (Msg Poll)
createCard =
    Html.div [ class "card text-center h-100" ]
        [ Html.div [ class "card-header" ] [ Html.h4 [] [ text "New Poll" ] ]
        , Html.div [ class "card-block" ] [ stdBtn Button.primary [ Button.attrs (navigate "/polls/new") ] False "Create" ]
        , Html.div [ class "card-footer" ] []
        ]



-- New


new : EntityDict Action -> EntityDict Authentication -> Repo Aux Poll -> Html Polls.Msg
new actionDict authDict ({ dirtyDict } as repo) =
    let
        (( { data }, audit ) as dirtyEntity) =
            Repo.dirtyGetWithDefault "new" Polls.dummyPoll dirtyDict
    in
        ViewParts.triPaneView
            [ Z.lazy titleNew data ]
            [ Z.lazy3 mainFormNew actionDict authDict dirtyEntity ]
            [ none ]
            [ text "right" ]
            |> Html.map Polls.RepoMsg


titleNew : Poll -> Html (Msg Poll)
titleNew data =
    Html.div
        [ class "d-flex justify-content-between align-items-center pb-2"
        , Styles.bottomBordered
        ]
        [ Html.div []
            [ Html.h2 [ class "mb-2" ]
                [ ViewParts.fa [ class "align-bottom mr-2" ] 2 "fa-calendar"
                , text "New Poll"
                ]
            ]
        , Html.div []
            [ stdBtn Button.info
                [ Button.small, Button.onClick (CancelEdit "new") ]
                (data == Polls.dummyPoll)
                "Reset"
            ]
        ]


mainFormNew : EntityDict Action -> EntityDict Authentication -> ( Entity Poll, Audit ) -> Html (Msg Poll)
mainFormNew actionDict authDict (( { data }, audit ) as dirtyEntity) =
    let
        isValid =
            Polls.isValid dirtyEntity
    in
        [ submitButton "poll" isValid "Create" ]
            |> (++) (mainFormInputs actionDict authDict "new" audit data)
            |> Html.form [ Attr.id "poll", Html.Events.onSubmit (ite isValid (Create "new" data) NoOp) ]
            |> ViewParts.cardBlock [] "" Nothing


mainFormInputs : EntityDict Action -> EntityDict Authentication -> EntityId -> Audit -> Poll -> List (Html (Msg Poll))
mainFormInputs actionDict authDict dirtyId audit ({ url, interval, authId, isEnabled, triggers } as data) =
    [ textInputRequired "poll" "URL" False audit dirtyId [ "url" ] (\x -> { data | url = x }) url
    , authSelect "poll" "Credential" (Authentications.listForHttp authDict) dirtyId data authId
    , Polls.intervals |> intervalSelectItems interval |> select "Interval" dirtyId (\x -> { data | interval = x })
    , Repo.ViewParts.checkbox "poll" "Enabled?" False dirtyId (\c -> { data | isEnabled = c }) isEnabled
    , triggerEditor actionDict dirtyId audit data
    ]


intervalSelectItems : Polls.Interval -> List Polls.Interval -> List Repo.ViewParts.SelectItem
intervalSelectItems currentInterval intervals =
    List.map (\x -> ( x, Polls.intervalToString x, currentInterval == x )) intervals


triggerEditor : EntityDict Action -> EntityId -> Audit -> Poll -> Html (Msg Poll)
triggerEditor actionDict dirtyId audit ({ triggers } as data) =
    let
        updateTriggers updateFun =
            { data | triggers = updateFun triggers }

        tsLen =
            List.length triggers

        auditIdsToData auditIds =
            case auditIds of
                [ a1, a2 ] ->
                    { data | triggers = ((Polls.dummyTrigger a1 a2) :: triggers) }

                _ ->
                    -- Should not happen
                    { data | triggers = ((Polls.dummyTrigger "t" "c") :: triggers) }
    in
        Html.div []
            [ Html.label [ class "mr-1" ] [ text "Triggers" ]
            , ViewParts.htmlIf (tsLen < 5) (addButton False dirtyId auditIdsToData 2)
            , triggers
                |> List.indexedMap (triggerForm actionDict tsLen dirtyId audit updateTriggers)
                |> Html.div [ class "container-fluid" ]
            ]


triggerForm :
    EntityDict Action
    -> Int
    -> EntityId
    -> Audit
    -> ((List Polls.Trigger -> List Polls.Trigger) -> Poll)
    -> Int
    -> Polls.Trigger
    -> Html (Msg Poll)
triggerForm actionDict tsLen dirtyId audit tsUpdate index ({ auditId, collapsed, actionId } as trigger) =
    let
        updateTriggerAtIndex updateFun =
            tsUpdate (LE.updateIfIndex ((==) index) updateFun)
    in
        Html.div [ class "row my-1" ]
            [ Html.div [ class "col-md-2 px-0 text-left" ]
                [ removeButton False dirtyId [ auditId ] (tsUpdate (LE.removeAt index))
                , toggleCollapseButton dirtyId (updateTriggerAtIndex (always { trigger | collapsed = not collapsed })) collapsed
                ]
            , Html.div [ class "col-md-8 px-0" ]
                [ triggerActionSelect actionDict dirtyId audit auditId updateTriggerAtIndex trigger
                ]
            , Html.div [ class "col-md-2 px-0 text-right" ]
                [ shuffleButton (index == tsLen - 1) dirtyId (tsUpdate (Utils.listShuffle index True)) True
                , shuffleButton (index == 0) dirtyId (tsUpdate (Utils.listShuffle index False)) False
                ]
            , ViewParts.htmlIf (not collapsed)
                (triggerDetailForm (Dict.get actionId actionDict) audit dirtyId updateTriggerAtIndex index trigger)
            ]


triggerActionSelect :
    EntityDict Action
    -> EntityId
    -> Audit
    -> AuditId
    -> ((Polls.Trigger -> Polls.Trigger) -> Poll)
    -> Polls.Trigger
    -> Html (Msg Poll)
triggerActionSelect actionDict dirtyId audit triggerAuditId tUpdate ({ actionId } as trigger) =
    let
        actionSelectItems =
            actionDict |> Dict.toList |> List.map (\( id, a ) -> ( id, a.data.label, id == actionId ))

        onActionSelect id =
            tUpdate (always { trigger | actionId = id, material = Dict.empty })

        auxEvents maybeSelectedValue =
            [ Html.Events.onBlur
                (OnValidate dirtyId
                    ( [ triggerAuditId, "action" ]
                    , maybeSelectedValue
                        |> isNothing
                        |> Utils.boolToMaybe "This field is required"
                    )
                )
            , Html.Events.onInput
                (\id ->
                    if (id == actionId) then
                        NoOp
                    else
                        OnEdit dirtyId
                            [ ( [ triggerAuditId, "material" ], Nothing )
                            , ( [ triggerAuditId ], Nothing )
                            ]
                            (onActionSelect id)
                )
            ]
    in
        Repo.ViewParts.selectWithAttrs auxEvents
            audit
            [ triggerAuditId, "action" ]
            "poll"
            "Trigger Action"
            True
            dirtyId
            onActionSelect
            actionSelectItems


shuffleButton : Bool -> EntityId -> Poll -> Bool -> Html (Msg Poll)
shuffleButton disabled dirtyId updatedData isAsc =
    -- Note: On UI, index is ascending toward BOTTOM
    smInlineFaBtn [ Button.info ]
        (OnEditValid dirtyId updatedData)
        disabled
        (ite isAsc "fa-caret-down" "fa-caret-up")


addButton : Bool -> EntityId -> (List AuditId -> Poll) -> Int -> Html (Msg Poll)
addButton disabled dirtyId auditIdsToData requiredIdCount =
    smInlineFaBtn [ Button.success ] (GenAuditIds requiredIdCount (auditIdsToData >> OnEditValid dirtyId)) disabled "fa-plus"


removeButton : Bool -> EntityId -> List AuditId -> Poll -> Html (Msg Poll)
removeButton disabled dirtyId auditIdPath updatedData =
    smInlineFaBtn [ Button.danger ] (OnEdit dirtyId [ ( auditIdPath, Nothing ) ] updatedData) disabled "fa-times"


toggleCollapseButton : EntityId -> Poll -> Bool -> Html (Msg Poll)
toggleCollapseButton dirtyId updatedData collapsed =
    smInlineFaBtn [ Button.secondary, Button.attrs [ class "border-0" ] ]
        (OnEditValid dirtyId updatedData)
        False
        (ite collapsed "fa-plus-square-o" "fa-minus-square")


triggerDetailForm :
    Maybe (Entity Action)
    -> Audit
    -> EntityId
    -> ((Polls.Trigger -> Polls.Trigger) -> Poll)
    -> Int
    -> Polls.Trigger
    -> Html (Msg Poll)
triggerDetailForm maybeActionEntity audit dirtyId tUpdate index ({ auditId, conditions, material } as trigger) =
    let
        updateConditions updateFun =
            tUpdate (always { trigger | conditions = updateFun conditions })

        updateMaterial updateFun =
            tUpdate (always { trigger | material = updateFun material })
    in
        Html.div [ class "col-md-12 px-0 card m-1" ]
            [ Html.div [ class "card-block p-1" ]
                [ conditionsCard audit auditId dirtyId updateConditions conditions
                ]
            , maybeActionEntity
                |> ViewParts.htmlMaybe
                    (materialCard audit auditId dirtyId updateMaterial material)
            , maybeActionEntity
                |> ViewParts.htmlMaybe
                    (.data >> Actions.ViewParts.preview >> List.singleton >> Html.div [ class "card-footer p-1" ])
            ]



-- Condition Form


conditionsCard : Audit -> AuditId -> EntityId -> ((List Condition -> List Condition) -> Poll) -> List Condition -> Html (Msg Poll)
conditionsCard audit triggerAuditId dirtyId csUpdate conditions =
    let
        auditIdsToData auditIds =
            case auditIds of
                [ a1 ] ->
                    csUpdate ((::) (Polls.simpleMatchCondition a1 ""))

                _ ->
                    -- Should not happen
                    csUpdate ((::) (Polls.simpleMatchCondition "c" ""))
    in
        Html.div [ class "container-fluid" ]
            [ Html.div [ class "row my-1" ]
                [ Html.div [ class "col-md-12 col-xl-3 px-0" ]
                    [ Html.label [ class "m-1" ] [ text "Conditions" ]
                    , addButton (List.length conditions >= 5) dirtyId auditIdsToData 1
                    ]
                , Html.div [ class "col-md-12 col-xl-9 px-0" ]
                    [ conditions
                        |> List.indexedMap (conditionForm audit triggerAuditId dirtyId csUpdate)
                        |> Html.div [ class "container-fluid" ]
                    ]
                ]
            ]


conditionForm :
    Audit
    -> AuditId
    -> EntityId
    -> ((List Condition -> List Condition) -> Poll)
    -> Int
    -> Condition
    -> Html (Msg Poll)
conditionForm audit triggerAuditId dirtyId csUpdate cIndex ({ auditId, extractor, responder } as c) =
    let
        conditionSelectItems =
            [ ( "simpleMatch", "Simple Match", Polls.isSimpleMatch c )
            , ( "functional", "Functional Scan", not (Polls.isSimpleMatch c) )
            ]

        updateCondition updateFun =
            csUpdate (LE.updateIfIndex ((==) cIndex) updateFun)

        onConditionModeSelect val =
            ite (val == "simpleMatch")
                (Polls.simpleMatchCondition auditId extractor.pattern)
                (Polls.sampleFunctionalCondition auditId extractor.pattern)
                |> always
                |> updateCondition

        onConditionPatternInput val =
            updateCondition (\c -> { c | extractor = { extractor | pattern = val } })
    in
        Html.div [ class "row my-1" ]
            [ Html.div [ class "col-sm-1 px-0 text-left" ]
                [ removeButton False dirtyId [ triggerAuditId, auditId ] (csUpdate (LE.removeAt cIndex))
                ]
            , Html.div [ class "col-sm-11 px-0" ]
                [ Html.div [ class "my-1" ]
                    [ Repo.ViewParts.select "poll" "Mode" True dirtyId onConditionModeSelect conditionSelectItems
                    , textInputRequired "poll"
                        "Pattern"
                        False
                        audit
                        dirtyId
                        [ triggerAuditId, auditId, "pattern" ]
                        onConditionPatternInput
                        extractor.pattern
                    ]
                , ViewParts.htmlIf (not (Polls.isSimpleMatch c))
                    (conditionEditor audit dirtyId [ triggerAuditId, auditId, "responder" ] updateCondition responder)
                ]
            ]


conditionEditor :
    Audit
    -> EntityId
    -> List AuditId
    -> ((Condition -> Condition) -> Poll)
    -> BooleanResponder
    -> Html (Msg Poll)
conditionEditor audit dirtyId auditIdPath cUpdate ({ highOrder, firstOrder } as responder) =
    let
        updateResponder updateFun =
            cUpdate (\c -> { c | responder = updateFun responder })

        highOrderButton ho =
            functionButton (OnEditValid dirtyId (updateResponder (\r -> { r | highOrder = ho })))
                (ho == highOrder)
                (toString ho)
    in
        Html.div []
            [ Html.div [ class "d-flex" ]
                [ Html.label [ class "mr-1", Styles.flex 2 ] [ Html.em [] [ text "High-order" ] ]
                , GBR.highOrders |> List.map highOrderButton |> Html.span [ Styles.flex 4 ]
                ]
            , Html.div [ class "d-flex" ]
                [ Html.label [ class "mr-1", Styles.flex 2 ] [ Html.em [] [ text "Predicate" ] ]
                , GBR.predicates
                    -- Truth is only for simpleMatch
                    |> List.drop 1
                    |> List.map (predicateButton dirtyId auditIdPath updateResponder firstOrder)
                    |> Html.span [ Styles.flex 4 ]
                ]
            , predicateArgsForm audit dirtyId auditIdPath updateResponder firstOrder
            ]


predicateButton :
    EntityId
    -> List AuditId
    -> ((BooleanResponder -> BooleanResponder) -> Poll)
    -> Grasp.FirstOrder Predicate
    -> Predicate
    -> Html (Msg Poll)
predicateButton dirtyId auditIdPath rUpdate firstOrder op =
    let
        onClickMsg =
            case GBR.updatePredicate firstOrder op of
                ( newFO, True ) ->
                    OnEdit dirtyId [ ( auditIdPath, Nothing ) ] (rUpdate (\r -> { r | firstOrder = newFO }))

                ( newFO, False ) ->
                    OnEditValid dirtyId (rUpdate (\r -> { r | firstOrder = newFO }))
    in
        functionButton onClickMsg
            (op == firstOrder.operator)
            (toString op)


functionButton : Msg Poll -> Bool -> String -> Html (Msg Poll)
functionButton msg enabled buttonText =
    smInlineBtn [ ite enabled Button.warning Button.secondary, Button.attrs [ class "mx-1" ] ]
        (ite enabled NoOp msg)
        False
        (text buttonText)


predicateArgsForm :
    Audit
    -> EntityId
    -> List AuditId
    -> ((BooleanResponder -> BooleanResponder) -> Poll)
    -> Grasp.FirstOrder Predicate
    -> Html (Msg Poll)
predicateArgsForm audit dirtyId auditIdPath rUpdate ({ operator, arguments } as fo) =
    let
        updateFirstOrder updateFun =
            rUpdate (\r -> { r | firstOrder = updateFun fo })
    in
        case operator of
            Truth ->
                none

            Contains ->
                Html.div [ class "d-flex" ] [ containsInput audit dirtyId auditIdPath updateFirstOrder arguments ]

            _ ->
                Html.div [ class "d-flex" ] [ twoArgsInput audit operator dirtyId auditIdPath updateFirstOrder arguments ]


containsInput :
    Audit
    -> EntityId
    -> List AuditId
    -> ((Grasp.FirstOrder Predicate -> Grasp.FirstOrder Predicate) -> Poll)
    -> List String
    -> Html (Msg Poll)
containsInput audit dirtyId auditIdPath0 foUpdate arguments =
    let
        arg =
            case arguments of
                [ rv ] ->
                    rv

                _ ->
                    "true"

        auditIdPath1 =
            auditIdPath0 ++ [ "rightValue" ]

        ( inputGroupClass, formControlClasses ) =
            case Repo.getAuditIn auditIdPath1 audit of
                Just (Complaint _) ->
                    ( " has-danger", [ class " form-control-danger" ] )

                _ ->
                    ( "", [] )

        onInput v =
            OnEdit dirtyId [ ( auditIdPath1, Repo.required v ) ] (foUpdate (\fo -> { fo | arguments = [ v ] }))
    in
        Html.div [ class ("input-group input-group-sm d-inline-flex my-2" ++ inputGroupClass) ]
            [ Html.span [ class "input-group-addon px-0", Styles.flex 2 ] [ text "Matches contains" ]
            , Repo.ViewParts.rawInput ((Styles.flex 5) :: formControlClasses)
                "text"
                "poll"
                (Repo.ViewParts.makeInputId "poll" "Right Value")
                "Right Value"
                onInput
                arg
            ]


twoArgsInput :
    Audit
    -> Predicate
    -> EntityId
    -> List AuditId
    -> ((Grasp.FirstOrder Predicate -> Grasp.FirstOrder Predicate) -> Poll)
    -> List String
    -> Html (Msg Poll)
twoArgsInput audit op dirtyId auditIdPath foUpdate arguments =
    let
        argsTuple =
            case arguments of
                [ ci, rv ] ->
                    ( ci, rv )

                _ ->
                    ( "1", "true" )

        updateArgAt index v =
            foUpdate (\fo -> { fo | arguments = LE.updateIfIndex ((==) index) (always v) arguments })

        ( inputClass, maybeArgsAudit ) =
            case Repo.getAuditIn auditIdPath audit of
                Just (Nested aa) ->
                    ( " has-danger", Just aa )

                _ ->
                    ( "", Nothing )
    in
        argsTuple
            |> twoArgsInputAddons maybeArgsAudit op dirtyId auditIdPath updateArgAt
            |> Html.div [ class ("input-group input-group-sm d-inline-flex my-2" ++ inputClass) ]


twoArgsInputAddons :
    Maybe Audit
    -> Predicate
    -> EntityId
    -> List AuditId
    -> (Int -> String -> Poll)
    -> ( String, String )
    -> List (Html (Msg Poll))
twoArgsInputAddons maybeArgsAudit op dirtyId auditIdPath updateArgAt ( captureIndex, rightValue ) =
    let
        ( isCaptureIndexValid, isRightValueValid ) =
            case maybeArgsAudit of
                Nothing ->
                    ( True, True )

                Just argsAudit ->
                    ( isNothing <| Dict.get "captureIndex" <| argsAudit
                    , isNothing <| Dict.get "rightValue" <| argsAudit
                    )
    in
        [ Html.span [ class "input-group-addon px-0", Styles.flex 2 ] [ text "Match at position" ]
        , indexNumericInput "Capture Index"
            isCaptureIndexValid
            dirtyId
            (auditIdPath ++ [ "captureIndex" ])
            (updateArgAt 0)
            captureIndex
        , Html.span [ class "input-group-addon px-0", Styles.flex 1 ] [ text (GBR.toOperator op) ]
        , rightValueInput "Right Value"
            isRightValueValid
            dirtyId
            (auditIdPath ++ [ "rightValue" ])
            (updateArgAt 1)
            rightValue
        ]


indexNumericInput :
    String
    -> Bool
    -> EntityId
    -> List AuditId
    -> (String -> Poll)
    -> String
    -> Html (Msg Poll)
indexNumericInput label isValid dirtyId auditIdPath updateCaptureIndex captureIndex =
    let
        onInput v =
            OnEdit dirtyId [ ( auditIdPath, mustBeNonNegInteger v ) ] <| updateCaptureIndex <| v
    in
        Repo.ViewParts.rawInput [ class ("text-center" ++ (ite isValid "" " form-control-danger")), Styles.flex 1, Attr.min "0" ]
            "number"
            "poll"
            (Repo.ViewParts.makeInputId "poll" label)
            "#"
            onInput
            captureIndex


mustBeNonNegInteger : String -> Maybe String
mustBeNonNegInteger v =
    case String.toInt v of
        Ok num ->
            ite (num >= 0) Nothing (Just "Must be non-negative integer")

        Err _ ->
            ite (v == "") (Just "This field is required") (Just "Must be non-negative integer")


rightValueInput :
    String
    -> Bool
    -> EntityId
    -> List AuditId
    -> (String -> Poll)
    -> String
    -> Html (Msg Poll)
rightValueInput label isValid dirtyId auditIdPath updateRightValue rightValue =
    let
        onInput v =
            OnEdit dirtyId [ ( auditIdPath, Repo.required v ) ] <| updateRightValue <| v
    in
        Repo.ViewParts.rawInput ((ite isValid [] [ class " form-control-danger" ]) ++ [ Styles.flex 5 ])
            "text"
            "poll"
            (Repo.ViewParts.makeInputId "poll" label)
            label
            onInput
            rightValue



-- Material Form


materialCard : Audit -> AuditId -> EntityId -> ((Material -> Material) -> Poll) -> Material -> Entity Action -> Html (Msg Poll)
materialCard audit triggerAuditId dirtyId mUpdate material { data } =
    case data.bodyTemplate.variables of
        [] ->
            none

        variables ->
            materialCardImpl audit triggerAuditId dirtyId mUpdate material variables


materialCardImpl : Audit -> AuditId -> EntityId -> ((Material -> Material) -> Poll) -> Material -> List String -> Html (Msg Poll)
materialCardImpl audit triggerAuditId dirtyId mUpdate material variables =
    Html.div [ class "card-block p-1" ]
        [ Html.div [ class "container-fluid" ]
            [ Html.div [ class "row my-1" ]
                [ Html.div [ class "col-md-12 col-xl-3 px-0" ]
                    [ Html.label [ class "m-1" ] [ text "Material" ]
                    ]
                , variables
                    |> List.map (materialForm audit [ triggerAuditId, "material" ] dirtyId mUpdate material)
                    |> Html.div [ class "col-md-12 col-xl-9 px-0" ]
                ]
            ]
        ]


materialForm : Audit -> List AuditId -> EntityId -> ((Material -> Material) -> Poll) -> Material -> String -> Html (Msg Poll)
materialForm audit auditIdPath dirtyId mUpdate material variable =
    let
        ({ extractor, responder } as materialItem) =
            material
                |> Utils.dictGetWithDefault variable
                    (Polls.functionalMaterialItem variable "" GSR.First At [ "0" ])

        updateMaterialItem updateFun =
            mUpdate (\m -> Dict.insert variable (updateFun materialItem) m)

        onMaterialPatternInput v =
            updateMaterialItem (\mi -> { mi | extractor = { extractor | pattern = v } })
    in
        Html.div [ class "card" ]
            [ Html.div [ class "card-header p-1" ] [ Html.code [] [ text variable ] ]
            , Html.div [ class "card-block px-2 py-1" ]
                [ textInputRequired "poll"
                    "Pattern"
                    False
                    audit
                    dirtyId
                    (auditIdPath ++ [ variable, "pattern" ])
                    onMaterialPatternInput
                    extractor.pattern
                ]
            , materialEditor audit (auditIdPath ++ [ variable ]) dirtyId updateMaterialItem responder
            ]


materialEditor :
    Audit
    -> List AuditId
    -> EntityId
    -> ((Grasp.Instruction StringResponder -> Grasp.Instruction StringResponder) -> Poll)
    -> StringResponder
    -> Html (Msg Poll)
materialEditor audit auditIdPath dirtyId miUpdate ({ highOrder, firstOrder } as responder) =
    let
        updateResponder updateFun =
            miUpdate (\mi -> { mi | responder = updateFun responder })

        highOrderButton ho =
            functionButton (OnEditValid dirtyId (updateResponder (\r -> { r | highOrder = ho })))
                (ho == highOrder)
                (toString ho)
    in
        Html.div [ class "px-2" ]
            [ Html.div [ class "d-flex" ]
                [ Html.label [ class "mr-1", Styles.flex 3 ] [ Html.em [] [ text "High-order" ] ]
                , GSR.highOrders |> List.map highOrderButton |> Html.span [ Styles.flex 4 ]
                ]
            , Html.div [ class "d-flex" ]
                [ Html.label [ class "mr-1", Styles.flex 3 ] [ Html.em [] [ text "String maker" ] ]
                , GSR.stringMakers
                    |> List.map (stringMakerButton dirtyId updateResponder firstOrder)
                    |> Html.span [ Styles.flex 4 ]
                ]
            , stringMakerArgsForm audit dirtyId auditIdPath updateResponder firstOrder
            ]


stringMakerButton :
    EntityId
    -> ((StringResponder -> StringResponder) -> Poll)
    -> Grasp.FirstOrder StringMaker
    -> StringMaker
    -> Html (Msg Poll)
stringMakerButton dirtyId rUpdate firstOrder op =
    functionButton (OnEditValid dirtyId (rUpdate (\r -> { r | firstOrder = GSR.newWithStringMaker op })))
        (op == firstOrder.operator)
        (toString op)


stringMakerArgsForm :
    Audit
    -> EntityId
    -> List AuditId
    -> ((StringResponder -> StringResponder) -> Poll)
    -> Grasp.FirstOrder StringMaker
    -> Html (Msg Poll)
stringMakerArgsForm audit dirtyId auditIdPath0 rUpdate ({ operator, arguments } as fo) =
    let
        arg =
            case ( operator, arguments ) of
                ( _, [ v ] ) ->
                    v

                ( Join, _ ) ->
                    ","

                ( At, _ ) ->
                    "1"

        updateSingleArg v =
            rUpdate (\r -> { r | firstOrder = { fo | arguments = [ v ] } })

        auditIdPath1 =
            auditIdPath0 ++ [ "responder" ]

        inputGroupClass =
            case Repo.getAuditIn auditIdPath1 audit of
                Just _ ->
                    " has-danger"

                _ ->
                    ""

        ( inputDescription, inputImpl ) =
            case operator of
                Join ->
                    ( "Join matches with"
                    , rightValueInput "Delimiter"
                        (audit |> Repo.getAuditIn (auditIdPath1 ++ [ "delimiter" ]) |> isNothing)
                        dirtyId
                        (auditIdPath1 ++ [ "delimiter" ])
                        updateSingleArg
                        arg
                    )

                At ->
                    ( "Use match at position"
                    , indexNumericInput "Capture Index"
                        (audit |> Repo.getAuditIn (auditIdPath1 ++ [ "captureIndex" ]) |> isNothing)
                        dirtyId
                        (auditIdPath1 ++ [ "captureIndex" ])
                        updateSingleArg
                        arg
                    )
    in
        Html.div [ class "d-flex" ]
            [ Html.div [ class ("input-group input-group-sm d-inline-flex my-2" ++ inputGroupClass) ]
                [ Html.span [ class "input-group-addon px-0", Styles.flex 4 ] [ text inputDescription ]
                , inputImpl
                ]
            ]



-- Form Parts


textInputRaw : String -> EntityId -> (String -> x) -> String -> Html (Msg x)
textInputRaw inputLabel =
    Repo.ViewParts.textInputWithoutValidation "poll" inputLabel True


select : String -> EntityId -> (String -> x) -> List Repo.ViewParts.SelectItem -> Html (Msg x)
select inputLabel =
    Repo.ViewParts.select "poll" inputLabel False


smInlineFaBtn : List (Button.Option msg) -> msg -> Bool -> String -> Html msg
smInlineFaBtn styles msg disabled fa =
    smInlineBtn ((Button.attrs [ class "mr-1" ]) :: styles) msg disabled (ViewParts.fa [] 1 fa)


smInlineBtn : List (Button.Option msg) -> msg -> Bool -> Html msg -> Html msg
smInlineBtn styles msg disabled html =
    let
        attrs =
            if disabled then
                [ class "p-0 disabled invisible", Styles.inline ]
            else
                [ class "p-0", Styles.inline, Styles.fakeLink ]
    in
        Button.button
            (styles
                ++ [ Button.small
                   , Button.onClick msg
                   , Button.attrs attrs
                   , Button.disabled disabled
                   ]
            )
            [ html ]



-- Show


show : EntityDict Action -> EntityDict Authentication -> Repo Aux Poll -> Entity Poll -> Html Polls.Msg
show actionDict authDict ({ dirtyDict, deleteModal } as pollRepo) ({ id } as entity) =
    let
        maybeDirtyEntity =
            Dict.get id dirtyDict
    in
        ViewParts.triPaneView
            [ Z.lazy2 titleShow maybeDirtyEntity entity
            , Z.lazy deleteModalDialog deleteModal
            ]
            [ mainFormShow actionDict authDict entity maybeDirtyEntity ]
            [ text "Poll History" ]
            [ text "right" ]


titleShow : Maybe ( Entity Poll, Audit ) -> Entity Poll -> Html Polls.Msg
titleShow maybeDirtyEntity ({ id, updatedAt, data } as entity) =
    Html.div
        [ class "d-flex justify-content-between align-items-center pb-2"
        , Styles.bottomBordered
        ]
        [ Html.div []
            [ Html.h2 [ class "mb-2" ]
                ([ ViewParts.fa [ class "align-bottom mr-2" ] 2 "fa-calendar"
                 , text "Poll to "
                 ]
                    ++ ViewParts.autoLink data.url
                )
            , Html.p [ class "text-muted mb-0", Styles.xSmall ]
                [ text ("ID : " ++ id)
                , text (", Last updated at : " ++ (Utils.timestampToString updatedAt))
                ]
            , Html.p [ class "text-muted mb-0", Styles.xSmall ]
                [ text ("Last run at : " ++ (data.lastRunAt |> ME.unwrap "(Not yet)" Utils.timestampToString))
                , text (", Next run at : " ++ (data.nextRunAt |> ME.unwrap "(Not scheduled)" Utils.timestampToString))
                ]
            ]
        , Html.div []
            [ Z.lazy2 toggleEditButton maybeDirtyEntity entity
            , Z.lazy deleteButton entity
            ]
        ]
        |> Html.map Polls.RepoMsg


toggleEditButton : Maybe ( Entity Poll, Audit ) -> Entity Poll -> Html (Msg Poll)
toggleEditButton maybeDirtyEntity ({ id } as entity) =
    case maybeDirtyEntity of
        Just dirtyEntity ->
            stdBtn Button.info [ Button.small, Button.onClick (CancelEdit id) ] False "Reset"

        Nothing ->
            stdBtn Button.primary [ Button.small, Button.onClick (StartEdit id entity) ] False "Edit"


deleteButton : Entity Poll -> Html (Msg Poll)
deleteButton entity =
    stdBtn Button.danger [ Button.small, Button.onClick (ConfirmDelete entity) ] False "Delete"


deleteModalDialog : Repo.ModalState Poll -> Html Polls.Msg
deleteModalDialog { target, isShown } =
    ViewParts.modal
        (always CancelDelete)
        isShown
        [ class "modal-sm" ]
        (text "Deleting Poll to " :: ViewParts.autoLink target.data.url)
        [ text "Are you sure?" ]
        [ stdBtn Button.danger [ Button.onClick (Delete target.id) ] False "Yes, delete"
        , stdBtn Button.secondary [ Button.onClick CancelDelete ] False "Cancel"
        ]
        |> Html.map Polls.RepoMsg


mainFormShow : EntityDict Action -> EntityDict Authentication -> Entity Poll -> Maybe ( Entity Poll, Audit ) -> Html Polls.Msg
mainFormShow actionDict authDict entity maybeDirtyEntity =
    let
        ( notEditing, ( { id, data }, audit ) as dirtyEntity ) =
            case maybeDirtyEntity of
                Just de ->
                    ( False, de )

                Nothing ->
                    ( True, ( entity, Repo.dummyAudit ) )

        readyToUpdate =
            Polls.hasDiff entity.data data && Polls.isValid dirtyEntity
    in
        [ submitButton "poll" readyToUpdate "Update" ]
            |> (++) (mainFormInputs actionDict authDict id audit data)
            |> (List.singleton << Html.fieldset [ Attr.disabled notEditing ])
            |> Html.form [ Attr.id "poll", Html.Events.onSubmit (ite readyToUpdate (Update id data) NoOp) ]
            |> ViewParts.cardBlock [] "" Nothing
            |> Html.map Polls.RepoMsg
