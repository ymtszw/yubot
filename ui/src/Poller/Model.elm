module Poller.Model exposing (..)

import Bootstrap.Tab as Tab
import Resource exposing (Resource, initialResource)
import Polls exposing (Poll, dummyPoll)
import Actions exposing (Action, dummyAction)


type alias Model =
    { pollRs : Resource Poll
    , actionRs : Resource Action
    , tabState : Tab.State
    }


initialModel : Model
initialModel =
    { pollRs = initialResource dummyPoll
    , actionRs = initialResource dummyAction
    , tabState = Tab.initialState
    }
