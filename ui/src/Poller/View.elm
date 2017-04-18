module Poller.View exposing (..)

import Html exposing (Html, div, h1, p, text)
import Bootstrap.Grid as Grid exposing (Column)
import Bootstrap.Grid.Col exposing (..)
import Polls.View
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(PollsMsg))
import Poller.Styles exposing (..)

view : Model -> Html Msg
view model =
    Grid.containerFluid [ background ]
        [ gap
        , Grid.simpleRow [ pollListView model ]
        ]

gap : Html Msg
gap =
    Grid.simpleRow
        [ Grid.col [ md12, attrs [ introGap ] ]
            [ h1 [ display1 ] [ text "Poller the Bear" ]
            , p [] [ text "I am the Bear who watches over the globe." ]
            ]
        ]

pollListView : Model -> Column Msg
pollListView model =
    Grid.col
        [ offsetLg3, lg8, offsetMd1, md10, offsetSm0, sm12, attrs [ greyBack, rounded ] ]
        [ Grid.simpleRow
            [ Grid.col [ md12 ]
                [ h1 [] [ text "Polls" ]
                ]
            ]
        , Grid.simpleRow
            [ Grid.col [ md12 ]
                [ Html.map PollsMsg (Polls.View.listView model.polls)
                ]
            ]
        , Html.map PollsMsg (Polls.View.deleteModalView model.pollDeleteModal)
        ]
