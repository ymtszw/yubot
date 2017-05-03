module Polls.ModalView exposing (deleteModalView, editModalView)

import Html exposing (Html, text, p, small)
import Html.Attributes exposing (for, value, selected, class)
import Html.Utils exposing (atext, mx2Button)
import Bootstrap.Button as Button exposing (Option)
import Bootstrap.Modal as Modal
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Select as Select
import Utils
import Resource exposing (..)
import Resource.Messages exposing (Msg(..))
import Polls exposing (Poll, Interval, dummyPoll, intervalToString)
import Authentications as Auth


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
                [ mx2Button (OnDeleteConfirmed target.id) [ Button.danger ] "Yes, delete"
                , mx2Button (OnDeleteModal Modal.hiddenState target) [] "Cancel"
                ]
            |> Modal.view pollRs.deleteModal.modalState


editModalView : List Auth.Authentication -> Resource Poll -> Html (Msg Poll)
editModalView authList pollRs =
    let
        target =
            pollRs.editModal.target

        stateToMsg state =
            OnEditModal state target

        titleText poll =
            if poll.id == "" then
                text "Creating Poll"
            else
                text "Updating Poll"
    in
        Modal.config stateToMsg
            |> Modal.h4 [] [ titleText target ]
            |> Modal.body []
                [ headerText target
                , editForm authList target
                ]
            |> Modal.footer []
                [ mx2Button (OnEditModal Modal.hiddenState target) [ Button.primary ] "Submit"
                , mx2Button (OnEditModal Modal.hiddenState target) [] "Cancel"
                ]
            |> Modal.view pollRs.editModal.modalState


headerText : Poll -> Html (Msg Poll)
headerText poll =
    if poll.id == "" then
        text "New poll!"
    else
        small [] [ text ("ID: " ++ poll.id) ]


editForm : List Auth.Authentication -> Poll -> Html (Msg Poll)
editForm authList poll =
    Form.form []
        [ Form.group []
            [ Form.label [ for "poll-url" ] [ text "URL" ]
            , Input.url
                [ Input.id "poll-url"
                , Input.value poll.url
                , Input.onInput (\url -> OnEditInput { poll | url = url })
                ]
            , authCheck authList poll
            ]
        , authSelect authList poll
        , Form.group []
            [ Form.label [ for "poll-interval" ] [ text "Interval" ]
            , intervalSelect poll
            ]
        ]


authCheck : List Auth.Authentication -> Poll -> Html (Msg Poll)
authCheck authList poll =
    let
        ( disabled, headAuthId ) =
            case authList of
                [] ->
                    ( True, "" )

                hd :: _ ->
                    ( False, hd.id )

        checked =
            case poll.auth of
                Nothing ->
                    False

                Just _ ->
                    True
    in
        small []
            [ Checkbox.checkbox
                [ Checkbox.checked checked
                , Checkbox.disabled disabled
                , Checkbox.onCheck (authOnCheck headAuthId poll)
                ]
                "Require authentication?"
            ]


authOnCheck : Utils.EntityId -> Poll -> Bool -> Msg Poll
authOnCheck headAuthId poll checked =
    case checked of
        False ->
            OnEditInput { poll | auth = Nothing }

        True ->
            OnEditInput { poll | auth = Just headAuthId }


authSelect : List Auth.Authentication -> Poll -> Html (Msg Poll)
authSelect authList poll =
    let
        itemText auth =
            text (auth.name ++ " (" ++ auth.id ++ ")")

        item auth =
            if poll.auth == Just auth.id then
                Select.item [ value auth.id, selected True ] [ itemText auth ]
            else
                Select.item [ value auth.id ] [ itemText auth ]

        select =
            authList
                |> Auth.listForPoll
                |> List.map item
                |> Select.select
                    [ Select.id "poll-auth"
                    , Select.onInput (\authId -> OnEditInput { poll | auth = Just authId })
                    ]
    in
        case poll.auth of
            Nothing ->
                text ""

            Just _ ->
                select


intervalSelect : Poll -> Html (Msg Poll)
intervalSelect poll =
    let
        item v =
            if v == poll.interval then
                Select.item [ value v, selected True ] [ text (intervalToString v) ]
            else
                Select.item [ value v ] [ text (intervalToString v) ]
    in
        [ "1", "3", "5", "10", "30", "hourly", "daily" ]
            |> List.map item
            |> Select.select
                [ Select.id "poll-interval"
                , Select.onInput (\interval -> OnEditInput { poll | interval = interval })
                ]
