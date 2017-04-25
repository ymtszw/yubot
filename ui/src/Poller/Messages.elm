module Poller.Messages exposing (..)

import Bootstrap.Tab as Tab
import Resource.Messages
import Polls
import Actions


type Msg
    = PollsMsg (Resource.Messages.Msg Polls.Poll)
    | ActionsMsg (Resource.Messages.Msg Actions.Action)
    | TabMsg Tab.State
