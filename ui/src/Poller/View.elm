module Poller.View exposing (view)

import Dict
import Set
import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Lazy as Z
import Bootstrap.Navbar as Navbar
import Utils
import Stack
import Routing exposing (Route(..))
import Repo
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
import Assets
import ViewParts exposing (none)


view : Model -> Html Msg
view ({ isDev, navbarState, route } as model) =
    Html.div []
        [ Z.lazy3 navbar isDev navbarState route
        , errorToasts model
        , Html.div [ class "container-fluid mt-3" ]
            [ Html.div [ class "row" ]
                [ Html.div [ class "col-md-12" ] [ mainContent model ] ]
            ]
        ]


errorToasts : Model -> Html Msg
errorToasts { pollRepo, actionRepo, authRepo, taskStack } =
    Html.div [ class "container-fluid mt-2", Styles.toastBlock ]
        [ Html.div [ Attr.id "error-toasts", class "row" ]
            [ Html.div [ class "col-md-10 offset-md-1 col-lg-8 offset-lg-2" ]
                [ pollRepo.errors |> Z.lazy errorToast |> htmlMap PollsMsg
                , actionRepo.errors |> Z.lazy errorToast |> Html.map (Poller.Messages.fromActions ActionsMsg << Actions.RepoMsg)
                , authRepo.errors |> Z.lazy errorToast |> htmlMap AuthMsg
                ]
            , Z.lazy spinner taskStack
            ]
        ]


spinner : Stack.Stack () -> Html msg
spinner taskStack =
    Html.div [ class "col-md-1 col-lg-2" ]
        [ Html.i
            [ class "float-right fa fa-spinner fa-pulse fa-3x fa-fw"
            , Styles.display (Stack.nonEmpty taskStack)
            ]
            []
        ]


navbar : Bool -> Navbar.State -> Route -> Html Msg
navbar isDev navbarState route =
    let
        logo =
            Html.h3 [ class "mb-0" ]
                [ Html.img [ class "align-bottom mx-1", Attr.src (Assets.url isDev "img/poller/favicon32.png") ] []
                , text "Poller"
                , Html.small [ Styles.xSmall ] [ text "the Bear" ]
                ]
    in
        Navbar.config NavbarMsg
            |> Navbar.withAnimation
            |> Navbar.collapseSmall
            |> Navbar.brand (navigate "/") [ logo ]
            |> Navbar.items (List.map (navbarItem route) [ "Polls", "Actions", "Credentials" ])
            |> Navbar.view navbarState


navbarItem : Route -> String -> Navbar.Item Msg
navbarItem route itemLabel =
    let
        attrs =
            Utils.ite (isActiveItem route itemLabel) [ class "pb-0 active", Styles.activeNavbarItem ] [ class "pb-0" ]
    in
        Navbar.itemLink (attrs ++ navigate ("/" ++ (String.toLower itemLabel))) [ text itemLabel ]


isActiveItem : Route -> String -> Bool
isActiveItem route =
    case route of
        PollsRoute ->
            (==) "Polls"

        PollRoute _ ->
            (==) "Polls"

        ActionsRoute ->
            (==) "Actions"

        NewActionRoute ->
            (==) "Actions"

        ActionRoute _ ->
            (==) "Actions"

        AuthsRoute ->
            (==) "Credentials"

        _ ->
            always False


mainContent : Model -> Html Msg
mainContent { route, pollRepo, actionRepo, authRepo, taskStack } =
    let
        showImpl msg htmlFun repo id =
            case Dict.get id repo.dict of
                Just entity ->
                    Html.map msg (htmlFun repo entity)

                Nothing ->
                    Utils.ite (Stack.isEmpty taskStack) notFoundPage none
    in
        case route of
            PollsRoute ->
                htmlMap PollsMsg (Z.lazy Polls.View.index pollRepo)

            PollRoute pollId ->
                showImpl (Poller.Messages.fromRepo PollsMsg) (Polls.View.show actionRepo.dict authRepo.dict) pollRepo pollId

            ActionsRoute ->
                Html.map (Poller.Messages.fromActions ActionsMsg) (Actions.View.index actionRepo)

            NewActionRoute ->
                Html.map (Poller.Messages.fromActions ActionsMsg) (Actions.View.new authRepo.dict actionRepo)

            ActionRoute actionId ->
                showImpl (Poller.Messages.fromActions ActionsMsg)
                    (Actions.View.show (Polls.usedActionIds pollRepo.dict) authRepo.dict)
                    actionRepo
                    actionId

            AuthsRoute ->
                htmlMap AuthMsg (Authentications.View.index (usedAuthIds pollRepo.dict actionRepo.dict) authRepo)

            _ ->
                notFoundPage


usedAuthIds : Repo.EntityDict Polls.Poll -> Repo.EntityDict Actions.Action -> Set.Set Repo.EntityId
usedAuthIds pollDict actionDict =
    Set.union (Actions.usedAuthIds actionDict) (Polls.usedAuthIds pollDict)


htmlMap : (Repo.Messages.Msg x -> Msg) -> Html (Repo.Messages.Msg x) -> Html Msg
htmlMap msgMapper =
    Html.map (Poller.Messages.fromRepo msgMapper)


navigate : Utils.Url -> List (Html.Attribute Msg)
navigate =
    ViewParts.navigate ChangeLocation


notFoundPage : Html msg
notFoundPage =
    Html.div [ class "text-center" ] [ Html.h1 [ class "display-1" ] [ text "Not Found." ] ]
