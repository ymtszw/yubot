module Poller.Update exposing (update)

import Date
import Task
import Navigation
import Utils
import Stack
import LiveReload
import Routing
import Title
import Repo.Update exposing (StackCmd(..))
import Repo.Messages
import Polls
import Actions
import Authentications
import Poller.Model exposing (Model)
import Poller.Messages exposing (Msg(..))
import Poller.Command


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ route, taskStack } as model) =
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

        promptLogin =
            if route == Routing.LoginRoute then
                ( model, Cmd.none )
            else
                ( { model
                    | route = Routing.LoginRoute -- Somewhat hacky; preemptively setting next route so that duplicate newUrl won't happen
                    , routeBeforeLogin = Just route
                  }
                , Navigation.newUrl "/poller/login"
                )
    in
        case msg of
            PollsMsg Repo.Messages.PromptLogin ->
                promptLogin

            PollsMsg subMsg ->
                Polls.update subMsg model.pollRepo
                    |> mapUpdate (\x -> { model | pollRepo = x }) PollsMsg

            ActionsMsg (Actions.RepoMsg Repo.Messages.PromptLogin) ->
                promptLogin

            ActionsMsg (Actions.Trial Actions.PromptLogin) ->
                promptLogin

            ActionsMsg subMsg ->
                Actions.update subMsg model.actionRepo
                    |> mapUpdate (\x -> { model | actionRepo = x }) ActionsMsg

            AuthMsg Repo.Messages.PromptLogin ->
                promptLogin

            AuthMsg subMsg ->
                Authentications.update subMsg model.authRepo
                    |> mapUpdate (\x -> { model | authRepo = x }) AuthMsg

            NavbarMsg state ->
                ( { model | navbarState = state }, Cmd.none )

            UserDropdownMsg isVisible ->
                ( { model | userDropdownVisible = isVisible }, Cmd.none )

            PromptLogin ->
                promptLogin

            OnLoginButtonClick ->
                -- Purely cosmetic state; will be refreshed by redirect
                ( { model | taskStack = Stack.push () taskStack }, Cmd.none )

            Logout ->
                ( model, Poller.Command.logout )

            OnLogout ->
                ( model, Navigation.load "/poller/login" )

            ChangeLocation path ->
                ( model, Navigation.newUrl ("/poller" ++ path) )

            OnLocationChange location ->
                let
                    ( route, cmds, subTitles ) =
                        Routing.parseLocation location
                in
                    ( { model | route = route, taskStack = List.map (always ()) cmds }, Cmd.batch (Title.concat subTitles :: cmds) )

            OnServerPush "reload" ->
                ( model, Navigation.reloadAndSkipCache )

            OnServerPush text ->
                ( model, log "Server push" text )

            OnClientTimeout _ ->
                ( model, LiveReload.cmd model.isDev )

            OnReceiveTitle title ->
                ( { model | title = title }, Cmd.none )

            DatedLog label text date ->
                Debug.log ("[" ++ (Utils.dateToFineString date) ++ "] " ++ label) text |> always ( model, Cmd.none )


{-| Log string into console with current datetime.
-}
log : String -> String -> Cmd Msg
log label text =
    Task.perform (DatedLog label text) Date.now
