module Polls.View exposing (..)

import Date
import Html exposing (Html, text, p)
import Html.Attributes exposing (colspan, for, value, selected, align)
import Html.Events exposing (onClick)
import Html.Utils exposing (atext, mx2Button)
import Bootstrap.Table as Table exposing (table, th, tr, td, cellAttr)
import Bootstrap.Button as Button exposing (Option)
import Bootstrap.Modal as Modal
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Select as Select
import Polls exposing (..)
import Polls.Messages exposing (Msg(..))
import Poller.Styles exposing (sorting)


listView : List Poll -> Maybe Sorter -> Html Msg
listView polls pollsSort =
    table
        { options = [ Table.striped ]
        , thead =
            Table.simpleThead
                [ th [] [ text "ID" ]
                , th (List.map cellAttr [ sorting, toggleSortOnClick .url pollsSort ]) [ text "URL" ]
                , th (List.map cellAttr [ sorting, toggleSortOnClick .interval pollsSort ]) [ text "Interval" ]
                , th (List.map cellAttr [ sorting, toggleSortOnClick .updatedAt pollsSort ]) [ text "Updated At" ]
                , th [] [ text "Actions" ]
                ]
        , tbody = Table.tbody [] <| rows polls
        }


toggleSortOnClick : (Poll -> String) -> Maybe Sorter -> Html.Attribute Msg
toggleSortOnClick newCompareBy maybeSorter =
    let
        order =
            case maybeSorter of
                Nothing ->
                    Asc

                Just ( oldCompareBy, oldOrder ) ->
                    case oldOrder of
                        Asc ->
                            Desc

                        Desc ->
                            Asc
    in
        onClick (OnSort ( newCompareBy, order ))


rows : List Poll -> List (Table.Row Msg)
rows polls =
    case polls of
        [] ->
            [ createRow ]

        nonEmpty ->
            polls |> List.map pollRow |> (::) createRow


createRow : Table.Row Msg
createRow =
    tr []
        [ td ([ colspan 5, align "center" ] |> List.map cellAttr)
            [ editPollButton dummyPoll Button.primary "Create!" ]
        ]


editPollButton : Poll -> Option Msg -> String -> Html Msg
editPollButton poll option string =
    mx2Button (OnEditModal Modal.visibleState poll) option string


pollRow : Poll -> Table.Row Msg
pollRow poll =
    tr []
        [ td [] [ text poll.id ]
        , td [] (atext poll.url)
        , td [] [ text (intervalToText poll.interval) ]
        , td [] [ text (toDateString poll.updatedAt) ]
        , td []
            [ editPollButton poll Button.primary "Update"
            , mx2Button (OnDeleteModal Modal.visibleState poll) Button.danger "Delete"
            ]
        ]


intervalToText : String -> String
intervalToText interval =
    case String.toInt interval of
        Ok _ ->
            "every " ++ interval ++ " min."

        Err _ ->
            interval


toDateString : String -> String
toDateString string =
    case Date.fromString string of
        Ok date ->
            toString date

        Err x ->
            "Invalid updatedAt!"


deleteModalView : DeleteModal -> Html Msg
deleteModalView deleteModal =
    let
        stateToMsg state =
            OnDeleteModal state deleteModal.poll
    in
        Modal.config stateToMsg
            |> Modal.h4 [] [ text "Deleting Poll" ]
            |> Modal.body []
                [ p [] [ text ("ID: " ++ deleteModal.poll.id) ]
                , p [] (atext ("URL: " ++ deleteModal.poll.url))
                , p [] [ text "Are you sure?" ]
                ]
            |> Modal.footer []
                [ mx2Button (OnDeleteConfirmed deleteModal.poll.id) Button.danger "Yes, delete"
                , mx2Button (OnDeleteModal Modal.hiddenState deleteModal.poll) Button.outlineSecondary "Cancel"
                ]
            |> Modal.view deleteModal.modalState


editModalView : EditModal -> Html Msg
editModalView editModal =
    let
        stateToMsg state =
            OnEditModal state editModal.poll

        titleText poll =
            if poll == dummyPoll then
                text "Creating Poll"
            else
                text "Updating Poll"
    in
        Modal.config stateToMsg
            |> Modal.h4 [] [ titleText editModal.poll ]
            |> Modal.body []
                [ headerText editModal.poll
                , editForm editModal.poll
                ]
            |> Modal.footer []
                [ mx2Button (OnEditModal Modal.hiddenState editModal.poll) Button.primary "Submit"
                , mx2Button (OnEditModal Modal.hiddenState editModal.poll) Button.outlineSecondary "Cancel"
                ]
            |> Modal.view editModal.modalState


headerText : Poll -> Html Msg
headerText poll =
    case poll.id of
        "" ->
            text "New poll!"

        id ->
            text ("ID: " ++ id)


editForm : Poll -> Html Msg
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


intervalSelect : String -> Html Msg
intervalSelect interval =
    let
        item v =
            if v == interval then
                Select.item [ value v, selected True ] [ text (intervalToText v) ]
            else
                Select.item [ value v ] [ text (intervalToText v) ]
    in
        [ "1", "3", "5", "10", "30", "hourly", "daily" ]
            |> List.map item
            |> Select.select [ Select.id "interval" ]
