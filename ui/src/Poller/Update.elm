module Poller.Update exposing (update)

import Navigation
import Routing
import Polls
import Actions
import Authentications
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PollsMsg subMsg ->
            let
                ( updatedPollRepo, cmd ) =
                    Polls.update subMsg model.pollRepo
            in
                ( { model | pollRepo = updatedPollRepo }, Cmd.map PollsMsg cmd )

        ActionsMsg subMsg ->
            let
                ( updatedActionRepo, cmd ) =
                    Actions.update subMsg model.actionRepo
            in
                ( { model | actionRepo = updatedActionRepo }, Cmd.map ActionsMsg cmd )

        AuthMsg subMsg ->
            let
                ( updatedAuthRepo, cmd ) =
                    Authentications.update subMsg model.authRepo
            in
                ( { model | authRepo = updatedAuthRepo }, Cmd.map AuthMsg cmd )

        NavbarMsg state ->
            ( { model | navbarState = state }, Cmd.none )

        ChangeLocation path ->
            ( model, Navigation.modifyUrl ("/poller" ++ path) )

        OnLocationChange location ->
            ( { model | route = Routing.parseLocation location }, Cmd.none )

        OnServerPush text ->
            case text of
                "reload" ->
                    ( model, Navigation.reloadAndSkipCache )

                _ ->
                    text
                        |> Debug.log "Server push"
                        |> always ( model, Cmd.none )
