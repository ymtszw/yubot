module Poller.Command exposing (logout)

import HttpBuilder
import Poller.Messages exposing (Msg(..))


logout : Cmd Msg
logout =
    HttpBuilder.post "/api/user/logout"
        |> HttpBuilder.send (always OnLogout)
