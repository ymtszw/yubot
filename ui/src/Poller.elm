module Poller exposing (..)

import Html exposing (program)
import Bootstrap.Tab
import Resource.Command
import Polls
import Actions
import Poller.Model exposing (Model, initialModel)
import Poller.Messages exposing (Msg(..))
import Poller.Update exposing (update)
import Poller.View exposing (view)


init : ( Model, Cmd Msg )
init =
    [ (Cmd.map PollsMsg (Resource.Command.fetchAll Polls.config))
    , (Cmd.map ActionsMsg (Resource.Command.fetchAll Actions.config))
    ]
        |> (!) initialModel



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Bootstrap.Tab.subscriptions model.tabState TabMsg



-- MAIN


main : Program Never Model Msg
main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
