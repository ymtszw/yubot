module Poller.Messages exposing (Msg(..), fromRepo)

import Navigation
import Bootstrap.Navbar
import Utils
import Repo.Messages
import Polls
import Actions
import Authentications


type Msg
    = PollsMsg (Repo.Messages.Msg Polls.Poll)
    | ActionsMsg (Repo.Messages.Msg Actions.Action)
    | AuthMsg (Repo.Messages.Msg Authentications.Authentication)
    | NavbarMsg Bootstrap.Navbar.State
    | ChangeLocation Utils.Url
    | OnLocationChange Navigation.Location
    | OnServerPush String


{-| Map Repo messages into root (Poller) messages, with special treatment for `ChangeLocation` message.
-}
fromRepo : (Repo.Messages.Msg x -> Msg) -> Repo.Messages.Msg x -> Msg
fromRepo fallbackMapper subMsg =
    case subMsg of
        Repo.Messages.ChangeLocation url ->
            ChangeLocation url

        otherMsg ->
            fallbackMapper otherMsg
