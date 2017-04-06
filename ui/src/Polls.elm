module Polls exposing (..)

import Http
import Date
import Json.Decode as Decode exposing (field)

-- Model

type alias Poll =
    { id: String
    , updatedAt: String
    }

-- Messages

type Msg
    = OnFetchAll (Result Http.Error (List Poll))

-- Updates

update : Msg -> List Poll -> ( List Poll, Cmd Msg )
update message polls =
    case message of
        OnFetchAll (Ok newPolls) ->
            ( newPolls, Cmd.none )
        OnFetchAll (Err error) ->
            ( polls, Cmd.none )

-- Commands

fetchAll : Cmd Msg
fetchAll =
    Http.get "/api/poll" fetchAllDecoder
        |> Http.send OnFetchAll

fetchAllDecoder : Decode.Decoder (List Poll)
fetchAllDecoder =
    Decode.list fetchDecoder

fetchDecoder : Decode.Decoder (Poll)
fetchDecoder =
    Decode.map2 Poll
        (field "_id" Decode.string)
        (field "updated_at" Decode.string)
