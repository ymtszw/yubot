module Actions.View exposing (index, show, new)

import Dict
import Set exposing (Set)
import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Events
import Html.Lazy as Z
import Maybe.Extra exposing (isJust)
import Bootstrap.Button as Button
import ListSet exposing (ListSet)
import Utils exposing (ite)
import HttpTrial
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Repo.ViewParts exposing (navigate, selectItems, submitButton)
import Actions exposing (Action, Aux, TrialValues, ActionType)
import Actions.Hipchat
import Actions.ViewParts
import Authentications exposing (Authentication)
import Authentications.ViewParts exposing (authSelect)
import Styles
import ViewParts exposing (none, stdBtn)
import StringTemplate exposing (StringTemplate)


-- Index


index : Repo Aux Action -> Html Actions.Msg
index ({ indexFilter } as data) =
    Html.div []
        [ indexNav indexFilter
        , cardList data
        ]


indexNav : ListSet ActionType -> Html Actions.Msg
indexNav indexFilter =
    Html.div [ class "d-flex justify-content-between align-items-center mb-2", Styles.bottomBordered ]
        [ (typeNavItems (flip List.member indexFilter))
            |> ViewParts.pillNav [ class "btn-success", Styles.fakeLink ] Actions.Filter (Just Actions.Filter)
            |> Html.map Actions.Index
        , (stdBtn Button.primary [ Button.small, Button.attrs (navigate "/actions/new") ] False "Create")
            |> Html.map Actions.RepoMsg
        ]


typeNavItems : (ActionType -> Bool) -> List ( ActionType, Bool, List (Html msg) )
typeNavItems predicate =
    [ Actions.Http, Actions.Hipchat ]
        |> List.map (\type_ -> ( type_, predicate type_, typeNavItem type_ ))


typeNavItem : ActionType -> List (Html msg)
typeNavItem type_ =
    [ logo "align-bottom mr-1" type_
    , text (toString type_)
    ]


logo : String -> Actions.ActionType -> Html msg
logo additionalClasses type_ =
    ViewParts.fa [ class additionalClasses ] 2 (Actions.typeToFa type_)


cardList : Repo Aux Action -> Html Actions.Msg
cardList { dict, sort, indexFilter } =
    let
        actionsToShow =
            dict |> Repo.dictToSortedList sort |> filterActions indexFilter
    in
        case actionsToShow of
            [] ->
                Html.div [ class "text-center text-muted" ] [ text "No Actions to show!" ]

            actions ->
                actions
                    |> List.map (Z.lazy actionCard)
                    |> Html.div [ class "row" ]
                    |> Html.map Actions.RepoMsg


filterActions : ListSet ActionType -> List (Repo.Entity Action) -> List (Repo.Entity Action)
filterActions indexFilter actionList =
    case indexFilter of
        [] ->
            actionList

        activeTypes ->
            List.filter (.data >> .type_ >> flip List.member activeTypes) actionList


actionCard : Repo.Entity Action -> Html (Msg Action)
actionCard { id, data } =
    Html.div [ class "col-lg-6 col-md-12" ]
        [ Html.div ([ class "card my-2 btn-secondary", Styles.rounded, Styles.fakeLink ] ++ (navigate ("/actions/" ++ id)))
            [ Html.div [ class "card-block p-3" ]
                [ Html.div [ class "card-text d-flex justify-content-between align-items-center" ]
                    [ Z.lazy onelineSummary data ]
                ]
            ]
        ]


onelineSummary : Action -> Html (Msg Action)
onelineSummary ({ type_ } as data) =
    case type_ of
        Actions.Http ->
            data |> httpSummary |> Html.div []

        Actions.Hipchat ->
            data |> hipchatSummary |> Html.div []


httpSummary : Action -> List (Html (Msg Action))
httpSummary ({ label, method, url, authId, type_ } as data) =
    [ logo "align-middle" type_
    , Html.strong [ class "mx-2" ] [ text label ]
    , Html.code [ class "mx-2" ] (ViewParts.autoLink ((toString method) ++ " " ++ url))
    , text " " -- Inline whitespace for soft-wrapping in small screen
    , ite (isJust authId) authBadge none
    ]


authBadge : Html msg
authBadge =
    Html.span [ class "badge badge-default" ] [ text "Require Auth" ]


hipchatSummary : Action -> List (Html (Msg Action))
hipchatSummary ({ type_ } as data) =
    data
        |> Actions.Hipchat.fetchParams
        |> hipchatSummaryImpl
        |> (::) (logo "align-middle" type_)


