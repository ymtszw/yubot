module Polls exposing (..)

import Date exposing (Date)
import Bootstrap.Modal as Modal


-- Model


type alias Poll =
    { id : String
    , updatedAt : Date
    , url : String
    , interval : String
    , auth : Maybe String
    , action : String
    , filters : Maybe (List String)
    }


dummyPoll : Poll
dummyPoll =
    Poll "" (Date.fromTime 0) "https://example.com" "10" Nothing "" Nothing


type alias DeleteModal =
    { modalState : Modal.State
    , poll : Poll
    }


type alias EditModal =
    { modalState : Modal.State
    , poll : Poll
    }


type Ord
    = Asc
    | Desc



-- Currently, only string field can be sorted


type alias Sorter =
    ( Poll -> String, Ord )
