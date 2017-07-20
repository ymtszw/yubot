module Polls.View exposing (index, new, show)

import Dict exposing (Dict)
import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Events as Events
import Html.Lazy as Z
import Maybe.Extra as ME exposing (isNothing)
import List.Extra as LE
import Bootstrap.Button as Button
import Utils exposing (ite, (>>=))
import Grasp
import Grasp.BooleanResponder as GBR exposing (BooleanResponder, Predicate(..))
import Grasp.StringResponder as GSR exposing (StringResponder, StringMaker(..))
import Repo exposing (Repo, Entity, EntityId, EntityDict, Audit, AuditId, AuditEntry(..))
import Repo.Messages exposing (Msg(..))
import Repo.ViewParts as RVP exposing (navigate, submitButton, textInputRequired)
import Polls exposing (Poll, Aux, Condition, Material)
import Actions exposing (Action)
import Actions.View exposing (trialResultCard)
import Actions.ViewParts
import Authentications exposing (Authentication)
import Authentications.ViewParts exposing (authSelect)
import Styles
import ViewParts as VP exposing (none, stdBtn)


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
new actionDict authDict repo =
    let
        (( { data }, audit ) as dirtyEntity) =
            Repo.dirtyGetWithDefault "new" Polls.dummyPoll repo.dirtyDict
    in
        VP.triPaneView
            [ Z.lazy titleNew data ]
            [ Z.lazy3 mainFormNew actionDict authDict dirtyEntity ]
            [ none -- Used by History in Show
            ]
            [ trialResults actionDict repo data ]