hipchatSummaryImpl : Actions.Hipchat.UserParams -> List (Html (Msg Action))
hipchatSummaryImpl { label, roomId, color, notify } =
    let
        ( notifyClass, notifyFa ) =
            ite notify ( " text-primary", "fa-toggle-on" ) ( "", "fa-toggle-off" )
    in
        List.map (Html.span [ class "mx-2" ])
            [ [ Html.strong [] [ text label ] ]
            , [ text "Room ID: ", Html.strong [] [ text roomId ] ]
            , [ text "Color: ", Html.span [ Styles.hipchatColor color ] [ text (toString color) ] ]
            , [ text "Notify: ", ViewParts.fa [ class ("fa-lg" ++ notifyClass) ] 1 notifyFa ]
            ]



-- New


new : Repo.EntityDict Authentication -> Repo Aux Action -> Html Actions.Msg
new authDict { dirtyDict, trialValues, trialResponse } =
    let
        (( { data }, audit ) as dirtyEntity) =
            Repo.dirtyGetWithDefault "new" Actions.dummyAction dirtyDict
    in
        ViewParts.triPaneView
            [ Z.lazy titleNew data ]
            [ Z.lazy2 mainFormNew authDict dirtyEntity ]
            [ trialForm trialValues data ]
            [ Z.lazy trialResultCard trialResponse ]


titleNew : Action -> Html Actions.Msg
titleNew data =
    Html.div
        [ class "d-flex justify-content-between align-items-center pb-2"
        , Styles.bottomBordered
        ]
        [ Html.div []
            [ Html.h2 [ class "mb-2" ]
                [ ViewParts.fa [ class "align-bottom mr-2" ] 2 "fa-file-text-o"
                , text "New Action"
                ]
            ]
        , Html.div [] [ stdBtn Button.info [ Button.small, Button.onClick (CancelEdit "new") ] (data == Actions.dummyAction) "Reset" ]
        ]
        |> Html.map Actions.RepoMsg


mainFormNew : Repo.EntityDict Authentication -> ( Repo.Entity Action, Repo.Audit ) -> Html Actions.Msg
mainFormNew authDict (( { data }, audit ) as dirtyEntity) =
    let
        isValid =
            case data.type_ of
                Actions.Hipchat ->
                    Actions.Hipchat.isValid dirtyEntity

                Actions.Http ->
                    Actions.isValid dirtyEntity
    in
        [ submitButton "action" isValid "Create" ]
            |> (++) (mainFormInputs authDict "new" audit data)
            |> (::) (typeNavNew authDict data)
            |> Html.form [ Attr.id "action", Html.Events.onSubmit (ite isValid (Create "new" data) NoOp) ]
            |> ViewParts.cardBlock [] "" Nothing
            |> Html.map Actions.RepoMsg


mainFormInputs : Repo.EntityDict Authentication -> Repo.EntityId -> Repo.Audit -> Action -> List (Html (Msg Action))
mainFormInputs authDict dirtyId audit data =
    case data.type_ of
        Actions.Http ->
            httpDataInputs authDict dirtyId audit data

        Actions.Hipchat ->
            hipchatDataInputs authDict dirtyId audit data


typeNavNew : Repo.EntityDict Authentication -> Action -> Html (Msg Action)
typeNavNew authDict data =
    let
        selectAvailable ( type_, _, _ ) =
            case type_ of
                Actions.Hipchat ->
                    authDict |> Authentications.listForHipchat |> List.isEmpty |> not

                Actions.Http ->
                    True

        onTypeSelect type_ =
            case type_ of
                Actions.Hipchat ->
                    Actions.Hipchat.default

                Actions.Http ->
                    Actions.dummyAction
    in
        (typeNavItems ((==) data.type_))
            |> List.filter selectAvailable
            |> ViewParts.pillNav [ Styles.bordered ] (OnEditValid "new" << onTypeSelect) Nothing


httpDataInputs : Repo.EntityDict Authentication -> Repo.EntityId -> Repo.Audit -> Action -> List (Html (Msg Action))
httpDataInputs authDict dirtyId audit ({ label, method, url, authId } as data) =
    [ textInputRequired "Label" audit dirtyId [ "label" ] (\x -> { data | label = x }) label
    , Utils.methods |> selectItems method |> select "Method" dirtyId (\x -> { data | method = Utils.stringToMethod x })
    , textInputRequired "URL" audit dirtyId [ "url" ] (\x -> { data | url = x }) url
    , authSelect "action" "Credential" (Authentications.listForHttp authDict) dirtyId data authId
    , httpBodyTemplateInput dirtyId audit data
    ]


