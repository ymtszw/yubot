module Polls exposing (..)

import Json.Decode as Decode
import Bootstrap.Modal as Modal
import Resource exposing (Resource)
import Resource.Command exposing (Config)
import Resource.Messages exposing (Msg)
import Resource.Update


-- Model


type alias Poll =
    { id : String
    , updatedAt : String
    , url : String
    , interval : String
    , auth : Maybe String
    , action : String
    , filters : Maybe (List String)
    }


dummyPoll : Poll
dummyPoll =
    Poll "" "2015-01-01T00:00:00Z" "https://example.com" "10" Nothing "" Nothing


type alias DeleteModal =
    { modalState : Modal.State
    , poll : Poll
    }


type alias EditModal =
    { modalState : Modal.State
    , poll : Poll
    }



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
