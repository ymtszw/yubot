module Poller.View exposing (view)

import Html exposing (Html, text)
import Html.Attributes exposing (class, src, href)
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
                [ Html.img [ class "align-bottom mx-1", src "/static/img/poller/favicon32.png" ] []
                , text "Poller"
                , Html.small [ Styles.xSmall ] [ text "the Bear" ]
                ]
    in
        Navbar.config NavbarMsg
            |> Navbar.withAnimation
            |> Navbar.collapseSmall
            |> Navbar.brand [ href "/poller" ] [ logo ]
            |> Navbar.items
                [ Navbar.itemLink [ href "/poller/polls" ] [ text "Polls" ]
                , Navbar.itemLink [ href "/poller/actions" ] [ text "Actions" ]
                , Navbar.itemLink [ href "/poller/credentials" ] [ text "Credentials" ]
                ]
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

                ActionsRoute ->
                    Actions.View.listView (Polls.usedActionIds model.pollRepo.dict) model.actionRepo
                        |> htmlMap ActionsMsg

                AuthsRoute ->
                    Authentications.View.listView model.authRepo
                        |> htmlMap AuthMsg

                _ ->
                    -- Not Found
                    Html.div [ class "text-center" ] [ Html.h1 [ class "display-1" ] [ text "Not Found." ] ]
    in
        Html.div [ class "col-md-12" ] [ content ]
