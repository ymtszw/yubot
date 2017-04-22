module Poller.Update exposing (..)

import Polls.Update
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PollsMsg subMsg ->
            let
                ( updatedModel, cmd ) =
                    Polls.Update.update subMsg model
            in
                ( updatedModel, Cmd.map PollsMsg cmd )

        TabMsg state ->
            ( { model | tabState = state }, Cmd.none )
