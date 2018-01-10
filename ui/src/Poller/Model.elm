module Poller.Model exposing (Model, initialModel)

import Bootstrap.Navbar as Navbar
import Stack exposing (Stack)
import Utils
import Routing
import Assets
import User exposing (User)
import Repo exposing (Repo)
import Polls exposing (Poll)
import Actions exposing (Action)
import Authentications exposing (Authentication)


type alias Model =
    { pollRepo : Repo Polls.Aux Poll
    , actionRepo : Repo Actions.Aux Action
    , authRepo : Repo {} Authentication
    , navbarState : Navbar.State
    , userDropdownState : Utils.DropdownState
    , route : Routing.Route
    , routeBeforeLogin : Maybe Routing.Route
    , isDev : Bool
    , user : Maybe User
    , assets : Assets.Assets
    , taskStack : Stack ()
    , title : String
    }


initialModel : Bool -> Maybe User -> Assets.Assets -> Stack () -> Routing.Route -> Navbar.State -> Model
initialModel isDev maybeUser assets initTaskStack route navbarState =
    Model
        (Polls.populate [])
        (Actions.populate [])
        (Repo.populate [] Authentications.dummyAuthentication)
        navbarState
        Utils.Hidden
        route
        Nothing
        isDev
        maybeUser
        assets
        initTaskStack
        ""
