module Poller.View exposing (..)

import Html exposing (Html, div, h1, p, text)
import Html.Utils exposing (atext)
import Bootstrap.Grid as Grid exposing (Column)
import Bootstrap.Grid.Col exposing (..)
import Bootstrap.Tab as Tab
import Bootstrap.Card as Card
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
        [ offsetLg2, lg9, md12
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
                , pane = Tab.pane [ whiteBack, p3 ] [ pollList model ]
                }
            , Tab.item
                { link = Tab.link [] [ text "Dummy" ]
                , pane = Tab.pane [ whiteBack, p3 ] [ dummyBlock ]
                }
            ]
        |> Tab.view model.tabState

pollList : Model -> Html Msg
pollList model =
    div []
        [ Grid.simpleRow
            [ Grid.col [ md12 ]
                [ Html.map PollsMsg (Polls.View.listView model.polls model.pollsSort)
                ]
            ]
        , Html.map PollsMsg (Polls.View.deleteModalView model.pollDeleteModal)
        , Html.map PollsMsg (Polls.View.editModalView model.pollEditModal)
        ]

dummyBlock : Html Msg
dummyBlock =
    Card.config []
        |> Card.block []
            [ Card.text []
                [ p [] (atext "Dummy texts with URLs.")
                , p [] (atext "Elm(http://elm-lang.org/)はいいぞ。")
                , p [] (atext "複雑なURLがhttps://www.wikiwand.com/ja/%E9%96%A2%E6%95%B0%E5%9E%8B%E8%A8%80%E8%AA%9E日本語文の中にあっても大丈夫。")
                ]
            ]
        |> Card.view
