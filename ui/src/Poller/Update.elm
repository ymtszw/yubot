module Poller.Update exposing (..)

import Polls
import Actions
import Poller.Model exposing (Model, diffDump)
import Poller.Messages exposing (Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( updatedModel, newCmd ) =
            case msg of
                PollsMsg subMsg ->
                    let
                        ( updatedPollRs, cmd ) =
                            Polls.update subMsg model.pollRs
                    in
                        ( { model | pollRs = updatedPollRs }, Cmd.map PollsMsg cmd )

                ActionsMsg subMsg ->
                    let
                        ( updatedActionRs, cmd ) =
                            Actions.update subMsg model.actionRs
                    in
                        ( { model | actionRs = updatedActionRs }, Cmd.map ActionsMsg cmd )

                TabMsg state ->
                    ( { model | tabState = state }, Cmd.none )

                NavbarMsg state ->
                    ( { model | navbarState = state }, Cmd.none )

                Verbose bool ->
                    ( { model | verbose = bool }, Cmd.none )
    in
        if model.verbose || updatedModel.verbose then
            ( diffDump model updatedModel, newCmd )
        else
            ( updatedModel, newCmd )
