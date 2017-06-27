module Poller.Messages exposing (Msg(..), fromRepo, fromActions)

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
    = PollsMsg (Repo.Messages.Msg Polls.Poll)
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


{-| Map Repo messages into root (Poller) messages, with special treatment for `ChangeLocation` message.
-}
fromRepo : (Repo.Messages.Msg x -> Msg) -> Repo.Messages.Msg x -> Msg
fromRepo fallbackMapper subMsg =
    case subMsg of
        Repo.Messages.ChangeLocation url ->
            ChangeLocation url

        Repo.Messages.PromptLogin ->
            PromptLogin

        otherMsg ->
            fallbackMapper otherMsg


{-| Map Actions messages into root (Poller) messages
-}
fromActions : (Actions.Msg -> Msg) -> Actions.Msg -> Msg
fromActions rootMapper msg =
    case msg of
        Actions.RepoMsg (Repo.Messages.ChangeLocation url) ->
            ChangeLocation url

        Actions.RepoMsg Repo.Messages.PromptLogin ->
            PromptLogin

        Actions.Trial Actions.PromptLogin ->
            PromptLogin

        otherMsg ->
            rootMapper otherMsg
