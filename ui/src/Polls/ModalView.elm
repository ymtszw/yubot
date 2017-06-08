module Polls.ModalView exposing (deleteModalView)

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
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Polls exposing (Poll, Interval, dummyPoll, intervalToString)
import Actions exposing (Action)
import Actions.View
import Authentications as Auth exposing (Authentication)
import Authentications.View exposing (authCheck, authSelect)
import Styles


deleteModalView : Repo Poll -> Html (Msg Poll)
deleteModalView pollRepo =
    let
        target =
            pollRepo.deleteModal.target

        stateToMsg state =
            OnDeleteModal state target
    in
        Modal.config stateToMsg
            |> Modal.h4 [] [ text "Deleting Poll" ]
            |> Modal.body []
                [ p [] [ text ("ID: " ++ target.id) ]
                , p [] (atext ("URL: " ++ target.data.url))
                , p [] [ text "Are you sure?" ]
                ]
            |> Modal.footer []
                [ mx2Button (OnDeleteConfirmed target.id) [ Button.danger ] "Yes, delete"
                , mx2Button (OnDeleteModal Modal.hiddenState target) [] "Cancel"
                ]
            |> Modal.view pollRepo.deleteModal.modalState



-- editModalView : List Action -> List Authentication -> Repo Poll -> Html (Msg Poll)
-- editModalView actionList authList pollRs =
--     let
--         target =
--             pollRs.editModal.target
--
--         stateToMsg state =
--             OnEditModal state target
--
--         ( headerText, titleText ) =
--             if target.id == "" then
--                 ( text "New poll!", text "Creating Poll" )
--             else
--                 ( small [] [ text ("ID: " ++ target.id) ]
--                 , text "Updating Poll"
--                 )
--     in
--         Modal.config stateToMsg
--             |> Modal.large
--             |> Modal.h4 [] [ titleText ]
--             |> Modal.body []
--                 [ headerText
--                 , editForm actionList authList target
--                 ]
--             |> Modal.footer []
--                 [ mx2Button (OnEditModal Modal.hiddenState target) [] "Cancel"
--                 ]
--             |> Modal.view pollRs.editModal.modalState


editForm : List (Repo.Entity Action) -> List (Repo.Entity Authentication) -> Repo.Entity Poll -> Html (Msg Poll)
editForm actionList authList poll =
    let
        pollData =
            poll.data

        maybeCurrentAction =
            LE.find (\action -> action.id == pollData.action) actionList
    in
        Form.form []
            [ Form.group []
                [ Form.label [ for "poll-url" ] [ text "URL" ]
                , Input.url
                    [ Input.id "poll-url"
                    , Input.value pollData.url
                    , Input.onInput (\url -> OnEditInput { pollData | url = url } [])
                    ]
                , authCheck authList pollData.auth (authOnCheck poll)
                ]
            , authSelect (Auth.listForPoll authList) "poll" pollData.auth (authOnSelect poll)
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


authOnCheck : Repo.Entity Poll -> Repo.EntityId -> Bool -> Msg Poll
authOnCheck { data } headAuthId checked =
    case checked of
        False ->
            OnEditInput { data | auth = Nothing } []

        True ->
            OnEditInput { data | auth = Just headAuthId } []


authOnSelect : Repo.Entity Poll -> Repo.EntityId -> Msg Poll
authOnSelect { data } authId =
    OnEditInput { data | auth = Just authId } []


intervalSelect : Repo.Entity Poll -> Html (Msg Poll)
intervalSelect { data } =
    let
        item v =
            Select.item [ value v, selected (v == data.interva) ] [ text (intervalToString v) ]
    in
        [ "1", "3", "5", "10", "30", "hourly", "daily" ]
            |> List.map item
            |> Select.select
                [ Select.id "poll-interval"
                , Select.onInput (\interval -> OnEditInput { data | interval = interval } [])
                ]


actionSelect : List (Repo.Entity Action) -> Repo.Entity Poll -> Html (Msg Poll)
actionSelect actionList { data } =
    let
        header =
            Select.item
                [ value ""
                , selected (data.action == "")
                , disabled True
                , Styles.hidden
                ]
                [ text "-- Select Action --" ]

        itemLabel action =
            case action.data.label of
                Nothing ->
                    action.id

                Just label ->
                    label ++ " (" ++ action.id ++ ")"

        item action =
            Select.item [ value action.id, selected (data.action == action.id) ] [ text (itemLabel action) ]

        emptyStringList action =
            List.map (\_ -> "") action.data.bodyTemplate.variables

        onInputMessage actionId =
            case LE.find (\a -> a.id == actionId) actionList of
                Just action ->
                    OnEditInput { data | action = actionId, filters = (emptyStringList action) } []

                Nothing ->
                    -- Should not happen
                    OnEditInput { data | action = actionId } []
    in
        actionList
            |> List.map item
            |> (::) header
            |> Select.select
                [ Select.id "poll-action"
                , Select.onInput onInputMessage
                ]


actionPreview : Maybe (Repo.Entity Action) -> Repo.Entity Poll -> Html (Msg Poll)
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
        case poll.data.action of
            "" ->
                -- dummyPoll
                text ""

            id ->
                previewOrError


filterInput : Maybe (Repo.Entity Action) -> Repo.Entity Poll -> List (Html (Msg Poll))
filterInput maybeAction { data } =
    let
        variableAndFilterPairs action =
            LE.zip action.data.bodyTemplate.variables data.filters

        onInputMessage index newFilter =
            case LE.setAt index newFilter data.filters of
                Just newFilters ->
                    OnEditInput { data | filters = newFilters } []

                Nothing ->
                    -- Should not happen
                    OnEditInput data []

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
        case data.action of
            "" ->
                -- dummyPoll
                [ Alert.info [ text "No variables." ] ]

            id ->
                inputs
