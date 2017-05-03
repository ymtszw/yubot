module Polls.View exposing (listView)

import Html exposing (Html, text)
import Html.Attributes exposing (colspan, align)
import Html.Utils exposing (atext, mx2Button, toggleSortOnClick)
import Bootstrap.Table as Table exposing (table, th, tr, td, cellAttr)
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Utils exposing (timestampToString)
import Resource exposing (..)
import Resource.Messages exposing (Msg(..))
import Polls exposing (Poll, dummyPoll, intervalToString)
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
        [ td (List.map cellAttr [ colspan 5, align "center" ])
            [ editPollButton dummyPoll [ Button.primary, Button.small ] "Create!" ]
        ]


editPollButton : Poll -> List (Button.Option (Msg Poll)) -> String -> Html (Msg Poll)
editPollButton poll options string =
    mx2Button (OnEditModal Modal.visibleState poll) options string


pollRow : Poll -> Table.Row (Msg Poll)
pollRow poll =
    tr []
        [ td [] (atext poll.url)
        , td [] [ text (intervalToString poll.interval) ]
        , td [] [ text (timestampToString poll.updatedAt) ]
        , td []
            [ editPollButton poll [ Button.primary, Button.small ] "Update"
            , mx2Button (OnDeleteModal Modal.visibleState poll) [ Button.danger, Button.small ] "Delete"
            ]
        ]
