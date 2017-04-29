module Resource.Update exposing (update)

import Bootstrap.Modal exposing (hiddenState)
import Resource exposing (Resource, ModalState)
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
                , list = Resource.sortList sorter resource.list
              }
            , Cmd.none
            )

        OnDeleteModal newState newTarget ->
            ( { resource | deleteModal = ModalState newState newTarget }, Cmd.none )

        OnDeleteConfirmed id ->
            ( { resource | deleteModal = ModalState hiddenState dummyResource }, (delete config id) )

        OnDelete (Ok ()) ->
            ( resource, fetchAll config )

        OnDelete (Err error) ->
            ( resource, Cmd.none )

        OnEditModal newState newTarget ->
            ( { resource | editModal = ModalState newState newTarget }, Cmd.none )
