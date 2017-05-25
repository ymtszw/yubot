module Routing exposing (Route(..), parseLocation, isActiveTab)

import Regex
import Navigation
import Repo


type Route
    = PollsRoute
    | PollRoute Repo.EntityId
    | ActionsRoute
    | ActionRoute Repo.EntityId
    | AuthsRoute
    | AuthRoute Repo.EntityId
    | NotFoundRoute


parseLocation : Navigation.Location -> Route
parseLocation { pathname } =
    case segments pathname of
        [ "poller" ] ->
            -- top
            PollsRoute

        [ "poller", "polls" ] ->
            PollsRoute

        [ "poller", "polls", pollId ] ->
            PollRoute pollId

        [ "poller", "actions" ] ->
            ActionsRoute

        [ "poller", "actions", actionId ] ->
            ActionRoute actionId

        [ "poller", "credentials" ] ->
            AuthsRoute

        [ "poller", "credentials", authId ] ->
            AuthRoute authId

        _ ->
            NotFoundRoute


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


isActiveTab : Route -> Int -> Bool
isActiveTab route index =
    case route of
        ActionsRoute ->
            index == 1

        ActionRoute _ ->
            index == 1

        AuthsRoute ->
            index == 2

        AuthRoute _ ->
            index == 2

        _ ->
            index == 0
