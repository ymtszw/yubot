module Polls.View exposing (..)

import Html exposing (Html, text)
import Html.Attributes exposing (colspan, align)
import Html.Utils exposing (atext, mx2Button, toggleSortOnClick, toDateString, intervalToString)
import Bootstrap.Table as Table exposing (table, th, tr, td, cellAttr)
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Resource exposing (..)
import Resource.Messages exposing (Msg(..))
import Polls exposing (Poll, dummyPoll)
import Poller.Styles exposing (sorting)


listView : Resource Poll -> Html (Msg Poll)
listView pollRs =
    table
        { options = [ Table.striped ]
        , thead =
            Table.simpleThead
                [ th (List.map cellAttr [ sorting, toggleSortOnClick .url pollRs.listSort ]) [ text "URL" ]
                , th (List.map cellAttr [ sorting, toggleSortOnClick .interval pollRs.listSort ]) [ text "Interval" ]
                , th (List.map cellAttr [ sorting, toggleSortOnClick .updatedAt pollRs.listSort ]) [ text "Updated At" ]
                , th [] [ text "Actions" ]
                ]
        , tbody = Table.tbody [] <| rows pollRs.list
        }


rows : List Poll -> List (Table.Row (Msg Poll))
rows polls =
    case polls of
        [] ->
            [ createRow ]

        nonEmpty ->
            polls |> List.map pollRow |> (::) createRow


createRow : Table.Row (Msg Poll)
createRow =
    tr []
        [ td ([ colspan 5, align "center" ] |> List.map cellAttr)
            [ editPollButton dummyPoll Button.primary "Create!" ]
        ]


editPollButton : Poll -> Button.Option (Msg Poll) -> String -> Html (Msg Poll)
editPollButton poll option string =
    mx2Button (OnEditModal Modal.visibleState poll) option string


pollRow : Poll -> Table.Row (Msg Poll)
pollRow poll =
    tr []
        [ td [] (atext poll.url)
        , td [] [ text (intervalToString poll.interval) ]
        , td [] [ text (toDateString poll.updatedAt) ]
        , td []
            [ editPollButton poll Button.primary "Update"
            , mx2Button (OnDeleteModal Modal.visibleState poll) Button.danger "Delete"
            ]
        ]
