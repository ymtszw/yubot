module Polls.ModalView exposing (..)

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
import Polls exposing (Poll, dummyPoll)


deleteModalView : Resource Poll -> Html (Msg Poll)
deleteModalView pollRs =
    let
        target =
            pollRs.deleteModal.target

        stateToMsg state =
            OnDeleteModal state target
    in
        Modal.config stateToMsg
            |> Modal.h4 [] [ text "Deleting Poll" ]
            |> Modal.body []
                [ p [] [ text ("ID: " ++ target.id) ]
                , p [] (atext ("URL: " ++ target.url))
                , p [] [ text "Are you sure?" ]
                ]
            |> Modal.footer []
                [ mx2Button (OnDeleteConfirmed target.id) Button.danger "Yes, delete"
                , mx2Button (OnDeleteModal Modal.hiddenState target) Button.outlineSecondary "Cancel"
                ]
            |> Modal.view pollRs.deleteModal.modalState


editModalView : Resource Poll -> Html (Msg Poll)
editModalView pollRs =
    let
        target =
            pollRs.editModal.target

        stateToMsg state =
            OnEditModal state target

        titleText poll =
            if poll == dummyPoll then
                text "Creating Poll"
            else
                text "Updating Poll"
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
            |> Modal.view pollRs.editModal.modalState


headerText : Poll -> Html (Msg Poll)
headerText poll =
    case poll.id of
        "" ->
            text "New poll!"

        id ->
            small [] [ text ("ID: " ++ id) ]


editForm : Poll -> Html (Msg Poll)
editForm poll =
    Form.form []
        [ Form.group []
            [ Form.label [ for "url" ] [ text "URL" ]
            , Input.url [ Input.id "url", Input.defaultValue poll.url ]
            ]
        , Form.group []
            [ Form.label [ for "interval" ] [ text "Interval" ]
            , intervalSelect poll.interval
            ]
        ]


intervalSelect : String -> Html (Msg Poll)
intervalSelect interval =
    let
        item v =
            if v == interval then
                Select.item [ value v, selected True ] [ text (intervalToString v) ]
            else
                Select.item [ value v ] [ text (intervalToString v) ]
    in
        [ "1", "3", "5", "10", "30", "hourly", "daily" ]
            |> List.map item
            |> Select.select [ Select.id "interval" ]
