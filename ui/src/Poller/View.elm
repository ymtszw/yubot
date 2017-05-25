module Poller.View exposing (view)

import Html exposing (Html, text)
import Html.Attributes exposing (class, src, href)
import Html.Utils exposing (navigateOnClick)
import Bootstrap.Navbar as Navbar
import Routing exposing (Route(..))
import Polls
import Polls.View
import Actions.View
import Authentications.View
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))
import Poller.Styles as Styles


view : Model -> Html Msg
view model =
    Html.div []
        [ navbar model
        , Html.div [ class "container-fluid mt-4" ]
            [ Html.div [ class "row" ]
                [ mainContent model ]
            ]
        ]


navbar : Model -> Html Msg
navbar model =
    let
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
    in
        Navbar.config NavbarMsg
            |> Navbar.withAnimation
            |> Navbar.collapseSmall
            |> Navbar.brand (navigateOnClick "") [ logo ]
            |> Navbar.customItems []
            |> Navbar.view model.navbarState


mainContent : Model -> Html Msg
mainContent model =
    let
        htmlMap msgMapper =
            Html.map (Poller.Messages.fromRepo msgMapper)

        content =
            case model.route of
                PollsRoute ->
                    Polls.View.cardsView model.pollRepo
                        |> htmlMap PollsMsg
                        |> tabbedContents 0

                ActionsRoute ->
                    Actions.View.listView (Polls.usedActionIds model.pollRepo.dict) model.actionRepo
                        |> htmlMap ActionsMsg
                        |> tabbedContents 1

                AuthsRoute ->
                    Authentications.View.listView model.authRepo
                        |> htmlMap AuthMsg
                        |> tabbedContents 2

                _ ->
                    -- Not Found
                    Html.div [ class "text-center" ] [ Html.h1 [ class "display-1" ] [ text "Not Found." ] ]
    in
        Html.div [ class "col-md-12" ] [ content ]


tabbedContents : Int -> Html Msg -> Html Msg
tabbedContents activeIndex html =
    let
        tabClass index =
            if index == activeIndex then
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
    in
        Html.div []
            [ Html.ul [ class "nav nav-tabs nav-justified" ] tabs
            , Html.div [ class "tab-content" ]
                [ Html.div [ class "tab-pane p-3", Styles.shown ] [ html ] ]
            ]
