module Polls.List exposing (..)

import Html exposing (..)
import Polls exposing (Poll, Msg)

view : List Poll -> Html Msg
view polls =
    div []
        [ list polls
        ]

list : List Poll -> Html Msg
list polls =
    div []
        [ table []
            [ thead []
                [ tr []
                    [ th [] [ text "ID"]
                    , th [] [ text "UpdatedAt"]
                    ]
                ]
            , tbody [] (List.map pollRow polls)
            ]
        ]

pollRow : Poll -> Html Msg
pollRow poll =
    tr []
        [ td [] [ text poll.id ]
        , td [] [ text poll.updatedAt ]
        ]
