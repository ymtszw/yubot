module Poller.Update exposing (update)

import Date
import Task
import Navigation
import Utils
import Stack
import LiveReload
import Routing
import Repo.Update exposing (StackCmd(..))
import Polls
import Actions
import Authentications
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ taskStack } as model) =
    let
        resolveTask stackCmd model =
            let
                newStack =
                    case stackCmd of
                        Push ->
                            Stack.push () taskStack

                        Keep ->
                            taskStack

                        Pop ->
                            taskStack |> Stack.pop |> Tuple.second
            in
                { model | taskStack = newStack }

        mapUpdate repoToModel msg ( x, cmd, stackCmd ) =
            ( x |> repoToModel |> resolveTask stackCmd, Cmd.map msg cmd )
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
                ( model, Navigation.newUrl ("/poller" ++ path) )

            OnLocationChange location ->
                let
                    ( route, cmds ) =
                        Routing.parseLocation location
                in
                    ( { model | route = route, taskStack = List.map (always ()) cmds }, Cmd.batch cmds )

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
