module Polls
    exposing
        ( Poll
        , Interval
        , dummyPoll
        , config
        , update
        , usedActionIds
        , usedAuthIds
        , intervalToString
        )

import Set exposing (Set)
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Utils
import Repo exposing (Repo)
import Repo.Command exposing (Config)
import Repo.Messages exposing (Msg)
import Repo.Update


-- Model


type alias Interval =
    String


type alias JqFilter =
    String


type alias Poll =
    { url : Utils.Url
    , interval : Interval
    , auth : Maybe Repo.EntityId
    , action : Repo.EntityId
    , filters : List JqFilter
    }


dummyPoll : Poll
dummyPoll =
    Poll "https://example.com" "10" Nothing "" []


usedActionIds : Repo.EntityDict Poll -> Set Repo.EntityId
usedActionIds polls =
    polls
        |> Dict.values
        |> List.map (.data >> .action)
        |> Set.fromList


usedAuthIds : Repo.EntityDict Poll -> Set Repo.EntityId
usedAuthIds polls =
    polls
        |> Dict.values
        |> List.map (.data >> .auth >> Maybe.withDefault "")
        |> Set.fromList


intervalToString : Interval -> String
intervalToString interval =
    case String.toInt interval of
        Ok _ ->
            "every " ++ interval ++ " min."

        Err _ ->
            interval



-- Config


config : Config Poll
config =
    Config "/api/poll" dataDecoder dataEncoder (always "/polls")


dataDecoder : Decode.Decoder Poll
dataDecoder =
    Decode.map5 Poll
        (Decode.field "url" Decode.string)
        (Decode.field "interval" Decode.string)
        (Decode.field "auth" (Decode.maybe Decode.string))
        (Decode.field "action" Decode.string)
        (Decode.field "filters" (Decode.list Decode.string))


dataEncoder : Poll -> Encode.Value
dataEncoder { url, interval, auth, action, filters } =
    Encode.object
        [ ( "url", Encode.string url )
        , ( "interval", Encode.string interval )
        , ( "auth", Utils.encodeMaybe Encode.string auth )
        , ( "action", Encode.string action )
        , ( "filters", filters |> List.map Encode.string |> Encode.list )
        ]



-- Update


update : Msg Poll -> Repo Poll -> ( Repo Poll, Cmd (Msg Poll) )
update =
    Repo.Update.update dummyPoll config
