module Poller exposing (main)

import Navigation
import Bootstrap.Navbar
import Routing
import Resource.Command
import Polls
import Actions
import Authentications
import Poller.Model exposing (Model, initialModel)
import Poller.Messages exposing (Msg(..))
import Poller.Update exposing (update)
import Poller.View exposing (view)


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        ( navbarState, navbarCmd ) =
            Bootstrap.Navbar.initialState NavbarMsg

        currentRoute =
            Routing.parseLocation location
    in
        [ (Cmd.map PollsMsg (Resource.Command.fetchAll Polls.config))
        , (Cmd.map ActionsMsg (Resource.Command.fetchAll Actions.config))
        , (Cmd.map AuthMsg (Resource.Command.fetchAll Authentications.config))
        , navbarCmd
        ]
            |> (!) (initialModel currentRoute navbarState)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Bootstrap.Navbar.subscriptions model.navbarState NavbarMsg
        ]



-- MAIN


main : Program Never Model Msg
main =
    Navigation.program OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
