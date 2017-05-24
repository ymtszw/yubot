module Poller.Model exposing (Model, initialModel)

import Bootstrap.Navbar as Navbar
import Routing
import Resource exposing (Resource, initialResource)
import Polls exposing (Poll, dummyPoll)
import Actions exposing (Action, dummyAction)
import Authentications exposing (Authentication, dummyAuthentication)


type alias Model =
    { pollRs : Resource Poll
    , actionRs : Resource Action
    , authRs : Resource Authentication
    , navbarState : Navbar.State
    , route : Routing.Route
    }


initialModel : Routing.Route -> Navbar.State -> Model
initialModel route navbarState =
    { pollRs = initialResource dummyPoll
    , actionRs = initialResource dummyAction
    , authRs = initialResource dummyAuthentication
    , navbarState = navbarState
    , route = route
    }
