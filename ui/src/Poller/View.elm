module Poller.View exposing (view)

import Dict
import Set
import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Lazy as Z
import Html.Events
import Http
import Maybe.Extra as ME
import Bootstrap.Navbar as Navbar
import Utils exposing (DropdownState(..))
import Stack
import Routing exposing (Route(..))
import User
import Repo
import Repo.ViewParts exposing (errorToast)
import OAuth
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
view model =
    case model.route of
        LoginRoute ->
            loginView model

        _ ->
            mainView model


loginView : Model -> Html Msg
loginView ({ assets, taskStack } as model) =
    Html.div [ class "container" ]
        [ Html.div [ class "row" ]
            [ Html.div [ class "col-sm-12 col-md-10 col-lg-6 offset-md-1 offset-lg-3" ]
                [ ViewParts.cardBlock (spinner taskStack :: brand assets) "" Nothing (loginForm model) ]
            ]
        ]


loginForm : Model -> Html Msg
loginForm { routeBeforeLogin } =
    Html.div []
        [ oauthLoginButton routeBeforeLogin [ class "btn-secondary mt-3" ] "fa-google" Styles.googleBlue OAuth.Google
        , oauthLoginButton routeBeforeLogin [ class "btn-secondary mt-3" ] "fa-github" Styles.githubBlack OAuth.GitHub
        ]


oauthLoginButton : Maybe Route -> List (Html.Attribute Msg) -> String -> Html.Attribute Msg -> OAuth.Provider -> Html Msg
oauthLoginButton maybeRoute attrs iconFa iconStyle provider =
    Html.a
        ([ class "btn btn-block"
         , Attr.href (oauthLoginLink maybeRoute provider)
         , Html.Events.onClick OnLoginButtonClick -- Purely cosmetic; this won't prevent default link behavior
         ]
            ++ attrs
        )
        [ ViewParts.fa [ iconStyle ] 2 iconFa
        , text ("Login with " ++ toString provider)
        ]


oauthLoginLink : Maybe Route -> OAuth.Provider -> Utils.Url
oauthLoginLink maybeRoute provider =
    let
        returnPath =
            maybeRoute |> ME.unwrap "/poller" Routing.routeToPath |> Http.encodeUri
    in
        "/oauth/" ++ Utils.toLowerString provider ++ "/login?return_path=" ++ returnPath


brand : Assets.Assets -> List (Html msg)
brand assets =
    [ Html.img [ class "align-bottom mx-1", Attr.src (Assets.url assets "img/poller/favicon32.png") ] []
    , text "Poller"
    , Html.small [ Styles.xSmall ] [ text "the Bear" ]
    ]


mainView : Model -> Html Msg
mainView model =
    Html.div []
        [ navbar model
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
                [ pollRepo.errors |> Z.lazy errorToast |> Html.map (PollsMsg << Polls.RepoMsg)
                , actionRepo.errors |> Z.lazy errorToast |> Html.map (ActionsMsg << Actions.RepoMsg)
                , authRepo.errors |> Z.lazy errorToast |> Html.map AuthMsg
                ]
            , Html.div [ class "col-md-1 col-lg-2" ] [ Z.lazy spinner taskStack ]
            ]
        ]


spinner : Stack.Stack () -> Html msg
spinner taskStack =
    ViewParts.fa [ class "float-right fa-pulse", Styles.display (Stack.nonEmpty taskStack) ] 2 "fa-spinner"


navbar : Model -> Html Msg
navbar { assets, navbarState, route, user, userDropdownState } =
    Navbar.config NavbarMsg
        |> Navbar.withAnimation
        |> Navbar.collapseSmall
        |> Navbar.brand (navigate "/") [ Html.h3 [ class "mb-0" ] (brand assets) ]
        |> Navbar.items (List.map (navbarItem route) [ "Polls", "Actions" ])
        |> Navbar.customItems (userDropdown user userDropdownState)
        |> Navbar.view navbarState


navbarItem : Route -> String -> Navbar.Item Msg
navbarItem route itemLabel =
    let
        itemFun =
            Utils.ite (isActiveItem route itemLabel) Navbar.itemLinkActive Navbar.itemLink
    in
        itemFun (navigate ("/" ++ (String.toLower itemLabel))) [ text itemLabel ]


isActiveItem : Route -> String -> Bool
isActiveItem route =
    case route of
        PollsRoute ->
            (==) "Polls"

        NewPollRoute ->
            (==) "Polls"

        PollRoute _ ->
            (==) "Polls"

        ActionsRoute ->
            (==) "Actions"

        NewActionRoute ->
            (==) "Actions"

        ActionRoute _ ->
            (==) "Actions"

        _ ->
            always False


userDropdown : Maybe User.User -> DropdownState -> List (Navbar.CustomItem Msg)
userDropdown maybeUser userDropdownState =
    let
        ( itemClass, menuClass, nextState ) =
            case userDropdownState of
                Shown ->
                    ( " show", " show", Fading )

                Fading ->
                    ( " show", " in", Hidden )

                Hidden ->
                    ( "", "", Shown )

        dropdown email { displayName } =
            Navbar.textItem [ class ("float-right dropdown" ++ itemClass) ]
                [ Html.a (class "dropdown-toggle" :: ViewParts.onFakeLinkClick True True (UserDropdownMsg nextState)) [ text displayName ]
                , Html.div [ class ("dropdown-menu dropdown-menu-right fade" ++ menuClass), Styles.toast, ViewParts.onClickNoPropagate (NoOp) ]
                    [ Html.h5 [ class "dropdown-header" ] [ text email ]
                    , Html.div [ class "dropdown-divider" ] []
                    , Html.a (class "dropdown-item" :: navigate "/credentials")
                        [ ViewParts.fa [] 1 "fa-key"
                        , text "Credentials"
                        ]
                    , Html.a (class "dropdown-item" :: ViewParts.onFakeLinkClick False True Logout)
                        [ ViewParts.fa [] 1 "fa-sign-out"
                        , text "Logout"
                        ]
                    ]
                ]
    in
        case maybeUser of
            Just { email, data } ->
                [ dropdown email data ]

            Nothing ->
                []


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
                Html.map PollsMsg (Z.lazy Polls.View.index pollRepo)

            NewPollRoute ->
                Html.map PollsMsg (Polls.View.new actionRepo.dict authRepo.dict pollRepo)

            PollRoute pollId ->
                showImpl PollsMsg (Polls.View.show actionRepo.dict authRepo.dict) pollRepo pollId

            ActionsRoute ->
                Html.map ActionsMsg (Actions.View.index actionRepo)

            NewActionRoute ->
                Html.map ActionsMsg (Actions.View.new authRepo.dict actionRepo)

            ActionRoute actionId ->
                showImpl ActionsMsg (Actions.View.show (Polls.usedActionIds pollRepo.dict) authRepo.dict) actionRepo actionId

            AuthsRoute ->
                Html.map AuthMsg (Authentications.View.index (usedAuthIds pollRepo.dict actionRepo.dict) authRepo)

            _ ->
                notFoundPage


usedAuthIds : Repo.EntityDict Polls.Poll -> Repo.EntityDict Actions.Action -> Set.Set Repo.EntityId
usedAuthIds pollDict actionDict =
    Set.union (Actions.usedAuthIds actionDict) (Polls.usedAuthIds pollDict)


navigate : Utils.Url -> List (Html.Attribute Msg)
navigate =
    ViewParts.navigate ChangeLocation


notFoundPage : Html msg
notFoundPage =
    Html.div [ class "text-center" ] [ Html.h1 [ class "display-1" ] [ text "Not Found." ] ]
