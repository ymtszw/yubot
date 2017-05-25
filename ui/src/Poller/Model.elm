module Poller.Model exposing (Model, initialModel)

import Bootstrap.Navbar as Navbar
import Routing
import Repo
import Polls exposing (Poll)
import Actions exposing (Action)
import Authentications exposing (Authentication)


type alias Model =
    { pollRepo : Repo.Repo Poll
    , actionRepo : Repo.Repo Action
    , authRepo : Repo.Repo Authentication
    , navbarState : Navbar.State
    , route : Routing.Route
    }


initialModel : Routing.Route -> Navbar.State -> Model
initialModel route navbarState =
    { pollRepo = Repo.initialize Polls.dummyPoll
    , actionRepo = Repo.initialize Actions.dummyAction
    , authRepo = Repo.initialize Authentications.dummyAuthentication
    , navbarState = navbarState
    , route = route
    }
