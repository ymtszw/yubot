module Poller.Model exposing (..)

import Bootstrap.Modal exposing (hiddenState)
import Polls exposing (Poll, DeleteModal, dummyPoll)

type alias Model =
    { polls : List Poll
    , pollDeleteModal : DeleteModal
    }

initialModel : Model
initialModel =
    { polls = []
    , pollDeleteModal = DeleteModal hiddenState dummyPoll
    }
