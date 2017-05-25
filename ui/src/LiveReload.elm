module LiveReload exposing (sub, cmd)

import Time
import WebSocket
import Poller.Messages exposing (Msg(..))


devWebsocketUrl : String
devWebsocketUrl =
    "ws://yubot.localhost:8080/ws"


sub : Bool -> List (Sub Msg)
sub isDev =
    if isDev then
        [ WebSocket.listen devWebsocketUrl OnServerPush
        , Time.every (30 * Time.second) OnClientTimeout
        ]
    else
        []


cmd : Bool -> Cmd Msg
cmd isDev =
    if isDev then
        WebSocket.send devWebsocketUrl "ping"
    else
        Cmd.none
