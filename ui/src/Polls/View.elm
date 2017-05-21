module Polls.View exposing (cardsView, listView)

import Html exposing (Html, text)
import Html.Attributes exposing (class, colspan, align)
import Html.Utils exposing (atext, mx2Button, toggleSortOnClick)
import Bootstrap.Table as Table exposing (table, th, tr, td, cellAttr)
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Utils
import Resource exposing (..)
import Resource.Messages exposing (Msg(..))
import Polls exposing (Poll)
import Poller.Styles as Styles


cardsView : Resource Poll -> Html (Msg Poll)
cardsView pollRs =
    let
        card poll =
            Html.div [ class "card text-center" ]
                [ Html.div [ class "card-header" ] [ Html.h4 [] [ text (Utils.shortenUrl poll.url) ] ]
                , Html.div [ class "card-block alert-success" ]
                    [ Html.h4 [ class "card-title" ] [ text "Status: OK" ]
                    , Html.p [ class "card-text" ] [ text ("Run: " ++ (Polls.intervalToString poll.interval)) ]
                    , Html.p [ class "card-text" ] [ text ("Action: " ++ poll.action) ]
                    ]
                , Html.div [ class "card-footer" ]
                    [ Html.small [ Styles.xSmall ] [ text ("Last run at: " ++ (Utils.timestampToString poll.updatedAt)) ] ]
                ]

        cardWithWrap poll =
            Html.div [ class "col-lg-3 col-md-4 col-sm-6 my-2" ] [ card poll ]
    in
        pollRs.list
            |> List.map cardWithWrap
            |> Html.div [ class "row" ]


listView : Resource Poll -> Html (Msg Poll)
listView pollRs =
    table
        { options = [ Table.striped ]
        , thead =
            Table.simpleThead
                [ th (List.map cellAttr [ Styles.sorting, toggleSortOnClick .url pollRs.listSort ]) [ text "URL" ]
                , th (List.map cellAttr [ Styles.sorting, toggleSortOnClick .interval pollRs.listSort ]) [ text "Interval" ]
                , th (List.map cellAttr [ Styles.sorting, toggleSortOnClick .updatedAt pollRs.listSort ]) [ text "Updated At" ]
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
            [ editPollButton Polls.dummyPoll [ Button.primary, Button.small ] "Create!" ]
        ]


editPollButton : Poll -> List (Button.Option (Msg Poll)) -> String -> Html (Msg Poll)
editPollButton poll options string =
    mx2Button (OnEditModal Modal.visibleState poll) options string


pollRow : Poll -> Table.Row (Msg Poll)
pollRow poll =
    tr []
        [ td [] (atext poll.url)
        , td [] [ text (Polls.intervalToString poll.interval) ]
        , td [] [ text (Utils.timestampToString poll.updatedAt) ]
        , td []
            [ editPollButton poll [ Button.primary, Button.small ] "Update"
            , mx2Button (OnDeleteModal Modal.visibleState poll) [ Button.danger, Button.small ] "Delete"
            ]
        ]
