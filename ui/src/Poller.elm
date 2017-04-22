module Poller exposing (..)

import Html exposing (program)
import Bootstrap.Tab
import Polls.Command
import Poller.Model exposing (Model, initialModel)
import Poller.Messages exposing (Msg(PollsMsg, TabMsg))
import Poller.Update exposing (update)
import Poller.View exposing (view)


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.map PollsMsg Polls.Command.fetchAll )



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