httpBodyTemplateInput : Repo.EntityId -> Repo.Audit -> Action -> Html (Msg Action)
httpBodyTemplateInput dirtyId audit ({ bodyTemplate } as data) =
    let
        onBodyInput body =
            case StringTemplate.validate body of
                Ok variables ->
                    OnEdit dirtyId [ ( [ "BodyTemplate" ], Nothing ) ] { data | bodyTemplate = StringTemplate body variables }

                Err error ->
                    OnEdit dirtyId [ ( [ "BodyTemplate" ], Just error ) ] { data | bodyTemplate = { bodyTemplate | body = body } }
    in
        Html.div []
            [ Repo.ViewParts.editorInput "action" "BodyTemplate" audit onBodyInput bodyTemplate.body
            , Actions.ViewParts.variableList bodyTemplate.variables
            ]


hipchatDataInputs : Repo.EntityDict Authentication -> Repo.EntityId -> Repo.Audit -> Action -> List (Html (Msg Action))
hipchatDataInputs authDict dirtyId audit ({ label, bodyTemplate } as data) =
    let
        ({ roomId, color, notify, messageTemplate } as userParams) =
            Actions.Hipchat.fetchParams data

        applyParamsNeverFail validUserParams =
            case Actions.Hipchat.applyParams data validUserParams of
                Ok newData ->
                    newData

                Err ( _, newData ) ->
                    -- Should not happen
                    newData

        applyMessageTemplate string =
            Actions.Hipchat.applyParams data { userParams | messageTemplate = string }
    in
        [ textInputRequired "Label" audit dirtyId [ "label" ] (\x -> { data | label = x }) label
        , textInputRequired "RoomID" audit dirtyId [ "roomId" ] (\x -> { data | url = Actions.Hipchat.roomIdToUrl x }) roomId
        , hipchatAuthSelect (Authentications.listForHipchat authDict) audit dirtyId data
        , hipchatColorSelect audit dirtyId (\x -> applyParamsNeverFail { userParams | color = Actions.Hipchat.stringToColor x }) color
        , hipchatNotifyCheck (\checked -> OnEditValid dirtyId (applyParamsNeverFail { userParams | notify = checked })) notify
        , hipchatMessageTemplateEditor dirtyId audit applyMessageTemplate bodyTemplate messageTemplate
        ]


hipchatColorSelect : Repo.Audit -> Repo.EntityId -> (String -> Action) -> Actions.Hipchat.Color -> Html (Msg Action)
hipchatColorSelect audit dirtyId applyColorString color =
    let
        hipchatColor maybeSelectedValue =
            case maybeSelectedValue of
                Nothing ->
                    []

                Just colorStr ->
                    colorStr |> Actions.Hipchat.stringToColor |> Styles.hipchatColor |> List.singleton
    in
        Actions.Hipchat.colors
            |> selectItems color
            |> Repo.ViewParts.selectWithAttrs hipchatColor audit [ "color" ] "action" "Color" False dirtyId applyColorString


hipchatAuthSelect : List (Repo.Entity Authentication) -> Repo.Audit -> Repo.EntityId -> Action -> Html (Msg Action)
hipchatAuthSelect authList audit dirtyId ({ authId } as data) =
    authList
        |> List.map (\{ id, data } -> ( id, (data.name ++ " (" ++ id ++ ")"), authId == Just id ))
        |> Repo.ViewParts.selectRequireable True audit "action" "Credential" False dirtyId [ "credential" ] (\x -> { data | authId = Just x })


hipchatNotifyCheck : (Bool -> Msg Action) -> Bool -> Html (Msg Action)
hipchatNotifyCheck msg notify =
    Html.div [ class "form-check" ]
        [ Html.label [ class "form-check-label" ]
            [ Html.input
                [ Attr.type_ "checkbox"
                , Attr.id "action-notify"
                , Attr.form "action"
                , class "form-check-input"
                , Attr.checked notify
                , Html.Events.onCheck msg
                ]
                []
            , text " Notify?"
            ]
        ]


hipchatMessageTemplateEditor :
    Repo.EntityId
    -> Repo.Audit
    -> (String -> Result ( String, Action ) Action)
    -> StringTemplate
    -> Actions.Hipchat.MessageTemplate
    -> Html (Msg Action)
