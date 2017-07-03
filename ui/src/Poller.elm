module Poller exposing (main)

import Json.Decode
import Navigation
import Bootstrap.Navbar
import Utils
import LiveReload
import Routing
import Document
import User exposing (User)
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))
import Poller.Update
import Poller.View


type alias Flags =
    { isDev : Bool
    , user : Maybe Json.Decode.Value
    }


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init { isDev, user } location =
    let
        ( navbarState, navbarCmd ) =
            Bootstrap.Navbar.initialState NavbarMsg

        ( currentRoute, initCmds0, subTitles ) =
            Routing.parseLocation location

        ( initCmds1, promptLoginCmds ) =
            Utils.ite (Utils.isJust user) ( initCmds0, [] ) ( [], [ Utils.emit PromptLogin ] )

        decodedUser =
            user
                |> Maybe.andThen (Json.Decode.decodeValue User.decoder >> Result.toMaybe)

        initTaskStack =
            List.map (always ()) initCmds1
    in
        Poller.Model.initialModel isDev decodedUser initTaskStack currentRoute navbarState
            ! (Document.concatSubtitles subTitles :: navbarCmd :: (initCmds1 ++ promptLoginCmds))



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions { isDev, navbarState, userDropdownState } =
    [ Bootstrap.Navbar.subscriptions navbarState NavbarMsg
    , Document.receiveTitle OnReceiveTitle
    ]
        |> (++) (LiveReload.sub isDev)
        |> (++) (backgroundClickSub userDropdownState)
        |> Sub.batch


backgroundClickSub : Utils.DropdownState -> List (Sub Msg)
backgroundClickSub userDropdownState =
    if userDropdownState == Utils.Shown then
        [ Document.listenBackgroundClick (always (UserDropdownMsg Utils.Fading)) ]
    else
        []



-- MAIN


main : Program Flags Model Msg
main =
    Navigation.programWithFlags OnLocationChange
        { init = init
        , view = Poller.View.view
        , update = Poller.Update.update
        , subscriptions = subscriptions
        }
