module Repo.Update exposing (update)

import Dict
import Http
import Navigation
import Repo
import Repo.Messages exposing (Msg(..))
import Repo.Command as Command exposing (Config)
import Error


update : t -> Config t -> Msg t -> Repo.Repo t -> ( Repo.Repo t, Cmd (Msg t), Bool )
update dummyData config msg repo =
    case msg of
        OnFetchAll (Ok newEntities) ->
            ( Repo.populate newEntities dummyData, Cmd.none, False )

        OnFetchAll (Err httpError) ->
            ( onHttpError repo httpError, Cmd.none, False )

        OnSort sorter ->
            ( { repo | sort = sorter }, Cmd.none, False )

        OnDeleteModal newTarget isShown ->
            ( { repo | deleteModal = Repo.ModalState isShown newTarget }, Cmd.none, False )

        OnDeleteConfirmed id ->
            ( { repo | deleteModal = Repo.ModalState False (Repo.dummyEntity dummyData) }
            , (Command.delete config id)
            , True
            )

        OnDelete (Ok ()) ->
            ( repo, Command.fetchAll config, False )

        OnDelete (Err httpError) ->
            ( onHttpError repo httpError, Cmd.none, False )

        OnEdit entityId dirtyEntity errors ->
            ( { repo | dirtyDict = Dict.insert entityId dirtyEntity repo.dirtyDict, errors = errors }
            , Cmd.none
            , False
            )

        OnEditCancel entityId ->
            ( { repo | dirtyDict = Dict.remove entityId repo.dirtyDict }, Cmd.none, False )

        OnSubmitNew data ->
            ( repo, Command.submitNew config data, True )

        OnCreate (Ok newEntity) ->
            ( repo, Navigation.modifyUrl ("/poller" ++ config.navigateOnWrite newEntity), True )

        OnCreate (Err httpError) ->
            ( onHttpError repo httpError, Cmd.none, False )

        SetErrors newErrors ->
            ( { repo | errors = newErrors }, Cmd.none, False )

        _ ->
            -- Other messages won't match inside Repo; handled by root Update
            ( repo, Cmd.none, False )


onHttpError : Repo.Repo t -> Http.Error -> Repo.Repo t
onHttpError ({ errors } as repo) httpError =
    let
        responseToDesc { url, status, body } =
            [ ( "URL", url )
            , ( "Status", toString status.code ++ " " ++ status.message )
            , ( "Body", body )
            ]

        newErrors =
            case httpError of
                Http.BadStatus response ->
                    [ ( Error.APIError, responseToDesc response ) ]

                Http.BadPayload failureMessage response ->
                    [ ( Error.APIError
                      , ( "Unable to parse body", failureMessage ) :: responseToDesc response
                      )
                    ]

                Http.NetworkError ->
                    [ Error.one Error.NetworkError "Unable to connect" "" ]

                Http.Timeout ->
                    [ Error.one Error.APIError "Server timeout" "" ]

                Http.BadUrl url ->
                    [ Error.one Error.ValidationError "Invalid URL" url ]
    in
        { repo | errors = newErrors }
