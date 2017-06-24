module Poller.Model exposing (Model, initialModel)

import Bootstrap.Navbar as Navbar
import Stack exposing (Stack)
import Routing
import Repo exposing (Repo)
import Polls exposing (Poll)
import Actions exposing (Action, Aux)
import Authentications exposing (Authentication)


type alias Model =
    { pollRepo : Repo {} Poll
    , actionRepo : Repo Aux Action
    , authRepo : Repo {} Authentication
    , navbarState : Navbar.State
    , route : Routing.Route
    , isDev : Bool
    , taskStack : Stack ()
    }


initialModel : Bool -> Stack () -> Routing.Route -> Navbar.State -> Model
initialModel isDev initTaskStack route navbarState =
    { pollRepo = Repo.populate [] Polls.dummyPoll
    , actionRepo = Actions.populate []
    , authRepo = Repo.populate [] Authentications.dummyAuthentication
    , navbarState = navbarState
    , route = route
    , isDev = isDev
    , taskStack = initTaskStack
    }
