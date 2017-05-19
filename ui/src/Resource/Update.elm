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
update dummyResource config msg rs =
    case msg of
        OnFetchAll (Ok newResources) ->
            ( { rs | list = newResources }, Cmd.none )

        OnFetchAll (Err error) ->
            ( rs, Cmd.none )

        OnSort sorter ->
            ( { rs
                | listSort = Just sorter
                , list = Resource.sortList sorter rs.list
              }
            , Cmd.none
            )

        OnDeleteModal newState newTarget ->
            ( { rs | deleteModal = ModalState newState newTarget [] }, Cmd.none )

        OnDeleteConfirmed id ->
            ( { rs | deleteModal = ModalState hiddenState dummyResource [] }, (delete config id) )

        OnDelete (Ok ()) ->
            ( rs, fetchAll config )

        OnDelete (Err error) ->
            ( rs, Cmd.none )

        OnEditModal newState newTarget ->
            ( { rs | editModal = ModalState newState newTarget [] }, Cmd.none )

        OnEditInput newTarget ->
            ( { rs | editModal = ModalState rs.editModal.modalState newTarget [] }, Cmd.none )

        OnEditInputWithError newTarget newErrorMessage ->
            let
                oldState =
                    rs.editModal.modalState

                oldErrors =
                    rs.editModal.errorMessages
            in
                ( { rs | editModal = ModalState oldState newTarget (newErrorMessage :: oldErrors) }, Cmd.none )
