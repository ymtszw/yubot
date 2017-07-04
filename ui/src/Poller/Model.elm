module Poller.Model exposing (Model, initialModel)

import Bootstrap.Navbar as Navbar
import Stack exposing (Stack)
import Utils
import Routing
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
    , taskStack : Stack ()
    , title : String
    }


initialModel : Bool -> Maybe User -> Stack () -> Routing.Route -> Navbar.State -> Model
initialModel isDev maybeUser initTaskStack route navbarState =
    { pollRepo = Polls.populate []
    , actionRepo = Actions.populate []
    , authRepo = Repo.populate [] Authentications.dummyAuthentication
    , navbarState = navbarState
    , userDropdownState = Utils.Hidden
    , route = route
    , routeBeforeLogin = Nothing
    , isDev = isDev
    , user = maybeUser
    , taskStack = initTaskStack
    , title = ""
    }
