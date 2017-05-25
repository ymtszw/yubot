module Poller.Update exposing (update)

import Navigation
import LiveReload
import Routing
import Polls
import Actions
import Authentications
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        mapUpdate repoToModel msg ( repo, cmd ) =
            ( repoToModel repo, Cmd.map msg cmd )
    in
        case msg of
            PollsMsg subMsg ->
                Polls.update subMsg model.pollRepo
                    |> mapUpdate (\x -> { model | pollRepo = x }) PollsMsg

            ActionsMsg subMsg ->
                Actions.update subMsg model.actionRepo
                    |> mapUpdate (\x -> { model | actionRepo = x }) ActionsMsg

            AuthMsg subMsg ->
                Authentications.update subMsg model.authRepo
                    |> mapUpdate (\x -> { model | authRepo = x }) AuthMsg

            NavbarMsg state ->
                ( { model | navbarState = state }, Cmd.none )

            ChangeLocation path ->
                ( model, Navigation.modifyUrl ("/poller" ++ path) )

            OnLocationChange location ->
                ( { model | route = Routing.parseLocation location }, Cmd.none )

            OnServerPush "reload" ->
                ( model, Navigation.reloadAndSkipCache )

            OnServerPush text ->
                Debug.log "Server push" text |> always ( model, Cmd.none )

            OnClientTimeout _ ->
                ( model, LiveReload.cmd model.isDev )
