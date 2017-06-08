module Poller.View exposing (view)

import Set
import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Utils exposing (navigate)
import Bootstrap.Navbar as Navbar
import Routing exposing (Route(..))
import Repo.Messages
import Repo.ViewParts exposing (errorToast)
import Polls
import Polls.View
import Actions
import Actions.View
import Authentications.View
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))
import Styles
import Poller.Assets as Assets


view : Model -> Html Msg
view model =
    Html.div []
        [ navbar model
        , errorToasts model
        , Html.div [ class "container-fluid mt-4" ]
            [ Html.div [ class "row" ]
                [ mainContent model ]
            ]
        ]


errorToasts : Model -> Html Msg
errorToasts model =
    Html.div [ class "container-fluid mt-2", Styles.toastBlock ]
        [ Html.div [ Attr.id "error-toasts", class "row" ]
            [ Html.div [ class "col-md-10 offset-md-1 col-lg-8 offset-lg-2" ]
                [ model.pollRepo |> errorToast |> htmlMap PollsMsg
                , model.actionRepo |> errorToast |> htmlMap ActionsMsg
                , model.authRepo |> errorToast |> htmlMap AuthMsg
                ]
            ]
        ]


navbar : Model -> Html Msg
navbar model =
    let
        logo =
            Html.h3 [ class "mb-0" ]
                [ Html.img [ class "align-bottom mx-1", Attr.src (Assets.url model.isDev model.assetInventory "img/poller/favicon32.png") ] []
                , text "Poller"
                , Html.small [ Styles.xSmall ] [ text "the Bear" ]
                ]
    in
        Navbar.config NavbarMsg
            |> Navbar.withAnimation
            |> Navbar.collapseSmall
            |> Navbar.brand (navigate ChangeLocation "/") [ logo ]
            |> Navbar.items
                [ Navbar.itemLink ((class "pb-0") :: navigate ChangeLocation "/polls") [ text "Polls" ]
                , Navbar.itemLink ((class "pb-0") :: navigate ChangeLocation "/actions") [ text "Actions" ]
                , Navbar.itemLink ((class "pb-0") :: navigate ChangeLocation "/credentials") [ text "Credentials" ]
                ]
            |> Navbar.view model.navbarState


mainContent : Model -> Html Msg
mainContent model =
    let
        content =
            case model.route of
                PollsRoute ->
                    Polls.View.cardsView model.pollRepo
                        |> htmlMap PollsMsg

                ActionsRoute ->
                    Actions.View.listView (Polls.usedActionIds model.pollRepo.dict) model.actionRepo
                        |> htmlMap ActionsMsg

                AuthsRoute ->
                    let
                        usedAuthIds =
                            Polls.usedAuthIds model.pollRepo.dict
                                |> Set.union (Actions.usedAuthIds model.actionRepo.dict)
                    in
                        Authentications.View.listView model.isDev model.assetInventory usedAuthIds model.authRepo
                            |> htmlMap AuthMsg

                _ ->
                    -- Not Found
                    Html.div [ class "text-center" ] [ Html.h1 [ class "display-1" ] [ text "Not Found." ] ]
    in
        Html.div [ class "col-md-12" ] [ content ]


htmlMap : (Repo.Messages.Msg x -> Msg) -> Html (Repo.Messages.Msg x) -> Html Msg
htmlMap msgMapper =
    Html.map (Poller.Messages.fromRepo msgMapper)
