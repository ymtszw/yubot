module Polls.Command exposing (..)

import Http
import Date exposing (..)
import Json.Decode as Decode exposing (field, at)
import Polls exposing (Poll)
import Polls.Messages exposing (Msg(OnFetchAll))

fetchAll : Cmd Msg
fetchAll =
    Http.get "/api/poll" fetchAllDecoder
        |> Http.send OnFetchAll

fetchAllDecoder : Decode.Decoder (List Poll)
fetchAllDecoder =
    Decode.list fetchDecoder

fetchDecoder : Decode.Decoder Poll
fetchDecoder =
    Decode.map7 Poll
        (field "_id" Decode.string)
        (field "updated_at" dateDecoder)
        (at ["data", "url"] Decode.string)
        (at ["data", "interval"] Decode.string)
        (at ["data", "auth"] (Decode.maybe Decode.string))
        (at ["data", "action"] Decode.string)
        (at ["data", "action"] filtersDecoder)

dateDecoder : Decode.Decoder Date
dateDecoder =
    Decode.map (Date.fromString >> (Result.withDefault fallbackTime)) Decode.string

fallbackTime : Date
fallbackTime =
    Date.fromTime 0.0

filtersDecoder : Decode.Decoder (Maybe (List String))
filtersDecoder =
    Decode.maybe (at ["data", "filters"] (Decode.list Decode.string))