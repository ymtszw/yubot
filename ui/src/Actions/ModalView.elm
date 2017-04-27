module Actions.ModalView exposing (..)

import Html exposing (Html, text, p, small)
import Html.Attributes exposing (for, value, selected)
import Html.Utils exposing (atext, mx2Button, intervalToString)
import Bootstrap.Button as Button exposing (Option)
import Bootstrap.Modal as Modal
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Select as Select
import Resource exposing (..)
import Resource.Messages exposing (Msg(..))
import Actions exposing (Action, dummyAction)


deleteModalView : Resource Action -> Html (Msg Action)
deleteModalView actionRs =
    let
        target =
            actionRs.deleteModal.target

        stateToMsg state =
            OnDeleteModal state target
    in
        Modal.config stateToMsg
            |> Modal.h4 [] [ text "Deleting Action" ]
            |> Modal.body []
                [ p [] [ text ("ID: " ++ target.id) ]
                , p [] (atext ("URL: " ++ target.url))
                , p [] [ text "Are you sure?" ]
                ]
            |> Modal.footer []
                [ mx2Button (OnDeleteConfirmed target.id) Button.danger "Yes, delete"
                , mx2Button (OnDeleteModal Modal.hiddenState target) Button.outlineSecondary "Cancel"
                ]
            |> Modal.view actionRs.deleteModal.modalState


editModalView : Resource Action -> Html (Msg Action)
editModalView actionRs =
    let
        target =
            actionRs.editModal.target

        stateToMsg state =
            OnEditModal state target

        titleText action =
            if action == dummyAction then
                text "Creating Action"
            else
                text "Updating Action"
    in
        Modal.config stateToMsg
            |> Modal.h4 [] [ titleText target ]
            |> Modal.body []
                [ headerText target
                , editForm target
                ]
            |> Modal.footer []
                [ mx2Button (OnEditModal Modal.hiddenState target) Button.primary "Submit"
                , mx2Button (OnEditModal Modal.hiddenState target) Button.outlineSecondary "Cancel"
                ]
            |> Modal.view actionRs.editModal.modalState


headerText : Action -> Html (Msg Action)
headerText action =
    case action.id of
        "" ->
            text "New action!"

        id ->
            small [] [ text ("ID: " ++ id) ]


editForm : Action -> Html (Msg Action)
editForm action =
    Form.form []
        [ Form.group []
            [ Form.label [ for "action-method" ] [ text "Method" ]
            , methodSelect action.method
            ]
        , Form.group []
            [ Form.label [ for "action-url" ] [ text "URL" ]
            , Input.url [ Input.id "action-url", Input.defaultValue action.url ]
            ]
        ]


methodSelect : String -> Html (Msg Action)
methodSelect method =
    let
        item v =
            if v == method then
                Select.item [ value v, selected True ] [ text (String.toUpper v) ]
            else
                Select.item [ value v ] [ text (String.toUpper v) ]
    in
        [ "get", "post", "put" ]
            |> List.map item
            |> Select.select [ Select.id "action-method" ]
