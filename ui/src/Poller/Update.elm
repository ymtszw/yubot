module Poller.Update exposing (update)

import Polls
import Actions
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
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
