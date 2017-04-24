module Actions exposing (..)

import Bootstrap.Modal as Modal


-- Model


type alias BodyTemplate =
    { body : String
    , variables : List String
    }


type alias Action =
    { id : String
    , updatedAt : String
    , method : String
    , url : String
    , auth : Maybe String
    , bodyTemplate : BodyTemplate
    }


dummyAction : Action
dummyAction =
    Action "" "2015-01-01T00:00:00Z" "POST" "https://example.com" Nothing (BodyTemplate "{}" [])


type alias DeleteModal =
    { modalState : Modal.State
    , action : Action
    }


type alias EditModal =
    { modalState : Modal.State
    , action : Action
    }
