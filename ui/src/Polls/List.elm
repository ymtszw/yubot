module Polls.List exposing (..)

import Html exposing (Html, text)
import Bootstrap.Table as Table exposing (table, th, tr, td)
import Bootstrap.Button as Button exposing (button)
import Polls exposing (Poll, Msg)

view : List Poll -> Html Msg
view polls =
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
            [ button [ Button.danger ] [ text "Delete" ]
            ]
        ]

intervalToText : String -> String
intervalToText interval =
    case String.toInt interval of
        Ok _ ->
            "every " ++ interval ++ " min."
        Err _ ->
            interval
