module Poller.Messages exposing (..)

import Bootstrap.Tab as Tab
import Polls.Messages


type Msg
    = PollsMsg Polls.Messages.Msg
    | TabMsg Tab.State
