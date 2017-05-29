module Repo.Update exposing (update)

import Bootstrap.Modal as Modal
import Repo
import Repo.Messages exposing (Msg(..))
import Repo.Command as Command exposing (Config)


update : t -> Config t -> Msg t -> Repo.Repo t -> ( Repo.Repo t, Cmd (Msg t) )
update dummyData config msg repo =
    case msg of
        OnFetchAll (Ok newEntities) ->
            ( { repo | dict = Repo.listToDict newEntities }, Cmd.none )

        OnFetchAll (Err error) ->
            ( repo, Cmd.none )

        OnSort sorter ->
            ( { repo | sort = sorter }, Cmd.none )

        OnDeleteModal newTarget newState ->
            ( { repo | deleteModal = Repo.ModalState newState newTarget }, Cmd.none )

        OnDeleteConfirmed id ->
            ( { repo | deleteModal = Repo.ModalState Modal.hiddenState (Repo.dummyEntity dummyData) }
            , (Command.delete config id)
            )

        OnDelete (Ok ()) ->
            ( repo, Command.fetchAll config )

        OnDelete (Err error) ->
            ( repo, Cmd.none )

        OnEditStart dirtyEntity ->
            ( { repo | dirty = dirtyEntity }, Cmd.none )

        OnEditInput dirtyEntityData errorMessages ->
            let
                oldDirty =
                    repo.dirty
            in
                ( { repo | dirty = { oldDirty | data = dirtyEntityData }, errorMessages = errorMessages }, Cmd.none )

        ChangeLocation _ ->
            -- Won't match inside Repo; handled by root Update
            ( repo, Cmd.none )
