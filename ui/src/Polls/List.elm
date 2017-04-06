module Polls.List exposing (..)

import Html exposing (Html, text)
import Bootstrap.Table as Table exposing (..)
import Polls exposing (Poll, Msg)

view : List Poll -> Html Msg
view polls =
    Table.table
        { options = [ Table.striped ]
        , thead = Table.simpleThead
            [ Table.th [] [ text "ID" ]
            , Table.th [] [ text "Updated At" ]
            ]
        , tbody = Table.tbody [] (List.map pollRow polls)
        }

pollRow : Poll -> Row Msg
pollRow poll =
    Table.tr []
        [ Table.td [] [ text poll.id ]
        , Table.td [] [ text (toString poll.updatedAt) ]
        ]
