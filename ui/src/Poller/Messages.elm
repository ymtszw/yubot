module Poller.Messages exposing (Msg(..))

import Navigation
import Bootstrap.Tab
import Bootstrap.Navbar
import Utils
import Resource.Messages
import Polls
import Actions
import Authentications


type Msg
    = PollsMsg (Resource.Messages.Msg Polls.Poll)
    | ActionsMsg (Resource.Messages.Msg Actions.Action)
    | AuthMsg (Resource.Messages.Msg Authentications.Authentication)
    | NavbarMsg Bootstrap.Navbar.State
    | ChangeLocation Utils.Url
    | OnLocationChange Navigation.Location
