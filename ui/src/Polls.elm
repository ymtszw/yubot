module Polls
    exposing
        ( Poll
        , Interval
        , dummyPoll
        , config
        , update
        , usedActionIds
        , intervalToString
        )

import Set exposing (Set)
import Json.Decode as Decode
import Utils exposing (..)
import Resource exposing (Resource)
import Resource.Command exposing (Config)
import Resource.Messages exposing (Msg)
import Resource.Update


-- Model


type alias Interval =
    String


type alias JqFilter =
    String


type alias Poll =
    { id : EntityId
    , updatedAt : Timestamp
    , url : Url
    , interval : Interval
    , auth : Maybe EntityId
    , action : EntityId
    , filters : Maybe (List JqFilter)
    }


dummyPoll : Poll
dummyPoll =
    Poll "" "2015-01-01T00:00:00Z" "https://example.com" "10" Nothing "" Nothing


usedActionIds : List Poll -> Set EntityId
usedActionIds polls =
    polls
        |> List.map .action
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
    Config "/api/poll" fetchDecoder


fetchDecoder : Decode.Decoder Poll
fetchDecoder =
    Decode.map7 Poll
        (Decode.field "_id" Decode.string)
        (Decode.field "updated_at" Decode.string)
        (Decode.at [ "data", "url" ] Decode.string)
        (Decode.at [ "data", "interval" ] Decode.string)
        (Decode.at [ "data", "auth" ] (Decode.maybe Decode.string))
        (Decode.at [ "data", "action" ] Decode.string)
        (Decode.at [ "data", "filters" ] (Decode.maybe (Decode.list Decode.string)))



-- Update


update : Msg Poll -> Resource Poll -> ( Resource Poll, Cmd (Msg Poll) )
update msg resource =
    Resource.Update.update dummyPoll config msg resource
