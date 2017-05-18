module Polls.ModalView exposing (deleteModalView, editModalView)

import Html exposing (Html, text, div, p, small, pre, code)
import Html.Attributes exposing (for, value, selected, class, disabled)
import Html.Utils exposing (atext, mx2Button)
import Bootstrap.Button as Button exposing (Option)
import Bootstrap.Modal as Modal
import Bootstrap.Card as Card
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Form.Select as Select
import Bootstrap.Alert as Alert
import List.Extra as LE
import Utils
import Resource exposing (..)
import Resource.Messages exposing (Msg(..))
import Polls exposing (Poll, Interval, dummyPoll, intervalToString)
import Actions exposing (Action)
import Actions.View
import Authentications as Auth exposing (Authentication)
import Authentications.View exposing (authCheck)


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


editModalView : List Action -> List Authentication -> Resource Poll -> Html (Msg Poll)
editModalView actionList authList pollRs =
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
            |> Modal.large
            |> Modal.h4 [] [ titleText target ]
            |> Modal.body []
                [ headerText target
                , editForm actionList authList target
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


editForm : List Action -> List Authentication -> Poll -> Html (Msg Poll)
editForm actionList authList poll =
    let
        maybeCurrentAction =
            LE.find (\action -> action.id == poll.action) actionList
    in
        Form.form []
            [ Form.group []
                [ Form.label [ for "poll-url" ] [ text "URL" ]
                , Input.url
                    [ Input.id "poll-url"
                    , Input.value poll.url
                    , Input.onInput (\url -> OnEditInput { poll | url = url })
                    ]
                , authCheck authList poll.auth (authOnCheck poll)
                ]
            , authSelect authList poll
            , Form.group []
                [ Form.label [ for "poll-interval" ] [ text "Interval" ]
                , intervalSelect poll
                ]
            , Form.group []
                [ Form.label [ for "poll-action" ] [ text "Action" ]
                , actionSelect actionList poll
                ]
            , actionPreview maybeCurrentAction poll
            , filterInput maybeCurrentAction poll
                |> (::) (Form.label [ for "poll-filters-0" ] [ text "Jq Filters" ])
                |> Form.group []
            ]


authOnCheck : Poll -> Utils.EntityId -> Bool -> Msg Poll
authOnCheck poll headAuthId checked =
    case checked of
        False ->
            OnEditInput { poll | auth = Nothing }

        True ->
            OnEditInput { poll | auth = Just headAuthId }


authSelect : List Authentication -> Poll -> Html (Msg Poll)
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
                Form.group []
                    [ Form.label [ for "poll-auth" ] [ text "Credential for URL" ]
                    , select
                    ]


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


actionSelect : List Action -> Poll -> Html (Msg Poll)
actionSelect actionList poll =
    let
        header poll =
            Select.item
                [ value ""
                , selected (poll.action == "")
                , disabled True
                , class "select-header"
                ]
                [ text "-- Select Action --" ]

        itemLabel action =
            case action.label of
                Nothing ->
                    action.id

                Just label ->
                    label ++ " (" ++ action.id ++ ")"

        item action =
            Select.item [ value action.id, selected (poll.action == action.id) ] [ text (itemLabel action) ]

        emptyStringList action =
            List.map (\_ -> "") action.bodyTemplate.variables

        onInputMessage actionId =
            case LE.find (\a -> a.id == actionId) actionList of
                Just action ->
                    OnEditInput { poll | action = actionId, filters = (emptyStringList action) }

                Nothing ->
                    -- Should not happen
                    OnEditInput { poll | action = actionId }
    in
        actionList
            |> List.map item
            |> (::) (header poll)
            |> Select.select
                [ Select.id "poll-action"
                , Select.onInput onInputMessage
                ]


actionPreview : Maybe Action -> Poll -> Html (Msg Poll)
actionPreview maybeAction poll =
    let
        previewOrError =
            case maybeAction of
                Just action ->
                    Card.config []
                        |> Card.block [] [ Card.text [] [ Actions.View.preview action ] ]
                        |> Card.view

                Nothing ->
                    Alert.danger [ text "Cannot find action!" ]
    in
        case poll.action of
            "" ->
                -- dummyPoll
                text ""

            id ->
                previewOrError


filterInput : Maybe Action -> Poll -> List (Html (Msg Poll))
filterInput maybeAction poll =
    let
        variableAndFilterPairs action =
            LE.zip action.bodyTemplate.variables poll.filters

        onInputMessage index newFilter =
            case LE.setAt index newFilter poll.filters of
                Just newFilters ->
                    OnEditInput { poll | filters = newFilters }

                Nothing ->
                    -- Should not happen
                    OnEditInput poll

        inputgroup index ( variable, currentFilter ) =
            InputGroup.text
                [ Input.id ("poll-filters-" ++ (toString index))
                , Input.value currentFilter
                , Input.onInput (onInputMessage index)
                ]
                |> InputGroup.config
                |> InputGroup.predecessors [ InputGroup.span [] [ code [] [ text variable ] ] ]
                |> InputGroup.view

        inputs =
            case maybeAction of
                Just action ->
                    case variableAndFilterPairs action of
                        [] ->
                            [ Alert.info [ text "No variables." ] ]

                        pairs ->
                            pairs
                                |> List.indexedMap inputgroup
                                |> List.intersperse (Html.br [] [])

                Nothing ->
                    [ Alert.danger [ text "Cannot find action!" ] ]
    in
        case poll.action of
            "" ->
                -- dummyPoll
                [ Alert.info [ text "No variables." ] ]

            id ->
                inputs
