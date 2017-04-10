module Polls.Update exposing (..)

import Polls exposing (DeleteModal)
import Polls.Messages exposing (Msg(..))
import Poller.Model exposing (Model)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnFetchAll (Ok newPolls) ->
            ( { model | polls = newPolls }, Cmd.none )
        OnFetchAll (Err error) ->
            ( model, Cmd.none )
        OnDeleteModal newState newPoll ->
            ( { model | pollDeleteModal = DeleteModal newState newPoll }, Cmd.none )
