module Polls.View exposing (..)

import Html exposing (Html, text)
import Bootstrap.Table as Table exposing (table, th, tr, td)
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Polls exposing (Poll, DeleteModal)
import Polls.Messages exposing (Msg(OnDeleteModal))

listView : List Poll -> Html Msg
listView polls =
    table
        { options = [ Table.striped ]
        , thead = Table.simpleThead
            [ th [] [ text "ID" ]
            , th [] [ text "URL" ]
            , th [] [ text "Interval" ]
            , th [] [ text "Updated At" ]
            , th [] [ text "Actions" ]
            ]
        , tbody = Table.tbody [] (List.map pollRow polls)
        }

pollRow : Poll -> Table.Row Msg
pollRow poll =
    tr []
        [ td [] [ text poll.id ]
        , td [] [ text poll.url ]
        , td [] [ text (intervalToText poll.interval) ]
        , td [] [ text (toString poll.updatedAt) ]
        , td []
            [ Button.button
                [ Button.danger
                , Button.onClick (OnDeleteModal Modal.visibleState poll)
                ]
                [ text "Delete" ]
            ]
        ]

intervalToText : String -> String
intervalToText interval =
    case String.toInt interval of
        Ok _ ->
            "every " ++ interval ++ " min."
        Err _ ->
            interval

deleteModalView : DeleteModal -> Html Msg
deleteModalView deleteModal =
    let
        stateToMsg state =
            OnDeleteModal state deleteModal.poll
    in
        Modal.config stateToMsg
            |> Modal.h4 [] [ text ("Deleting Poll " ++ deleteModal.poll.id) ]
            |> Modal.body [] [ text "Are you sure?" ]
            |> Modal.footer []
                [ Button.button
                    [ Button.danger ]
                    [ text "Yes, delete" ]
                , Button.button
                    [ Button.outlinePrimary
                    , Button.onClick (OnDeleteModal Modal.hiddenState deleteModal.poll)
                    ]
                    [ text "Cancel" ]
                ]
            |> Modal.view deleteModal.modalState