hipchatMessageTemplateEditor dirtyId audit applyMessageTemplate { variables } messageTemplate =
    let
        onMessageTemplateInput string =
            case applyMessageTemplate string of
                Ok newData ->
                    OnEdit dirtyId [ ( [ "MessageTemplate" ], Nothing ) ] newData

                Err ( error, newData ) ->
                    OnEdit dirtyId [ ( [ "MessageTemplate" ], Just error ) ] newData
    in
        Html.div []
            [ Repo.ViewParts.editorInput "action" "MessageTemplate" audit onMessageTemplateInput messageTemplate
            , Actions.ViewParts.variableList variables
            ]


trialForm : TrialValues -> Action -> Html Actions.Msg
trialForm trialValues ({ bodyTemplate } as data) =
    let
        isReady =
            Actions.trialReady bodyTemplate.variables trialValues
    in
        [ submitButton "action-trial" isReady "Try" ]
            |> (++) (trialInputs trialValues data)
            |> Html.form [ Attr.id "action-trial", Html.Events.onSubmit (ite isReady (Actions.Try data trialValues) Actions.NoOp) ]
            |> ViewParts.cardBlock
                [ Html.h4 [ class "pb-2", Styles.bottomBordered ] [ text "Try Action" ] ]
                "Fill template variables and try action!"
                Nothing
            |> Html.map Actions.Trial


trialInputs : TrialValues -> Action -> List (Html Actions.TrialMsg)
trialInputs trialValues ({ bodyTemplate, type_ } as data) =
    let
        trialTextInput variable =
            Repo.ViewParts.textInputImpl
                "action-trial"
                variable
                False
                Repo.dummyAudit
                [ "trial value" ]
                (Actions.OnTrialEdit variable)
                (Utils.dictGetWithDefault variable "" trialValues)

        templateToPreview =
            case type_ of
                Actions.Http ->
                    bodyTemplate

                Actions.Hipchat ->
                    StringTemplate
                        (Actions.Hipchat.fetchMessageTemplateFromBody bodyTemplate.body)
                        bodyTemplate.variables
    in
        [ Html.div [ class "small" ] [ Actions.ViewParts.target data ]
        , Z.lazy2 Actions.ViewParts.renderBodyTemplate templateToPreview trialValues
        ]
            |> (++) (List.map trialTextInput bodyTemplate.variables)


trialResultCard : Maybe HttpTrial.Response -> Html Actions.Msg
trialResultCard maybeResponse =
    let
        ( description, resultBody, cleared ) =
            case maybeResponse of
                Just ({ elapsedMs } as trialResponse) ->
                    ( "Completed in " ++ (toString elapsedMs) ++ "ms", responseCard trialResponse, False )

                Nothing ->
                    ( "Response will be shown here.", none, True )
    in
        ViewParts.cardBlock
            [ Html.div [ class "pb-2 d-flex justify-content-between", Styles.bottomBordered ]
                [ Html.h4 [] [ text "Try Result" ]
                , stdBtn Button.secondary [ Button.small, Button.onClick Actions.Clear ] cleared "Clear"
                ]
            ]
            description
            Nothing
            resultBody
            |> Html.map Actions.Trial


responseCard : HttpTrial.Response -> Html msg
responseCard { status, headers, body } =
    let
        statusAlert =
            if 200 <= status && status < 300 then
                "alert-success"
            else if 400 <= status then
                "alert-danger"
            else
                "alert-warning"

        maxNameLength =
            headers |> List.map (Tuple.first >> String.length) |> List.maximum |> Maybe.withDefault 0

        headerString ( name, value ) =
            (String.padRight maxNameLength ' ' name) ++ " : " ++ value
    in
        Html.div []
            [ Html.h5 [ Styles.bottomBordered ] [ text "Status" ]
            , Html.div [ class ("alert " ++ statusAlert) ] [ text (toString status) ]
            , Html.h5 [ Styles.bottomBordered ] [ text "Headers" ]
            , ViewParts.codeBlock [ Styles.xSmall ] [ headers |> List.map headerString |> String.join "\n" |> text ]
            , Html.h5 [ Styles.bottomBordered ] [ text "Body" ]
            , ViewParts.codeBlock [ Styles.xSmall ] [ text body ]
            ]


textInputRequired : String -> Repo.Audit -> Repo.EntityId -> List Repo.AuditId -> (String -> x) -> String -> Html (Msg x)
textInputRequired inputLabel =
    Repo.ViewParts.textInputRequired "action" inputLabel False


select : String -> Repo.EntityId -> (String -> x) -> List Repo.ViewParts.SelectItem -> Html (Msg x)
select inputLabel =
    Repo.ViewParts.select "action" inputLabel False



-- Show


