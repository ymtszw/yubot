module Polls.Update exposing (..)

import Bootstrap.Modal exposing (hiddenState)
import Polls exposing (..)
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

        OnSort sorter ->
            ( { model
                | pollsSort = Just sorter
                , polls = sortPolls sorter model.polls
              }
            , Cmd.none
            )

        OnDeleteModal newState newPoll ->
            ( { model | pollDeleteModal = DeleteModal newState newPoll }, Cmd.none )

        OnDeleteConfirmed id ->
            ( { model | pollDeleteModal = DeleteModal hiddenState dummyPoll }, (delete id) )

        OnDelete (Ok ()) ->
            ( model, fetchAll )

        OnDelete (Err error) ->
            ( model, Cmd.none )

        OnEditModal newState newPoll ->
            ( { model | pollEditModal = EditModal newState newPoll }, Cmd.none )


sortPolls : Sorter -> List Poll -> List Poll
sortPolls ( compareBy, order ) polls =
    case order of
        Asc ->
            List.sortBy compareBy polls

        Desc ->
            polls
                |> List.sortBy compareBy
                |> List.reverse
