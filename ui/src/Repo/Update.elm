module Repo.Update exposing (StackCmd(..), update, onHttpError)

import Dict
import Http
import Navigation
import Utils
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Repo.Command as Command exposing (Config)
import Error


type StackCmd
    = Push
    | Keep
    | Pop


update : t -> Config t -> Msg t -> Repo a t -> ( Repo a t, Cmd (Msg t), StackCmd )
update dummyData config msg ({ dirtyDict, errors } as repo) =
    case msg of
        OnFetchOne (Ok newEntity) ->
            ( Repo.put newEntity repo, Cmd.none, Pop )

        OnFetchOne (Err httpError) ->
            onHttpError PromptLogin repo httpError

        OnNavigateAndFetchOne (Ok newEntity) ->
            ( Repo.put newEntity repo, Cmd.none, Pop )

        OnNavigateAndFetchOne (Err httpError) ->
            -- Skip error toast since NotFound page will be shown
            ( repo, Cmd.none, Pop )

        OnFetchAll (Ok newEntities) ->
            ( { repo | dict = Repo.listToDict newEntities }, Cmd.none, Pop )

        OnFetchAll (Err httpError) ->
            onHttpError PromptLogin repo httpError

        Sort sorter ->
            ( { repo | sort = sorter }, Cmd.none, Keep )

        ConfirmDelete newTarget ->
            ( { repo | deleteModal = Repo.ModalState True newTarget }, Cmd.none, Keep )

        CancelDelete ->
            ( { repo | deleteModal = Repo.ModalState False (Repo.dummyEntity dummyData) }, Cmd.none, Keep )

        Delete id ->
            ( { repo | deleteModal = Repo.ModalState False (Repo.dummyEntity dummyData) }
            , (Command.delete config id)
            , Push
            )

        OnDelete (Ok ()) ->
            ( repo, Navigation.newUrl ("/poller" ++ config.indexPath), Pop )

        OnDelete (Err httpError) ->
            onHttpError PromptLogin repo httpError

        StartEdit entityId dirtyEntity ->
            ( { repo | dirtyDict = Dict.insert entityId ( dirtyEntity, Dict.empty ) dirtyDict }, Cmd.none, Keep )

        OnEdit entityId ( label, maybeMessage ) dirtyData ->
            ( { repo | dirtyDict = Repo.onEdit dirtyDict entityId label maybeMessage dirtyData }, Cmd.none, Keep )

        OnValidate entityId ( label, maybeMessage ) ->
            ( { repo | dirtyDict = Repo.onValidate dirtyDict entityId label maybeMessage }, Cmd.none, Keep )

        OnEditValid entityId dirtyData ->
            ( { repo | dirtyDict = Repo.onEdit dirtyDict entityId "dummy" Nothing dirtyData }, Cmd.none, Keep )

        CancelEdit entityId ->
            ( { repo | dirtyDict = Dict.remove entityId dirtyDict }, Cmd.none, Keep )

        Create dirtyId data ->
            ( repo, Command.create config dirtyId data, Push )

        OnCreate dirtyId (Ok newEntity) ->
            ( { repo | dirtyDict = Dict.remove dirtyId dirtyDict }
            , Navigation.newUrl ("/poller" ++ config.navigateOnWrite newEntity)
            , Pop
            )

        OnCreate dirtyId (Err httpError) ->
            onHttpError PromptLogin repo httpError

        DismissError errorIndex ->
            ( { repo | errors = Utils.listUpdateAt errorIndex Error.dismiss errors }
            , Utils.emitIn 400 (SetErrors (Utils.listDeleteAt errorIndex errors))
            , Keep
            )

        SetErrors newErrors ->
            ( { repo | errors = newErrors }, Cmd.none, Keep )

        Update dirtyId data ->
            ( repo, Command.update config dirtyId data, Push )

        OnUpdate (Ok newEntity) ->
            ( { repo | dirtyDict = Dict.remove newEntity.id dirtyDict } |> Repo.put newEntity, Cmd.none, Pop )

        OnUpdate (Err httpError) ->
            onHttpError PromptLogin repo httpError

        _ ->
            -- Should not happen; stolen by root update
            ( repo, Cmd.none, Keep )


handleAuthorized : Repo a t -> Http.Error -> Repo a t
handleAuthorized ({ errors } as repo) httpError =
    let
        responseToDesc { url, status, body } =
            [ ( "URL", url )
            , ( "Status", toString status.code ++ " " ++ status.message )
            , ( "Body", body )
            ]

        newError =
            case httpError of
                Http.BadStatus response ->
                    ( Error.APIError, responseToDesc response, False )

                Http.BadPayload failureMessage response ->
                    ( Error.APIError, ( "Unable to parse body", failureMessage ) :: responseToDesc response, False )

                Http.NetworkError ->
                    Error.one Error.NetworkError "Unable to connect" ""

                Http.Timeout ->
                    Error.one Error.APIError "Server timeout" ""

                Http.BadUrl url ->
                    Error.one Error.UnexpectedError "Invalid URL" url
    in
        { repo | errors = newError :: errors }


onHttpError : msg -> Repo a t -> Http.Error -> ( Repo a t, Cmd msg, StackCmd )
onHttpError promptLogin repo httpError =
    case httpError of
        Http.BadStatus { status } ->
            if status.code == 401 then
                ( repo, Utils.emit promptLogin, Pop )
            else
                ( handleAuthorized repo httpError, Cmd.none, Pop )

        _ ->
            ( handleAuthorized repo httpError, Cmd.none, Pop )
