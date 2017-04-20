module Poller.Model exposing (..)

import Bootstrap.Modal exposing (hiddenState)
import Bootstrap.Tab as Tab
import Polls exposing (Poll, DeleteModal, dummyPoll)

type alias Model =
    { polls : List Poll
    , pollDeleteModal : DeleteModal
    , tabState : Tab.State
    }

initialModel : Model
initialModel =
    { polls = []
    , pollDeleteModal = DeleteModal hiddenState dummyPoll
    , tabState = Tab.initialState
    }
