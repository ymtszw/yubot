module Routing exposing (Route(..), parseLocation)

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
    | PollRoute Repo.EntityId
    | ActionsRoute
    | ActionRoute Repo.EntityId
    | AuthsRoute
    | AuthRoute Repo.EntityId
    | NotFoundRoute


parseLocation : Navigation.Location -> ( Route, List (Cmd Msg) )
parseLocation { pathname } =
    case segments pathname of
        [ "poller" ] ->
            -- top
            ( PollsRoute, [ Cmd.map PollsMsg (Repo.Command.fetchAll Polls.config) ] )

        [ "poller", "polls" ] ->
            ( PollsRoute, [ Cmd.map PollsMsg (Repo.Command.fetchAll Polls.config) ] )

        [ "poller", "polls", pollId ] ->
            ( PollRoute pollId, [] )

        [ "poller", "actions" ] ->
            ( ActionsRoute
            , [ Cmd.map ActionsMsg (Repo.Command.fetchAll Actions.config)
              , Cmd.map PollsMsg (Repo.Command.fetchAll Polls.config)
              ]
            )

        [ "poller", "actions", actionId ] ->
            ( ActionRoute actionId, [] )

        [ "poller", "credentials" ] ->
            ( AuthsRoute
            , [ Cmd.map AuthMsg (Repo.Command.fetchAll Authentications.config)
              , Cmd.map PollsMsg (Repo.Command.fetchAll Polls.config)
              , Cmd.map AuthMsg (Repo.Command.fetchAll Authentications.config)
              ]
            )

        [ "poller", "credentials", authId ] ->
            ( AuthRoute authId, [] )

        _ ->
            ( NotFoundRoute, [] )


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
