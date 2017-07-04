module Routing exposing (Route(..), parseLocation, routeToPath)

import Regex
import Navigation
import Repo
import Repo.Command
import Poller.Messages exposing (Msg(..))
import Polls
import Actions
import Authentications


type Route
    = PollsRoute
    | NewPollRoute
    | PollRoute Repo.EntityId
    | ActionsRoute
    | NewActionRoute
    | ActionRoute Repo.EntityId
    | AuthsRoute
    | LoginRoute
    | NotFoundRoute


parseLocation : Navigation.Location -> ( Route, List (Cmd Msg), List String )
parseLocation { pathname } =
    case segments pathname of
        [ "poller" ] ->
            -- top
            ( PollsRoute, [ Cmd.map (PollsMsg << Polls.RepoMsg) (Repo.Command.fetchAll Polls.config) ], [] )

        [ "poller", "polls", "new" ] ->
            ( NewPollRoute
            , [ Cmd.map (ActionsMsg << Actions.RepoMsg) (Repo.Command.fetchAll Actions.config)
              , Cmd.map AuthMsg (Repo.Command.fetchAll Authentications.config)
              ]
            , [ "Polls" ]
            )

        [ "poller", "polls" ] ->
            ( PollsRoute, [ Cmd.map (PollsMsg << Polls.RepoMsg) (Repo.Command.fetchAll Polls.config) ], [ "Polls" ] )

        [ "poller", "polls", pollId ] ->
            ( PollRoute pollId
            , [ Cmd.map (PollsMsg << Polls.RepoMsg) (Repo.Command.navigateAndFetchOne Polls.config pollId)
              , Cmd.map (ActionsMsg << Actions.RepoMsg) (Repo.Command.fetchAll Actions.config)
              , Cmd.map AuthMsg (Repo.Command.fetchAll Authentications.config)
              ]
            , [ "Polls" ]
            )

        [ "poller", "actions" ] ->
            ( ActionsRoute, [ Cmd.map (ActionsMsg << Actions.RepoMsg) (Repo.Command.fetchAll Actions.config) ], [ "Actions" ] )

        [ "poller", "actions", "new" ] ->
            ( NewActionRoute
            , [ Cmd.map (PollsMsg << Polls.RepoMsg) (Repo.Command.fetchAll Polls.config)
              , Cmd.map AuthMsg (Repo.Command.fetchAll Authentications.config)
              ]
            , [ "Actions" ]
            )

        [ "poller", "actions", actionId ] ->
            ( ActionRoute actionId
            , [ Cmd.map (ActionsMsg << Actions.RepoMsg) (Repo.Command.navigateAndFetchOne Actions.config actionId)
              , Cmd.map (PollsMsg << Polls.RepoMsg) (Repo.Command.fetchAll Polls.config)
              , Cmd.map AuthMsg (Repo.Command.fetchAll Authentications.config)
              ]
            , [ "Actions" ]
            )

        [ "poller", "credentials" ] ->
            ( AuthsRoute
            , [ Cmd.map AuthMsg (Repo.Command.fetchAll Authentications.config)
              , Cmd.map (PollsMsg << Polls.RepoMsg) (Repo.Command.fetchAll Polls.config)
              , Cmd.map (ActionsMsg << Actions.RepoMsg) (Repo.Command.fetchAll Actions.config)
              ]
            , [ "Credentials" ]
            )

        [ "poller", "login" ] ->
            ( LoginRoute, [], [ "Login" ] )

        _ ->
            ( NotFoundRoute, [], [ "404" ] )


segments : String -> List String
segments pathname =
    let
        segmentPattern =
            "/([^/]*)"

        extractSegment { submatches } =
            case submatches of
                (Just segment) :: _ ->
                    segment

                _ ->
                    ""

        trim reversedSegments =
            case reversedSegments of
                "" :: segs ->
                    trim segs

                segs ->
                    segs
    in
        pathname
            |> Regex.find Regex.All (Regex.regex segmentPattern)
            |> List.map extractSegment
            |> List.reverse
            |> trim
            |> List.reverse


routeToPath : Route -> String
routeToPath route =
    let
        pollerPath =
            case route of
                PollsRoute ->
                    "/polls"

                NewPollRoute ->
                    "/polls/new"

                PollRoute id ->
                    "/polls/" ++ id

                ActionsRoute ->
                    "/actions"

                NewActionRoute ->
                    "/actions/new"

                ActionRoute id ->
                    "/actions/" ++ id

                AuthsRoute ->
                    "/credentials"

                _ ->
                    ""
    in
        "/poller" ++ pollerPath
