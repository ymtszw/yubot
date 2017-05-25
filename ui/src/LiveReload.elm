module LiveReload exposing (set, ping)

import Time
import WebSocket
import Poller.Messages exposing (Msg(..))


devWebsocketUrl : String
devWebsocketUrl =
    "ws://yubot.localhost:8080/ws"


set : Bool -> List (Sub Msg)
set isDev =
    if isDev then
        [ WebSocket.listen devWebsocketUrl OnServerPush
        , Time.every (30 * Time.second) OnClientTimeout
        ]
    else
        []


ping : Bool -> Cmd Msg
ping isDev =
    if isDev then
        WebSocket.send devWebsocketUrl "ping"
    else
        Cmd.none
