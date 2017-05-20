module Poller.View exposing (view)

import Html exposing (Html, h1, p, text, strong)
import Html.Attributes exposing (class, src, href)
import Html.Utils exposing (atext, navigateOnClick)
import Bootstrap.Grid as Grid exposing (Column)
import Bootstrap.Grid.Col exposing (..)
import Bootstrap.Navbar as Navbar
import Routing
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
    Html.div []
        [ navbar model
        , Grid.containerFluid [ class "mt-4" ] [ Grid.simpleRow [ mainContent model ] ]
        ]


navbar : Model -> Html Msg
navbar model =
    Navbar.config NavbarMsg
        |> Navbar.withAnimation
        |> Navbar.collapseSmall
        |> Navbar.brand (navigateOnClick "/poller") [ logo ]
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
    let
        tabClass index =
            if Routing.isActiveTab model.route index then
                class "nav-link active"
            else
                class "nav-link"

        tab index ( url, title ) =
            Html.li [ class "nav-item" ]
                [ Html.a ((tabClass index) :: navigateOnClick url) [ text title ] ]

        tabs =
            [ ( "/poller/polls", "Polls" )
            , ( "/poller/actions", "Actions" )
            , ( "/poller/credentials", "Credentials" )
            ]
                |> List.indexedMap tab

        contentClass index =
            if Routing.isActiveTab model.route index then
                Styles.shown
            else
                Styles.hidden

        content index html =
            Html.div [ class "tab-pane p-3", contentClass index ] [ html ]

        contents =
            [ pollList model
            , actionList model
            , authList model
            ]
                |> List.indexedMap content
    in
        Html.div []
            [ Html.ul [ class "nav nav-tabs nav-justified" ] tabs
            , Html.div [ class "tab-content" ] contents
            ]


pollList : Model -> Html Msg
pollList model =
    Html.div []
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
    Html.div []
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
    Html.div []
        [ Grid.simpleRow
            [ Grid.col [ md12 ]
                [ Html.map AuthMsg (Authentications.View.listView model.authRs)
                ]
            ]
        ]
