module Polls exposing (..)

import Bootstrap.Modal as Modal


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
