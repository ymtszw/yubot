module Resource.Update exposing (..)

import Bootstrap.Modal exposing (hiddenState)
import Utils exposing (..)
import Resource exposing (..)
import Resource.Messages exposing (Msg(..))
import Resource.Command exposing (Config, fetchAll, delete)


update :
    resource
    -> Config resource
    -> Msg resource
    -> Resource resource
    -> ( Resource resource, Cmd (Msg resource) )
update dummyResource config msg resource =
    case msg of
        OnFetchAll (Ok newResources) ->
            ( { resource | list = newResources }, Cmd.none )

        OnFetchAll (Err error) ->
            ( resource, Cmd.none )

        OnSort sorter ->
            ( { resource
                | listSort = Just sorter
                , list = sortList sorter resource.list
              }
            , Cmd.none
            )

        OnDeleteModal newState newTarget ->
            ( { resource | deleteModal = DeleteModal newState newTarget }, Cmd.none )

        OnDeleteConfirmed id ->
            ( { resource | deleteModal = DeleteModal hiddenState dummyResource }, (delete config id) )

        OnDelete (Ok ()) ->
            ( resource, fetchAll config )

        OnDelete (Err error) ->
            ( resource, Cmd.none )

        OnEditModal newState newTarget ->
            ( { resource | editModal = EditModal newState newTarget }, Cmd.none )


sortList : Sorter resource -> List resource -> List resource
sortList ( compareBy, order ) list =
    case order of
        Asc ->
            List.sortBy compareBy list

        Desc ->
            list
                |> List.sortBy compareBy
                |> List.reverse
