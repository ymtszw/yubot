module Poller.Update exposing (update)

import Date
import Task
import Navigation
import Utils
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
        mapUpdate repoToModel msg ( x, cmd, isBusy ) =
            ( repoToModel x isBusy, Cmd.map msg cmd )
    in
        case msg of
            PollsMsg subMsg ->
                Polls.update subMsg model.pollRepo
                    |> mapUpdate (\x isBusy -> { model | pollRepo = x, isBusy = isBusy }) PollsMsg

            ActionsMsg subMsg ->
                Actions.update subMsg model.actionRepo
                    |> mapUpdate (\x isBusy -> { model | actionRepo = x, isBusy = isBusy }) ActionsMsg

            AuthMsg subMsg ->
                Authentications.update subMsg model.authRepo
                    |> mapUpdate (\x isBusy -> { model | authRepo = x, isBusy = isBusy }) AuthMsg

            NavbarMsg state ->
                ( { model | navbarState = state }, Cmd.none )

            ChangeLocation path ->
                ( model, Navigation.modifyUrl ("/poller" ++ path) )

            OnLocationChange location ->
                let
                    ( route, cmds, isBusy ) =
                        Routing.parseLocation location
                in
                    ( { model | route = route, isBusy = isBusy }, Cmd.batch cmds )

            OnServerPush "reload" ->
                ( model, Navigation.reloadAndSkipCache )

            OnServerPush text ->
                ( model, log "Server push" text )

            OnClientTimeout _ ->
                ( model, LiveReload.cmd model.isDev )

            DatedLog label text date ->
                Debug.log ("[" ++ (Utils.dateToFineString date) ++ "] " ++ label) text |> always ( model, Cmd.none )


{-| Log string into console with current datetime.
-}
log : String -> String -> Cmd Msg
log label text =
    Task.perform (DatedLog label text) Date.now
