module Poller.Model exposing (Model, initialModel)

import Set exposing (Set)
import Bootstrap.Navbar as Navbar
import Routing
import Repo
import Polls exposing (Poll)
import Actions exposing (Action)
import Authentications exposing (Authentication)


type alias Model =
    { pollRepo : Repo.Repo Poll
    , actionRepo : Repo.Repo Action
    , actionFilter : Set Actions.ActionType
    , authRepo : Repo.Repo Authentication
    , navbarState : Navbar.State
    , route : Routing.Route
    , isDev : Bool
    , isBusy : Bool
    }


initialModel : Bool -> Bool -> Routing.Route -> Navbar.State -> Model
initialModel isDev isBusy route navbarState =
    { pollRepo = Repo.initialize Polls.dummyPoll
    , actionRepo = Repo.initialize Actions.dummyAction
    , actionFilter = Set.empty
    , authRepo = Repo.initialize Authentications.dummyAuthentication
    , navbarState = navbarState
    , route = route
    , isDev = isDev
    , isBusy = isBusy
    }
