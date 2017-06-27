module Poller.Model exposing (Model, initialModel)

import Bootstrap.Navbar as Navbar
import Stack exposing (Stack)
import Routing
import User exposing (User)
import Repo exposing (Repo)
import Polls exposing (Poll)
import Actions exposing (Action, Aux)
import Authentications exposing (Authentication)


type alias Model =
    { pollRepo : Repo {} Poll
    , actionRepo : Repo Aux Action
    , authRepo : Repo {} Authentication
    , navbarState : Navbar.State
    , userDropdownVisible : Bool
    , route : Routing.Route
    , routeBeforeLogin : Maybe Routing.Route
    , isDev : Bool
    , user : Maybe User
    , taskStack : Stack ()
    , title : String
    }


initialModel : Bool -> Maybe User -> Stack () -> Routing.Route -> Navbar.State -> Model
initialModel isDev maybeUser initTaskStack route navbarState =
    { pollRepo = Repo.populate [] Polls.dummyPoll
    , actionRepo = Actions.populate []
    , authRepo = Repo.populate [] Authentications.dummyAuthentication
    , navbarState = navbarState
    , userDropdownVisible = False
    , route = route
    , routeBeforeLogin = Nothing
    , isDev = isDev
    , user = maybeUser
    , taskStack = initTaskStack
    , title = ""
    }