titleNew : Poll -> Html Polls.Msg
titleNew data =
    Html.div
        [ class "d-flex justify-content-between align-items-center pb-2"
        , Styles.bottomBordered
        ]
        [ Html.div []
            [ Html.h2 [ class "mb-2" ]
                [ VP.fa [ class "align-bottom mr-2" ] 2 "fa-calendar"
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
        |> Html.map Polls.RepoMsg


mainFormNew : EntityDict Action -> EntityDict Authentication -> ( Entity Poll, Audit ) -> Html Polls.Msg
mainFormNew actionDict authDict (( { data }, audit ) as dirtyEntity) =
    let
        isValid =
            Polls.isValid dirtyEntity
    in
        [ Html.div [ class "float-right" ]
            [ Z.lazy2 runButton isValid data |> Html.map Polls.AuxMsg
            , submitButton "poll" isValid "Create"
            ]
        ]
            |> (++) (mainFormInputs actionDict authDict "new" audit data)
            |> Html.form [ Attr.id "poll", Events.onSubmit (Polls.RepoMsg (ite isValid (Create "new" data) NoOp)) ]
            |> VP.cardBlock [] "" Nothing


runButton : Bool -> Poll -> Html Polls.AuxMsg
runButton isValid data =
    stdBtn Button.success
        [ Button.attrs [], Button.onClick (Polls.RunPoll data) ]
        (not isValid)
        "Run"


mainFormInputs : EntityDict Action -> EntityDict Authentication -> EntityId -> Audit -> Poll -> List (Html Polls.Msg)
mainFormInputs actionDict authDict dirtyId audit ({ interval, authId, isEnabled, triggers } as data) =
    [ urlInputWithTryButton audit dirtyId data
    , authSelect "poll" "Credential" (Authentications.listForHttp authDict) dirtyId data authId |> Html.map Polls.RepoMsg
    , Polls.intervals
        |> intervalSelectItems interval
        |> RVP.select "poll" "Interval" False dirtyId (\x -> { data | interval = x })
        |> Html.map Polls.RepoMsg
    , RVP.checkbox "poll" "Enabled?" False dirtyId (\c -> { data | isEnabled = c }) isEnabled |> Html.map Polls.RepoMsg
    , triggerEditor actionDict dirtyId audit data
    ]


urlInputWithTryButton : Audit -> EntityId -> Poll -> Html Polls.Msg
urlInputWithTryButton audit dirtyId data =
    RVP.formGroup "poll" "URL" False audit [ "url" ] (urlInputGroup dirtyId data)


urlInputGroup : EntityId -> Poll -> String -> Html Polls.Msg
urlInputGroup dirtyId ({ url } as data) inputId =
    Html.div [ class "input-group input-group-sm d-inline-flex my-2" ]
        [ RVP.rawInput [ Styles.flex 7 ]
            "url"
            "poll"
            inputId
            "URL"
            (\x -> Polls.RepoMsg <| OnEdit dirtyId [ ( [ "url" ], Repo.required x ) ] { data | url = x })
            url
        , Html.span [ class "input-group-btn px-0", Styles.flex 1 ]
            [ Html.button
                [ class "btn btn-primary"
                , Attr.type_ "button"
                , Styles.fakeLink
                , Attr.disabled (url == "")
                , VP.onClickNoPropagate (Polls.AuxMsg <| Polls.TryPoll data)
                ]
                [ text "Try" ]
            ]
        ]


intervalSelectItems : Polls.Interval -> List Polls.Interval -> List RVP.SelectItem
intervalSelectItems currentInterval intervals =
    List.map (\x -> ( x, Polls.intervalToString x, currentInterval == x )) intervals


triggerEditor : EntityDict Action -> EntityId -> Audit -> Poll -> Html Polls.Msg
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
            , VP.htmlIf (tsLen < 5) (addButton False dirtyId auditIdsToData 2 |> Html.map Polls.RepoMsg)
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
    -> Html Polls.Msg
triggerForm actionDict tsLen dirtyId audit tsUpdate index ({ auditId, collapsed, actionId } as trigger) =
    let
        updateTriggerAtIndex updateFun =
            tsUpdate (LE.updateIfIndex ((==) index) updateFun)
    in
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
        ]
            |> List.map (Html.map Polls.RepoMsg)
            |> (flip (++))
                [ VP.htmlIf (not collapsed)
                    (triggerDetailForm (Dict.get actionId actionDict) audit dirtyId updateTriggerAtIndex index trigger)
                ]
            |> Html.div [ class "row my-1" ]


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
            [ Events.onBlur
                (OnValidate dirtyId
                    ( [ triggerAuditId, "action" ]
                    , maybeSelectedValue
                        |> isNothing
                        |> Utils.boolToMaybe "This field is required"
                    )
                )
            , Events.onInput
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
        RVP.selectWithAttrs auxEvents
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
    -> Html Polls.Msg
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
                |> VP.htmlMaybe
                    (materialCard audit auditId dirtyId updateMaterial material)
            , maybeActionEntity
                |> VP.htmlMaybe
                    (.data >> Actions.ViewParts.preview >> List.singleton >> Html.div [ class "card-footer p-1" ])
            ]



-- Condition Form


conditionsCard : Audit -> AuditId -> EntityId -> ((List Condition -> List Condition) -> Poll) -> List Condition -> Html Polls.Msg
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
                    , addButton (List.length conditions >= 5) dirtyId auditIdsToData 1 |> Html.map Polls.RepoMsg
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
    -> Html Polls.Msg
conditionForm audit triggerAuditId dirtyId csUpdate cIndex ({ auditId, extractor, responder } as c) =
    let
        updateCondition updateFun =
            csUpdate (LE.updateIfIndex ((==) cIndex) updateFun)

        onConditionPatternInput val =
            updateCondition (\c -> { c | extractor = { extractor | pattern = val } })
    in
        Html.div [ class "row my-1" ]
            [ Html.div [ class "col-sm-1 px-0 text-left" ]
                [ removeButton False dirtyId [ triggerAuditId, auditId ] (csUpdate (LE.removeAt cIndex)) |> Html.map Polls.RepoMsg
                ]
            , Html.div [ class "col-sm-11 px-0" ]
                [ Html.div []
                    [ conditionSelectWithTestButton audit triggerAuditId dirtyId updateCondition c
                    , textInputRequired "poll"
                        "Pattern"
                        False
                        audit
                        dirtyId
                        [ triggerAuditId, auditId, "pattern" ]
                        onConditionPatternInput
                        extractor.pattern
                        |> Html.map Polls.RepoMsg
                    ]
                , VP.htmlIf (not (Polls.isSimpleMatch c))
                    (conditionEditor audit dirtyId [ triggerAuditId, auditId, "responder" ] updateCondition responder)
                ]
            ]


conditionSelectWithTestButton : Audit -> AuditId -> EntityId -> ((Condition -> Condition) -> Poll) -> Condition -> Html Polls.Msg
conditionSelectWithTestButton audit triggerAuditId dirtyId cUpdate ({ auditId, extractor } as c) =
    let
        conditionSelectItems =
            [ ( "simpleMatch", "Simple Match", Polls.isSimpleMatch c )
            , ( "functional", "Functional Scan", not (Polls.isSimpleMatch c) )
            ]

        onConditionModeSelect val =
            ite (val == "simpleMatch")
                (Polls.simpleMatchCondition auditId extractor.pattern)
                (Polls.sampleFunctionalCondition auditId extractor.pattern)
                |> always
                |> cUpdate
    in
        Html.div [ class "d-flex mb-2 align-items-center" ]
            [ Html.div [ class "mr-1", Styles.flex 5 ]
                [ RVP.selectWithAttrs (always [])
                    audit
                    [ triggerAuditId, auditId, "mode" ]
                    "poll"
                    "Trigger Mode"
                    True
                    dirtyId
                    onConditionModeSelect
                    conditionSelectItems
                    |> Html.map Polls.RepoMsg
                ]
            , Html.div [ Styles.flex 1 ]
                [ conditionTestButton (cUpdate <| always c) c
                ]
            ]


conditionTestButton : Poll -> Condition -> Html Polls.Msg
conditionTestButton data c =
    let
        readyToTest =
            (data.url /= "")
                && (Grasp.isValidInstruction GBR.isValid c)
    in
        Html.button
            ((ite readyToTest [ Styles.fakeLink ] [])
                ++ [ class "btn btn-sm btn-block btn-primary"
                   , Attr.type_ "button"
                   , Attr.disabled (not readyToTest)
                   , VP.onClickNoPropagate (Polls.AuxMsg <| Polls.TestCondition data c)
                   ]
            )
            [ text "Test" ]


conditionEditor :
    Audit
    -> EntityId
    -> List AuditId
    -> ((Condition -> Condition) -> Poll)
    -> BooleanResponder
    -> Html Polls.Msg
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
            |> Html.map Polls.RepoMsg


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
            , RVP.rawInput ((Styles.flex 5) :: formControlClasses)
                "text"
                "poll"
                (RVP.makeInputId "poll" "Right Value")
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
        RVP.rawInput [ class ("text-center" ++ (ite isValid "" " form-control-danger")), Styles.flex 1, Attr.min "0" ]
            "number"
            "poll"
            (RVP.makeInputId "poll" label)
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
        RVP.rawInput ((ite isValid [] [ class " form-control-danger" ]) ++ [ Styles.flex 5 ])
            "text"
            "poll"
            (RVP.makeInputId "poll" label)
            label
            onInput
            rightValue



-- Material Form


materialCard : Audit -> AuditId -> EntityId -> ((Material -> Material) -> Poll) -> Material -> Entity Action -> Html Polls.Msg
materialCard audit triggerAuditId dirtyId mUpdate material { data } =
    case data.bodyTemplate.variables of
        [] ->
            none

        variables ->
            materialCardImpl audit triggerAuditId dirtyId mUpdate material variables


materialCardImpl : Audit -> AuditId -> EntityId -> ((Material -> Material) -> Poll) -> Material -> List String -> Html Polls.Msg
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


materialForm : Audit -> List AuditId -> EntityId -> ((Material -> Material) -> Poll) -> Material -> String -> Html Polls.Msg
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
            [ Html.div [ class "card-header p-1 d-flex align-items-center justify-content-between" ]
                [ Html.div [] [ Html.code [] [ text variable ] ]
                , Z.lazy3 materialTestButton (material |> always |> mUpdate) material variable |> Html.map Polls.AuxMsg
                ]
            , Html.div [ class "card-block px-2 py-1" ]
                [ textInputRequired "poll"
                    "Pattern"
                    False
                    audit
                    dirtyId
                    (auditIdPath ++ [ variable, "pattern" ])
                    onMaterialPatternInput
                    extractor.pattern
                    |> Html.map Polls.RepoMsg
                ]
            , materialEditor audit (auditIdPath ++ [ variable ]) dirtyId updateMaterialItem responder |> Html.map Polls.RepoMsg
            ]


materialTestButton : Poll -> Material -> String -> Html Polls.AuxMsg
materialTestButton data material variable =
    case Dict.get variable material of
        Just instruction ->
            stdBtn Button.primary
                [ Button.small, Button.onClick (Polls.TestMaterial data variable instruction) ]
                False
                "Test"

        Nothing ->
            stdBtn Button.primary
                [ Button.small ]
                True
                "Test"


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



-- Try Results


trialResults : EntityDict Action -> Repo Aux Poll -> Poll -> Html Polls.Msg
trialResults actionDict { pollTrialResponse, pollTrialResponseCollapsed, conditionTestResult, materialTestResult, runResult } { url } =
    Html.div []
        [ trialResultCard (Just Polls.ToggleTryPollResult) Polls.Clear pollTrialResponseCollapsed pollTrialResponse
        , conditionTestResultCard conditionTestResult
        , materialTestResultCard materialTestResult
        , runResultCard actionDict url runResult
        ]
        |> Html.map Polls.AuxMsg


conditionTestResultCard : Maybe Grasp.TestResult -> Html msg
conditionTestResultCard maybeResult =
    let
        resultHtml value =
            Html.div [ class ("alert " ++ (ite (value == "true") "alert-success" "alert-danger")) ] [ text value ]
    in
        VP.cardBlock [ text "Condition Test" ]
            (maybeResult |> ME.unwrap "Condition test result will be shown here." (always "Condition applied to the body above."))
            Nothing
            (maybeResult |> ME.unwrap none (graspDetail resultHtml))


graspDetail : (String -> Html msg) -> Grasp.TestResult -> Html msg
graspDetail resultHtml { extractResultant, value } =
    let
        matches =
            case extractResultant of
                [] ->
                    Html.div [ class "alert alert-danger" ] [ text "(Not matched)" ]

                ers ->
                    Z.lazy extractResultantTable ers
    in
        Html.div []
            [ Html.h6 [ Styles.bottomBordered ] [ text "Matches" ]
            , matches
            , Html.h6 [ Styles.bottomBordered ] [ text "Result" ]
            , resultHtml value
            ]


extractResultantTable : List (List String) -> Html msg
extractResultantTable extractResultant =
    let
        cols =
            extractResultant |> List.foldl (\x acc -> max (List.length x) acc) 1

        tail subMatches =
            case (List.length subMatches) - cols of
                0 ->
                    []

                1 ->
                    [ Html.td [] [] ]

                l ->
                    [ Html.td [ Attr.colspan l ] [] ]

        tailFilledRow index subMatches =
            subMatches
                |> List.map (text >> List.singleton >> Html.mark [ Styles.pre ] >> List.singleton >> Html.td [])
                |> flip (++) (tail subMatches)
                |> (::) (Html.th [ Attr.scope "row" ] [ text <| toString <| index ])
                |> Html.tr []
    in
        Html.table [ class "table table-responsive table-sm table-bordered", Styles.xSmall ]
            [ (cols - 1)
                |> List.range 0
                |> List.map (toString >> (++) "$" >> text >> List.singleton >> Html.th [])
                |> (::) (Html.th [] [ text "#" ])
                |> Html.thead [ class "thead-default" ]
            , extractResultant
                |> List.indexedMap tailFilledRow
                |> Html.tbody []
            ]


materialTestResultCard : Maybe ( String, Grasp.TestResult ) -> Html msg
materialTestResultCard maybeResult =
    let
        resultDetail ( variable, r ) =
            (\v ->
                Html.div [ class "card" ]
                    [ Html.div [ class "card-header" ] [ Html.code [] [ text variable ] ]
                    , Html.div [ class "card-block" ]
                        [ Html.div [] [ Html.mark [] [ text v ] ] ]
                    ]
            )
                |> flip graspDetail r
    in
        VP.cardBlock [ text "Material Test" ]
            (maybeResult |> ME.unwrap "Material test result will be shown here." (always "Material extraction applied to the body above."))
            Nothing
            (maybeResult |> ME.unwrap none resultDetail)


runResultCard : EntityDict Action -> Utils.Url -> Maybe Polls.HistoryEntry -> Html msg
runResultCard actionDict url maybeHistory =
    VP.cardBlock [ text "Run Result" ]
        (maybeHistory |> ME.unwrap "Run result will be shown here." (always "The Poll was executed!"))
        Nothing
        (maybeHistory |> ME.unwrap none (historyDetail actionDict url))


historyDetail : EntityDict Action -> Utils.Url -> Polls.HistoryEntry -> Html msg
historyDetail actionDict url { runAt, pollResult, triggerResult } =
    Html.div []
        ([ Z.lazy2 pollResultBlock url pollResult ]
            ++ (triggerResults actionDict pollResult triggerResult)
        )


pollResultBlock : Utils.Url -> Polls.PollResult -> Html msg
pollResultBlock url { status } =
    Html.div []
        [ horizontalCard
            [ VP.fa [ class ("text-" ++ Utils.statusBsColor status) ] 2 (statusFa status)
            , Html.strong [] [ text "Retrieve from URL" ]
            ]
        , rightShiftedBlock
            [ Html.dl []
                [ Html.dt [] [ text "URL" ]
                , Html.dd [ class "p-2" ] [ Html.code [ class "small" ] (VP.autoLink url) ]
                , Html.dt [] [ text "Status" ]
                , Html.dd [ class "p-2" ] [ Z.lazy statusText status ]
                ]
            ]
        ]


statusText : Int -> Html msg
statusText code =
    Html.span [ class ("text-white p-1 bg-" ++ Utils.statusBsColor code) ]
        [ text (toString code ++ " " ++ Utils.statusText code) ]


triggerResults : EntityDict Action -> Polls.PollResult -> Maybe Polls.TriggerResult -> List (Html msg)
triggerResults actionDict { status } maybeTriggerResult =
    [ Html.div []
        [ Z.lazy2 triggerCard status maybeTriggerResult
        , maybeTriggerResult
            >>= (.actionId >> flip Dict.get actionDict)
            |> ME.unwrap none (Z.lazy triggeredActionDetail)
        ]
    , maybeTriggerResult |> ME.unwrap none (Z.lazy actionResultBlock)
    ]


triggerCard : Int -> Maybe Polls.TriggerResult -> Html msg
triggerCard code maybeTriggerResult =
    let
        ( iconTextClass, fa, cardText ) =
            if code == 304 then
                ( "text-warning", "fa-minus-circle", "Not Modified" )
            else if code < 200 || code >= 300 then
                ( "text-" ++ Utils.statusBsColor code, statusFa code, "Cannot proceed" )
            else if isNothing maybeTriggerResult then
                ( "text-warning", "fa-minus-circle", "Nothing Triggered" )
            else
                ( "text-success", "fa-check-circle", "Action Triggered" )
    in
        horizontalCard [ VP.fa [ class iconTextClass ] 2 fa, Html.strong [] [ text cardText ] ]


triggeredActionDetail : Entity Action -> Html msg
triggeredActionDetail { data } =
    rightShiftedBlock
        [ Html.dl []
            [ Html.dt [] [ text data.label ]
            , Html.dd [ class "p-2 small" ] [ Actions.ViewParts.preview data ]
            ]
        ]


actionResultBlock : Polls.TriggerResult -> Html msg
actionResultBlock { status, variables } =
    Html.div []
        [ horizontalCard
            [ VP.fa [ class ("text-" ++ Utils.statusBsColor status) ] 2 (statusFa status)
            , Html.strong [] [ text "Execute Action" ]
            ]
        , Html.div [ class "ml-4 my-0 px-4 py-1", Styles.leftInvisibleBordered ]
            [ Html.dl []
                ([ Html.dt [] [ text "Status" ]
                 , Html.dd [ class "p-2" ] [ Z.lazy statusText status ]
                 ]
                    ++ (variableItems variables)
                )
            ]
        ]


variableItems : Dict String String -> List (Html msg)
variableItems variables =
    variables
        |> Dict.toList
        |> List.concatMap
            (\( name, value ) ->
                [ Html.dt [] [ Html.code [] [ text name ] ]
                , Html.dd [ class "p-2" ] [ Html.mark [] [ text value ] ]
                ]
            )


statusFa : Int -> String
statusFa code =
    if code < 200 then
        "fa-minus-circle"
    else if code < 300 then
        "fa-check-circle"
    else if code < 400 then
        "fa-minus-circle"
    else
        "fa-times-circle"


horizontalCard : List (Html msg) -> Html msg
horizontalCard htmls =
    Html.div [ class "card my-0", Styles.rounded ]
        [ Html.div [ class "card-block p-2" ]
            [ Html.div [ class "card-text d-flex align-items-center" ] htmls
            ]
        ]


rightShiftedBlock : List (Html msg) -> Html msg
rightShiftedBlock htmls =
    Html.div [ class "ml-4 my-0 px-4 py-1", Styles.leftDoubleBordered ] htmls



-- Form Parts


smInlineFaBtn : List (Button.Option msg) -> msg -> Bool -> String -> Html msg
smInlineFaBtn styles msg disabled fa =
    smInlineBtn ((Button.attrs [ class "mr-1" ]) :: styles) msg disabled (VP.fa [] 1 fa)


smInlineBtn : List (Button.Option msg) -> msg -> Bool -> Html msg -> Html msg
smInlineBtn styles msg disabled html =
    let
        attrs =
            if disabled then
                [ class "p-0 disabled invisible" ]
            else
                [ class "p-0", Styles.fakeLink ]
    in
        Button.button
            (styles
                ++ [ Button.small
                   , Button.onClick msg
                   , Button.attrs ([ Attr.type_ "button", Styles.inline ] ++ attrs)
                   , Button.disabled disabled
                   ]
            )
            [ html ]



-- Show


show : EntityDict Action -> EntityDict Authentication -> Repo Aux Poll -> Entity Poll -> Html Polls.Msg
show actionDict authDict ({ dirtyDict, deleteModal } as repo) ({ id } as entity) =
    let
        maybeDirtyEntity =
            Dict.get id dirtyDict
    in
        VP.triPaneView
            [ Z.lazy2 titleShow maybeDirtyEntity entity
            , Z.lazy deleteModalDialog deleteModal
            ]
            [ mainFormShow actionDict authDict entity maybeDirtyEntity ]
            [ text "Poll History" ]
            [ trialResults actionDict repo (maybeDirtyEntity |> ME.unwrap entity Tuple.first |> .data)
            ]


titleShow : Maybe ( Entity Poll, Audit ) -> Entity Poll -> Html Polls.Msg
titleShow maybeDirtyEntity ({ id, updatedAt, data } as entity) =
    Html.div
        [ class "d-flex justify-content-between align-items-center pb-2"
        , Styles.bottomBordered
        ]
        [ Html.div []
            [ Html.h2 [ class "mb-2" ]
                ([ VP.fa [ class "align-bottom mr-2" ] 2 "fa-calendar"
                 , text "Poll to "
                 ]
                    ++ VP.autoLink data.url
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
    VP.modal
        (always CancelDelete)
        isShown
        [ class "modal-sm" ]
        (text "Deleting Poll to " :: VP.autoLink target.data.url)
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

        isValid =
            Polls.isValid dirtyEntity

        readyToUpdate =
            Polls.hasDiff entity.data data && isValid
    in
        [ Html.div [ class "text-right" ]
            [ Z.lazy2 runButton isValid data |> Html.map Polls.AuxMsg
            , submitButton "poll" readyToUpdate "Update"
            ]
        ]
            |> (++) (mainFormInputs actionDict authDict id audit data)
            |> (List.singleton << Html.fieldset [ Attr.disabled notEditing ])
            |> Html.form [ Attr.id "poll", Events.onSubmit (Polls.RepoMsg (ite readyToUpdate (Update id data) NoOp)) ]
            |> VP.cardBlock [] "" Nothing
