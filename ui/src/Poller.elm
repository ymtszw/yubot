module Poller exposing (..)

import Html exposing (program)
import Bootstrap.Tab
import Bootstrap.Navbar
import Resource.Command
import Polls
import Actions
import Poller.Model exposing (Model, initialModel)
import Poller.Messages exposing (Msg(..))
import Poller.Update exposing (update)
import Poller.View exposing (view)


init : ( Model, Cmd Msg )
init =
    let
        ( navbarState, navbarCmd ) =
            Bootstrap.Navbar.initialState NavbarMsg
    in
        [ (Cmd.map PollsMsg (Resource.Command.fetchAll Polls.config))
        , (Cmd.map ActionsMsg (Resource.Command.fetchAll Actions.config))
        , navbarCmd
        ]
            |> (!) (initialModel navbarState)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Bootstrap.Tab.subscriptions model.tabState TabMsg
        , Bootstrap.Navbar.subscriptions model.navbarState NavbarMsg
        ]



-- MAIN


main : Program Never Model Msg
main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
