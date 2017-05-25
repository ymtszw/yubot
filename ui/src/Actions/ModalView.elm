module Actions.ModalView exposing (deleteModalView)

import Html exposing (Html, text)
import Html.Attributes exposing (for, value, selected)
import Html.Utils exposing (atext, mx2Button)
import Bootstrap.Button as Button exposing (Option)
import Bootstrap.Modal as Modal
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Select as Select
import Bootstrap.Form.Textarea as Textarea
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import StringTemplate exposing (StringTemplate)
import Actions exposing (Action)
import Actions.ViewParts
import Authentications exposing (Authentication)
import Authentications.View exposing (authCheck, authSelect)
import Poller.Styles as Styles


deleteModalView : Repo Action -> Html (Msg Action)
deleteModalView actionRepo =
    let
        target =
            actionRepo.deleteModal.target

        stateToMsg state =
            OnDeleteModal state target
    in
        Modal.config stateToMsg
            |> Modal.h4 [] [ text "Deleting Action" ]
            |> Modal.body []
                [ Html.p [] [ text ("ID: " ++ target.id) ]
                , Actions.ViewParts.preview target
                , Html.p [] [ text "Are you sure?" ]
                ]
            |> Modal.footer []
                [ mx2Button (OnDeleteConfirmed target.id) [ Button.danger ] "Yes, delete"
                , mx2Button (OnDeleteModal Modal.hiddenState target) [] "Cancel"
                ]
            |> Modal.view actionRepo.deleteModal.modalState



-- editModalView : List Authentication -> Repo Action -> Html (Msg Action)
-- editModalView authList actionRs =
--     let
--         target =
--             actionRs.editModal.target
--
--         stateToMsg state =
--             OnEditModal state target
--
--         ( headerText, titleText ) =
--             if target.id == "" then
--                 ( text "New action!", text "Creating Action" )
--             else
--                 ( small [] [ text ("ID: " ++ target.id) ]
--                 , text "Updating Action"
--                 )
--     in
--         Modal.config stateToMsg
--             |> Modal.large
--             |> Modal.h4 [] [ titleText ]
--             |> Modal.body []
--                 [ headerText
--                 , editForm authList target
--                 , Html.Utils.errorAlert actionRs.editModal.errorMessages
--                 ]
--             |> Modal.footer []
--                 [ mx2Button (OnEditModal Modal.hiddenState target) [ Button.primary ] "Submit"
--                 , mx2Button (OnEditModal Modal.hiddenState target) [] "Cancel"
--                 ]
--             |> Modal.view actionRs.editModal.modalState


editForm : List (Repo.Entity Authentication) -> Repo.Entity Action -> Html (Msg Action)
editForm authList { data } =
    Form.form []
        [ Form.group []
            [ Form.label [ for "action-label" ] [ text "Label" ]
            , Input.text
                [ Input.id "action-label"
                , Input.value (Maybe.withDefault "" data.label)
                , Input.onInput (\label -> OnEditInput { data | label = Just label } [])
                ]
            ]
        , Form.group []
            [ Form.label [ for "action-method" ] [ text "Method" ]
            , methodSelect data
            ]
        , Form.group []
            [ Form.label [ for "action-url" ] [ text "URL" ]
            , Input.url
                [ Input.id "action-url"
                , Input.value data.url
                , Input.onInput (\url -> OnEditInput { data | url = url } [])
                ]
            , authCheck authList data.auth (authOnCheck data)
            ]
        , authSelect authList "action" data.auth (authOnSelect data)
        , bodyTemplateInput data
        ]


methodSelect : Action -> Html (Msg Action)
methodSelect action =
    let
        item v =
            if v == action.method then
                Select.item [ value v, selected True ] [ text (String.toUpper v) ]
            else
                Select.item [ value v ] [ text (String.toUpper v) ]
    in
        [ "post", "put", "get" ]
            |> List.map item
            |> Select.select
                [ Select.id "action-method"
                , Select.onInput (\method -> OnEditInput { action | method = method } [])
                ]


authOnCheck : Action -> Repo.EntityId -> Bool -> Msg Action
authOnCheck action authId checked =
    case checked of
        False ->
            OnEditInput { action | auth = Nothing } []

        True ->
            OnEditInput { action | auth = Just authId } []


authOnSelect : Action -> Repo.EntityId -> Msg Action
authOnSelect action authId =
    OnEditInput { action | auth = Just authId } []


bodyTemplateInput : Action -> Html (Msg Action)
bodyTemplateInput action =
    Form.group []
        [ Form.label [ for "action-bodyTemplate" ] [ text "Body Template" ]
        , Textarea.textarea
            [ Textarea.id "action-bodyTemplate"
            , Textarea.attrs [ Styles.monospace ]
            , Textarea.rows 5
            , Textarea.value action.bodyTemplate.body
            , Textarea.onInput (bodyTemplateOnInput action)
            ]
        , Actions.ViewParts.variableList action.bodyTemplate.variables
        ]


bodyTemplateOnInput : Action -> StringTemplate.Body -> Msg Action
bodyTemplateOnInput action body =
    let
        ( newBodyTemplate, errorMessages ) =
            case StringTemplate.validate body of
                Ok vars ->
                    ( StringTemplate body vars, [] )

                Err message ->
                    ( action.bodyTemplate, [ message ] )
    in
        OnEditInput { action | bodyTemplate = newBodyTemplate } errorMessages
