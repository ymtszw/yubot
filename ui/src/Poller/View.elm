module Poller.View exposing (view)

import Html exposing (Html, text)
import Html.Attributes exposing (class, src, href)
import Html.Utils exposing (navigateOnClick)
import Bootstrap.Navbar as Navbar
import Routing
import Polls
import Polls.View
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
        , Html.div [ class "container-fluid mt-4" ] [ Html.div [ class "row" ] [ mainContent model ] ]
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


mainContent : Model -> Html Msg
mainContent model =
    Html.div [ class "col-md-12" ] [ mainTabs model ]


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
            [ ( "/polls", "Polls" )
            , ( "/actions", "Actions" )
            , ( "/credentials", "Credentials" )
            ]
                |> List.indexedMap tab

        contentClass index =
            if Routing.isActiveTab model.route index then
                Styles.shown
            else
                Styles.hidden

        content index html =
            Html.div [ class "tab-pane p-3", contentClass index ] [ html ]

        htmlMap msgMapper =
            Html.map (Poller.Messages.fromRepo msgMapper)

        contents =
            [ htmlMap PollsMsg (Polls.View.cardsView model.pollRepo)
            , actionList model
            , authList model
            ]
                |> List.indexedMap content
    in
        Html.div []
            [ Html.ul [ class "nav nav-tabs nav-justified" ] tabs
            , Html.div [ class "tab-content" ] contents
            ]



-- pollList : Model -> Html Msg
-- pollList model =
--     Html.div []
--         [ Html.div [ class "row" ]
--             [ Html.div [ class "col-md-12" ]
--                 [ Html.map PollsMsg (Polls.View.listView model.pollRepo)
--                 ]
--             ]
--         , Html.map PollsMsg (Polls.ModalView.deleteModalView model.pollRepo)
--         ]


actionList : Model -> Html Msg
actionList model =
    Html.div []
        [ Html.div [ class "row" ]
            [ Html.div [ class "col-md-12" ]
                [ Html.map ActionsMsg (Actions.View.listView (Polls.usedActionIds model.pollRepo.dict) model.actionRepo)
                ]
            ]
        , Html.map ActionsMsg (Actions.ModalView.deleteModalView model.actionRepo)
        ]


authList : Model -> Html Msg
authList model =
    Html.div []
        [ Html.div [ class "row" ]
            [ Html.div [ class "col-md-12" ]
                [ Html.map AuthMsg (Authentications.View.listView model.authRepo)
                ]
            ]
        ]
