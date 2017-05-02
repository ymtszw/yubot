module Poller.Model exposing (Model, initialModel)

import Bootstrap.Tab as Tab
import Bootstrap.Navbar as Navbar
import Resource exposing (Resource, initialResource)
import Polls exposing (Poll, dummyPoll)
import Actions exposing (Action, dummyAction)
import Authentications exposing (Authentication, dummyAuthentication)


type alias Model =
    { pollRs : Resource Poll
    , actionRs : Resource Action
    , authRs : Resource Authentication
    , tabState : Tab.State
    , navbarState : Navbar.State
    }


initialModel : Navbar.State -> Model
initialModel navbarState =
    { pollRs = initialResource dummyPoll
    , actionRs = initialResource dummyAction
    , authRs = initialResource dummyAuthentication
    , tabState = Tab.initialState
    , navbarState = navbarState
    }
