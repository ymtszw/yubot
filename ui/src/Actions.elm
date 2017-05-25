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
import Utils
import Repo exposing (Repo)
import Repo.Command exposing (Config)
import Repo.Messages exposing (Msg)
import Repo.Update
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
    { label : Maybe Label
    , method : Method
    , url : Utils.Url
    , auth : Maybe Repo.EntityId
    , bodyTemplate : StringTemplate
    , type_ : Type
    }


dummyAction : Action
dummyAction =
    Action Nothing "post" "https://example.com" Nothing (StringTemplate "{}" []) Http



-- Config


config : Config Action
config =
    Config "/api/action" dataDecoder


dataDecoder : Decode.Decoder Action
dataDecoder =
    Decode.map6 Action
        (Decode.field "label" (Decode.maybe Decode.string))
        (Decode.field "method" Decode.string)
        (Decode.field "url" Decode.string)
        (Decode.field "auth" (Decode.maybe Decode.string))
        (Decode.field "body_template" bodyTemplateDecoder)
        (Decode.field "type" (typeDecoder))


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


update : Msg Action -> Repo Action -> ( Repo Action, Cmd (Msg Action) )
update msg resource =
    Repo.Update.update dummyAction config msg resource
