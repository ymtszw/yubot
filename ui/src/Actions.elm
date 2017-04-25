module Actions exposing (..)

import Json.Decode as Decode
import Bootstrap.Modal as Modal
import Resource exposing (Resource)
import Resource.Command exposing (Config)
import Resource.Messages exposing (Msg)
import Resource.Update


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



-- Config


config : Config Action
config =
    Config "/api/action" fetchDecoder


fetchDecoder : Decode.Decoder Action
fetchDecoder =
    Decode.map6 Action
        (Decode.field "_id" Decode.string)
        (Decode.field "updated_at" Decode.string)
        (Decode.at [ "data", "method" ] Decode.string)
        (Decode.at [ "data", "url" ] Decode.string)
        (Decode.at [ "data", "auth" ] (Decode.maybe Decode.string))
        (Decode.at [ "data", "body_template" ] bodyTemplateDecoder)


bodyTemplateDecoder : Decode.Decoder BodyTemplate
bodyTemplateDecoder =
    Decode.map2 BodyTemplate
        (Decode.field "body" Decode.string)
        (Decode.field "variables" (Decode.list Decode.string))



-- Update


update : Msg Action -> Resource Action -> ( Resource Action, Cmd (Msg Action) )
update msg resource =
    Resource.Update.update dummyAction config msg resource
