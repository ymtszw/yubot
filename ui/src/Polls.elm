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
    Config "/api/poll" dataDecoder


dataDecoder : Decode.Decoder Poll
dataDecoder =
    Decode.map5 Poll
        (Decode.field "url" Decode.string)
        (Decode.field "interval" Decode.string)
        (Decode.field "auth" (Decode.maybe Decode.string))
        (Decode.field "action" Decode.string)
        (Decode.field "filters" (Decode.list Decode.string))



-- Update


update : Msg Poll -> Repo Poll -> ( Repo Poll, Cmd (Msg Poll) )
update =
    Repo.Update.update dummyPoll config
