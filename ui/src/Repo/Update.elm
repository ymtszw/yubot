module Repo.Update exposing (update)

import Dict
import Http
import Navigation
import Repo
import Repo.Messages exposing (Msg(..))
import Repo.Command as Command exposing (Config)
import Error


update : t -> Config t -> Msg t -> Repo.Repo t -> ( Repo.Repo t, Cmd (Msg t) )
update dummyData config msg repo =
    case msg of
        OnFetchAll (Ok newEntities) ->
            ( Repo.populate newEntities dummyData, Cmd.none )

        OnFetchAll (Err httpError) ->
            ( onHttpError repo httpError, Cmd.none )

        OnSort sorter ->
            ( { repo | sort = sorter }, Cmd.none )

        OnDeleteModal newTarget isShown ->
            ( { repo | deleteModal = Repo.ModalState isShown newTarget }, Cmd.none )

        OnDeleteConfirmed id ->
            ( { repo | deleteModal = Repo.ModalState False (Repo.dummyEntity dummyData) }
            , (Command.delete config id)
            )

        OnDelete (Ok ()) ->
            ( repo, Command.fetchAll config )

        OnDelete (Err httpError) ->
            ( onHttpError repo httpError, Cmd.none )

        OnEdit entityId dirtyEntity errors ->
            ( { repo | dirtyDict = Dict.insert entityId dirtyEntity repo.dirtyDict, errors = errors }
            , Cmd.none
            )

        OnEditCancel entityId ->
            ( { repo | dirtyDict = Dict.remove entityId repo.dirtyDict }, Cmd.none )

        OnSubmitNew data ->
            ( repo, Command.submitNew config data )

        OnCreate (Ok newEntity) ->
            ( repo, Navigation.modifyUrl ("/poller" ++ config.navigateOnWrite newEntity) )

        OnCreate (Err httpError) ->
            ( onHttpError repo httpError, Cmd.none )

        SetErrors newErrors ->
            ( { repo | errors = newErrors }, Cmd.none )

        _ ->
            -- Other messages won't match inside Repo; handled by root Update
            ( repo, Cmd.none )


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
