module Poller.View exposing (..)

import Html exposing (Html, div, h1, p, text)
import Bootstrap.Grid as Grid exposing (Column)
import Bootstrap.Grid.Col exposing (..)
import Bootstrap.Tab as Tab
import Polls.View
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(PollsMsg, TabMsg))
import Poller.Styles exposing (..)

view : Model -> Html Msg
view model =
    Grid.containerFluid [ background ]
        [ gap
        , Grid.simpleRow [ mainContent model ]
        ]

gap : Html Msg
gap =
    Grid.simpleRow
        [ Grid.col [ md12, attrs [ introGap ] ]
            [ h1 [ display1 ] [ text "Poller the Bear" ]
            , p [] [ text "I am the Bear who watches over the globe." ]
            ]
        ]

mainContent : Model -> Column Msg
mainContent model =
    Grid.col
        [ offsetLg3, lg8, offsetMd1, md10, offsetSm0, sm12
        , attrs [ greyBack, rounded, py3 ]
        ]
        [ mainTabs model ]

mainTabs : Model -> Html Msg
mainTabs model =
    Tab.config TabMsg
        |> Tab.withAnimation
        |> Tab.justified
        |> Tab.attrs [ rounded, whiteBack ]
        |> Tab.items
            [ Tab.item
                { link = Tab.link [] [ text "Polls" ]
                , pane = Tab.pane [ whiteBack ] [ pollList model ]
                }
            , Tab.item
                { link = Tab.link [] [ text "Dummy" ]
                , pane = Tab.pane [ whiteBack ] [ text "dummy pane" ]
                }
            ]
        |> Tab.view model.tabState

pollList : Model -> Html Msg
pollList model =
    div []
        [ Grid.simpleRow
            [ Grid.col [ md12 ]
                [ Html.map PollsMsg (Polls.View.listView model.polls)
                ]
            ]
        , Html.map PollsMsg (Polls.View.deleteModalView model.pollDeleteModal)
        ]
