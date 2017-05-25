module Poller exposing (main)

import Navigation
import WebSocket
import Bootstrap.Navbar
import Routing
import Repo.Command
import Polls
import Actions
import Authentications
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))
import Poller.Update exposing (update)
import Poller.View exposing (view)


type alias Flags =
    { isDev : Bool }


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init { isDev } location =
    let
        ( navbarState, navbarCmd ) =
            Bootstrap.Navbar.initialState NavbarMsg

        currentRoute =
            Routing.parseLocation location
    in
        [ (Cmd.map PollsMsg (Repo.Command.fetchAll Polls.config))
        , (Cmd.map ActionsMsg (Repo.Command.fetchAll Actions.config))
        , (Cmd.map AuthMsg (Repo.Command.fetchAll Authentications.config))
        , navbarCmd
        ]
            |> (!) (Poller.Model.initialModel isDev currentRoute navbarState)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        baseSubs =
            if model.isDev then
                [ WebSocket.listen "ws://yubot.localhost:8080/ws" OnServerPush ]
            else
                []
    in
        baseSubs
            |> (::) (Bootstrap.Navbar.subscriptions model.navbarState NavbarMsg)
            |> Sub.batch



-- MAIN


main : Program Flags Model Msg
main =
    Navigation.programWithFlags OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
