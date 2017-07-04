module Poller.Messages exposing (Msg(..))

import Time
import Date
import Navigation
import Bootstrap.Navbar
import Utils
import Repo.Messages
import Polls
import Actions
import Authentications


type Msg
    = PollsMsg Polls.Msg
    | ActionsMsg Actions.Msg
    | AuthMsg (Repo.Messages.Msg Authentications.Authentication)
    | NavbarMsg Bootstrap.Navbar.State
    | UserDropdownMsg Utils.DropdownState
    | PromptLogin
    | OnLoginButtonClick
    | Logout
    | OnLogout
    | ChangeLocation Utils.Url
    | OnLocationChange Navigation.Location
    | OnServerPush String
    | OnClientTimeout Time.Time
    | OnReceiveTitle String
    | DatedLog String String Date.Date
    | NoOp
