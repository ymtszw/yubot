module Poller.Messages exposing (..)

import Polls.Messages

type Msg
    = PollsMsg Polls.Messages.Msg
