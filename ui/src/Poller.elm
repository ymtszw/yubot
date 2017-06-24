module Poller exposing (main)

import Navigation
import Bootstrap.Navbar
import LiveReload
import Routing
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))
import Poller.Update
import Poller.View


type alias Flags =
    { isDev : Bool }


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init { isDev } location =
    let
        ( navbarState, navbarCmd ) =
            Bootstrap.Navbar.initialState NavbarMsg

        ( currentRoute, initCmds ) =
            Routing.parseLocation location

        initTaskStack =
            List.map (always ()) initCmds
    in
        Poller.Model.initialModel isDev initTaskStack currentRoute navbarState ! (navbarCmd :: initCmds)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    [ Bootstrap.Navbar.subscriptions model.navbarState NavbarMsg ]
        |> (++) (LiveReload.sub model.isDev)
        |> Sub.batch



-- MAIN


main : Program Flags Model Msg
main =
    Navigation.programWithFlags OnLocationChange
        { init = init
        , view = Poller.View.view
        , update = Poller.Update.update
        , subscriptions = subscriptions
        }
