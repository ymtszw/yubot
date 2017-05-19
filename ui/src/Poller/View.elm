module Poller.View exposing (view)

import Html exposing (Html, div, h1, p, text, strong)
import Html.Attributes exposing (class, src)
import Html.Utils exposing (atext)
import Bootstrap.Grid as Grid exposing (Column)
import Bootstrap.Grid.Col exposing (..)
import Bootstrap.Tab as Tab
import Bootstrap.Card as Card
import Bootstrap.Navbar as Navbar
import Polls
import Polls.View
import Polls.ModalView
import Actions.View
import Actions.ModalView
import Authentications.View
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))
import Poller.Styles as Styles


view : Model -> Html Msg
view model =
    div []
        [ navbar model
        , Grid.containerFluid [ class "mt-4" ] [ Grid.simpleRow [ mainContent model ] ]
        ]


navbar : Model -> Html Msg
navbar model =
    Navbar.config NavbarMsg
        |> Navbar.withAnimation
        |> Navbar.collapseSmall
        |> Navbar.brand [] [ logo ]
        |> Navbar.customItems []
        |> Navbar.view model.navbarState


logo : Html Msg
logo =
    Html.h3 [ class "mb-0" ]
        [ Html.img
            [ class "align-bottom"
            , class "mx-1"
            , src "/static/img/poller/favicon32.png"
            ]
            []
        , text "Poller"
        , Html.small [ Styles.xSmall ] [ text "the Bear" ]
        ]


mainContent : Model -> Column Msg
mainContent model =
    Grid.col [] [ mainTabs model ]


mainTabs : Model -> Html Msg
mainTabs model =
    Tab.config TabMsg
        |> Tab.withAnimation
        |> Tab.justified
        |> Tab.attrs []
        |> Tab.items
            [ Tab.item
                { link = Tab.link [] [ text "Polls" ]
                , pane = Tab.pane [ Styles.whiteBack, class "p-3" ] [ pollList model ]
                }
            , Tab.item
                { link = Tab.link [] [ text "Actions" ]
                , pane = Tab.pane [ Styles.whiteBack, class "p-3" ] [ actionList model ]
                }
            , Tab.item
                { link = Tab.link [] [ text "Credentials" ]
                , pane = Tab.pane [ Styles.whiteBack, class "p-3" ] [ authList model ]
                }
            , Tab.item
                { link = Tab.link [] [ text "Dummy" ]
                , pane = Tab.pane [ Styles.whiteBack, class "p-3" ] [ dummyBlock ]
                }
            ]
        |> Tab.view model.tabState


pollList : Model -> Html Msg
pollList model =
    div []
        [ Grid.simpleRow
            [ Grid.col [ md12 ]
                [ Html.map PollsMsg (Polls.View.listView model.pollRs)
                ]
            ]
        , Html.map PollsMsg (Polls.ModalView.deleteModalView model.pollRs)
        , Html.map PollsMsg (Polls.ModalView.editModalView model.actionRs.list model.authRs.list model.pollRs)
        ]


actionList : Model -> Html Msg
actionList model =
    div []
        [ Grid.simpleRow
            [ Grid.col [ md12 ]
                [ Html.map ActionsMsg (Actions.View.listView (Polls.usedActionIds model.pollRs.list) model.actionRs)
                ]
            ]
        , Html.map ActionsMsg (Actions.ModalView.deleteModalView model.actionRs)
        , Html.map ActionsMsg (Actions.ModalView.editModalView model.authRs.list model.actionRs)
        ]


authList : Model -> Html Msg
authList model =
    div []
        [ Grid.simpleRow
            [ Grid.col [ md12 ]
                [ Html.map AuthMsg (Authentications.View.listView model.authRs)
                ]
            ]
        ]


dummyBlock : Html Msg
dummyBlock =
    Card.config []
        |> Card.block []
            [ Card.text []
                [ p [] (atext "Dummy texts with URLs.")
                , p [] (atext "Elm(http://elm-lang.org/)はいいぞ。Elixir(http://elixir-lang.org)もいいぞ。")
                , p [] (atext "atextヘルパーでは複雑なURLがhttps://www.wikiwand.com/ja/%E9%96%A2%E6%95%B0%E5%9E%8B%E8%A8%80%E8%AA%9E日本語文の中にあっても大丈夫。")
                ]
            ]
        |> Card.view
