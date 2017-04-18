module Polls.Update exposing (..)

import Bootstrap.Modal exposing (hiddenState)
import Polls exposing (DeleteModal, dummyPoll)
import Polls.Messages exposing (Msg(..))
import Polls.Command exposing (fetchAll, delete)
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
        OnDeleteConfirmed id ->
            ( { model | pollDeleteModal = DeleteModal hiddenState dummyPoll }, (delete id) )
        OnDelete (Ok ()) ->
            ( model, fetchAll )
        OnDelete (Err error) ->
            ( model, Cmd.none )
