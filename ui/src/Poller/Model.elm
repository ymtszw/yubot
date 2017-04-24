module Poller.Model exposing (..)

import Bootstrap.Modal exposing (hiddenState)
import Bootstrap.Tab as Tab
import Utils exposing (Sorter)
import Polls exposing (Poll, dummyPoll)
import Actions exposing (Action, dummyAction)


type alias Model =
    { polls : List Poll
    , pollsSort : Maybe (Sorter Poll)
    , pollDeleteModal : Polls.DeleteModal
    , pollEditModal : Polls.EditModal
    , actions : List Action
    , actionsSort : Maybe (Sorter Action)
    , actionDeleteModal : Actions.DeleteModal
    , actionEditModal : Actions.EditModal
    , tabState : Tab.State
    }


initialModel : Model
initialModel =
    { polls = []
    , pollsSort = Nothing
    , pollDeleteModal = Polls.DeleteModal hiddenState dummyPoll
    , pollEditModal = Polls.EditModal hiddenState dummyPoll
    , actions = []
    , actionsSort = Nothing
    , actionDeleteModal = Actions.DeleteModal hiddenState dummyAction
    , actionEditModal = Actions.EditModal hiddenState dummyAction
    , tabState = Tab.initialState
    }
