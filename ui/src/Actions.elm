module Actions
    exposing
        ( Action
        , Method
        , Type(..)
        , dummyAction
        , config
        , update
        )

import Json.Decode as Decode
import Utils exposing (EntityId, Timestamp, Url)
import Resource exposing (Resource)
import Resource.Command exposing (Config)
import Resource.Messages exposing (Msg)
import Resource.Update
import StringTemplate exposing (StringTemplate)


-- Model


type alias Label =
    String


type alias Method =
    String


type Type
    = Hipchat
    | Http


type alias Action =
    { id : EntityId
    , updatedAt : Timestamp
    , label : Maybe Label
    , method : Method
    , url : Url
    , auth : Maybe EntityId
    , bodyTemplate : StringTemplate
    , type_ : Type
    }


dummyAction : Action
dummyAction =
    Action "" "2015-01-01T00:00:00Z" Nothing "post" "https://example.com" Nothing (StringTemplate "{}" []) Http



-- Config


config : Config Action
config =
    Config "/api/action" fetchDecoder


fetchDecoder : Decode.Decoder Action
fetchDecoder =
    Decode.map8 Action
        (Decode.field "_id" Decode.string)
        (Decode.field "updated_at" Decode.string)
        (Decode.at [ "data", "label" ] (Decode.maybe Decode.string))
        (Decode.at [ "data", "method" ] Decode.string)
        (Decode.at [ "data", "url" ] Decode.string)
        (Decode.at [ "data", "auth" ] (Decode.maybe Decode.string))
        (Decode.at [ "data", "body_template" ] bodyTemplateDecoder)
        (Decode.at [ "data", "type" ] (typeDecoder))


bodyTemplateDecoder : Decode.Decoder StringTemplate
bodyTemplateDecoder =
    Decode.map2 StringTemplate
        (Decode.field "body" Decode.string)
        (Decode.field "variables" (Decode.list Decode.string))


typeDecoder : Decode.Decoder Type
typeDecoder =
    let
        stringToType string =
            case string of
                "hipchat" ->
                    Hipchat

                _ ->
                    -- "http"
                    Http
    in
        Decode.map stringToType Decode.string



-- Update


update : Msg Action -> Resource Action -> ( Resource Action, Cmd (Msg Action) )
update msg resource =
    Resource.Update.update dummyAction config msg resource
