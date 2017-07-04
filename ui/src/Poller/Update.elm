module Poller.Update exposing (update)

import Date
import Task
import Navigation
import Utils
import Stack
import LiveReload
import Routing
import Document
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
            PollsMsg (Polls.RepoMsg (Repo.Messages.ChangeLocation path)) ->
                changeLocation model path

            PollsMsg (Polls.RepoMsg Repo.Messages.PromptLogin) ->
                promptLogin

            PollsMsg (Polls.Trial Polls.PromptLogin) ->
                promptLogin

            PollsMsg subMsg ->
                Polls.update subMsg model.pollRepo
                    |> mapUpdate (\x -> { model | pollRepo = x }) PollsMsg

            ActionsMsg (Actions.RepoMsg (Repo.Messages.ChangeLocation path)) ->
                changeLocation model path

            ActionsMsg (Actions.RepoMsg Repo.Messages.PromptLogin) ->
                promptLogin

            ActionsMsg (Actions.Trial Actions.PromptLogin) ->
                promptLogin

            ActionsMsg subMsg ->
                Actions.update subMsg model.actionRepo
                    |> mapUpdate (\x -> { model | actionRepo = x }) ActionsMsg

            AuthMsg (Repo.Messages.ChangeLocation path) ->
                changeLocation model path

            AuthMsg Repo.Messages.PromptLogin ->
                promptLogin

            AuthMsg subMsg ->
                Authentications.update subMsg model.authRepo
                    |> mapUpdate (\x -> { model | authRepo = x }) AuthMsg

            NavbarMsg state ->
                ( { model | navbarState = state }, Cmd.none )

            UserDropdownMsg Utils.Shown ->
                ( { model | userDropdownState = Utils.Shown }, Document.setBackgroundClickListener () )

            UserDropdownMsg Utils.Fading ->
                { model | userDropdownState = Utils.Fading }
                    ! [ Document.removeBackgroundClickListener ()
                      , Utils.emitIn 400 (UserDropdownMsg Utils.Hidden)
                      ]

            UserDropdownMsg state ->
                ( { model | userDropdownState = state }, Cmd.none )

            PromptLogin ->
                promptLogin

            OnLoginButtonClick ->
                -- Purely cosmetic state; will be refreshed by redirect
                ( { model | taskStack = Stack.push () taskStack }, Cmd.none )

            Logout ->
                ( model, Poller.Command.logout ) |> fadeDropdownIfShown

            OnLogout ->
                ( model, Navigation.load "/poller/login" )

            ChangeLocation path ->
                changeLocation model path

            OnLocationChange location ->
                let
                    ( route, cmds, subTitles ) =
                        Routing.parseLocation location
                in
                    { model | route = route, taskStack = List.map (always ()) cmds } ! (Document.concatSubtitles subTitles :: cmds)

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

            NoOp ->
                ( model, Cmd.none )


andThen : (Model -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
andThen anotherUpdate ( model, cmd ) =
    let
        ( newModel, newCmd ) =
            anotherUpdate model
    in
        newModel ! [ cmd, newCmd ]


changeLocation : Model -> Utils.Url -> ( Model, Cmd Msg )
changeLocation model path =
    ( model, Navigation.newUrl ("/poller" ++ path) ) |> fadeDropdownIfShown


fadeDropdownIfShown : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
fadeDropdownIfShown (( model, cmd ) as prev) =
    if model.userDropdownState == Utils.Shown then
        prev |> andThen (update (UserDropdownMsg Utils.Fading))
    else
        prev


{-| Log string into console with current datetime.
-}
log : String -> String -> Cmd Msg
log label text =
    Task.perform (DatedLog label text) Date.now
