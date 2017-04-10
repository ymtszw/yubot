module Poller.View exposing (..)

import Html exposing (Html, h1, text)
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col exposing (md12)
import Polls.View
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(PollsMsg))

view : Model -> Html Msg
view model =
    Grid.container []
        [ Grid.simpleRow
            [ Grid.col [ md12 ]
                [ h1 [] [ text "Poller the Bear" ]
                ]
            ]
        , Grid.simpleRow
            [ Grid.col [ md12 ]
                [ Html.map PollsMsg (Polls.View.listView model.polls)
                ]
            ]
        , Html.map PollsMsg (Polls.View.deleteModalView model.pollDeleteModal)
        ]
