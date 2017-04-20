module Poller.Model exposing (..)

import Bootstrap.Modal exposing (hiddenState)
import Bootstrap.Tab as Tab
import Polls exposing (Poll, dummyPoll)

type alias Model =
    { polls : List Poll
    , pollDeleteModal : Polls.DeleteModal
    , pollEditModal : Polls.EditModal
    , tabState : Tab.State
    }

initialModel : Model
initialModel =
    { polls = []
    , pollDeleteModal = Polls.DeleteModal hiddenState dummyPoll
    , pollEditModal = Polls.EditModal hiddenState dummyPoll
    , tabState = Tab.initialState
    }