show : Set Repo.EntityId -> Repo.EntityDict Authentication -> Repo Aux Action -> Repo.Entity Action -> Html Actions.Msg
show usedActionIds authDict { dirtyDict, deleteModal, trialValues, trialResponse } ({ id, data } as entity) =
    let
        maybeDirtyEntity =
            Dict.get id dirtyDict

        trialData =
            case maybeDirtyEntity of
                Just ( dirtyEntity, _ ) ->
                    dirtyEntity.data

                Nothing ->
                    data
    in
        ViewParts.triPaneView
            [ titleShow usedActionIds maybeDirtyEntity entity
            , Z.lazy deleteModalDialog deleteModal
            ]
            [ mainFormShow authDict entity maybeDirtyEntity ]
            [ trialForm trialValues trialData ]
            [ Z.lazy trialResultCard trialResponse ]


titleShow : Set Repo.EntityId -> Maybe ( Repo.Entity Action, Repo.Audit ) -> Repo.Entity Action -> Html Actions.Msg
titleShow usedActionIds maybeDirtyEntity ({ id, updatedAt, data } as entity) =
    Html.div
        [ class "d-flex justify-content-between align-items-center pb-2"
        , Styles.bottomBordered
        ]
        [ Html.div []
            [ Html.h2 [ class "mb-2" ]
                [ logo "align-bottom mr-2" data.type_
                , text (toString data.type_)
                , text (" Action : " ++ data.label)
                ]
            , Html.p [ class "text-muted mb-0", Styles.xSmall ]
                [ text ("ID : " ++ id)
                , text (", Last updated at : " ++ (Utils.timestampToString updatedAt))
                ]
            ]
        , Html.div []
            [ Z.lazy2 editToggleButton maybeDirtyEntity entity
            , Z.lazy2 deleteButton usedActionIds entity
            ]
        ]
        |> Html.map Actions.RepoMsg


editToggleButton : Maybe ( Repo.Entity Action, Repo.Audit ) -> Repo.Entity Action -> Html (Msg Action)
editToggleButton maybeDirtyEntity ({ id } as entity) =
    case maybeDirtyEntity of
        Just dirtyEntity ->
            stdBtn Button.info [ Button.small, Button.onClick (CancelEdit id) ] False "Reset"

        Nothing ->
            stdBtn Button.primary [ Button.small, Button.onClick (StartEdit id entity) ] False "Edit"


deleteButton : Set Repo.EntityId -> Repo.Entity Action -> Html (Msg Action)
deleteButton usedActionIds entity =
    let
        ( isDisabled, buttonLabel ) =
            ite (Set.member entity.id usedActionIds) ( True, "Used" ) ( False, "Delete" )
    in
        stdBtn Button.danger [ Button.small, Button.onClick (ConfirmDelete entity) ] isDisabled buttonLabel


deleteModalDialog : Repo.ModalState Action -> Html Actions.Msg
deleteModalDialog { target, isShown } =
    ViewParts.modal
        (always CancelDelete)
        isShown
        [ class "modal-sm" ]
        [ text ("Deleting '" ++ target.data.label ++ "'") ]
        [ text "Are you sure?" ]
        [ stdBtn Button.danger [ Button.onClick (Delete target.id) ] False "Yes, delete"
        , stdBtn Button.secondary [ Button.onClick CancelDelete ] False "Cancel"
        ]
        |> Html.map Actions.RepoMsg


mainFormShow : Repo.EntityDict Authentication -> Repo.Entity Action -> Maybe ( Repo.Entity Action, Repo.Audit ) -> Html Actions.Msg
mainFormShow authDict entity maybeDirtyEntity =
    let
        ( notEditing, ( { id, data }, audit ) as dirtyEntity ) =
            case maybeDirtyEntity of
                Just de ->
                    ( False, de )

                Nothing ->
                    ( True, ( entity, Repo.dummyAudit ) )

        readyToUpdate =
            (data /= entity.data)
                && case data.type_ of
                    Actions.Hipchat ->
                        Actions.Hipchat.isValid dirtyEntity

                    Actions.Http ->
                        Actions.isValid dirtyEntity
    in
        [ submitButton "action" readyToUpdate "Update" ]
            |> (++) (mainFormInputs authDict id audit data)
            |> (List.singleton << Html.fieldset [ Attr.disabled notEditing ])
            |> Html.form [ Attr.id "action", Html.Events.onSubmit (ite readyToUpdate (Update id data) NoOp) ]
            |> ViewParts.cardBlock [] "" Nothing
            |> Html.map Actions.RepoMsg
