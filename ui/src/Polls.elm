module Polls exposing (..)

import Date exposing (Date)
import Bootstrap.Modal

-- Model

type alias Poll =
    { id: String
    , updatedAt: Date
    , url: String
    , interval: String
    , auth: Maybe String
    , action: String
    , filters: Maybe (List String)
    }

dummyPoll : Poll
dummyPoll =
    Poll "dummyId" (Date.fromTime 0) "https://example.com" "1" Nothing "dummyActionId" Nothing

type alias DeleteModal =
    { modalState : Bootstrap.Modal.State
    , poll : Poll
    }
