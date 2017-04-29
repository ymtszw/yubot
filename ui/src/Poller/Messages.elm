module Poller.Messages exposing (Msg(..))

import Bootstrap.Tab
import Bootstrap.Navbar
import Resource.Messages
import Polls
import Actions


type Msg
    = PollsMsg (Resource.Messages.Msg Polls.Poll)
    | ActionsMsg (Resource.Messages.Msg Actions.Action)
    | TabMsg Bootstrap.Tab.State
    | NavbarMsg Bootstrap.Navbar.State
