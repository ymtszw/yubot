module Actions
    exposing
        ( Action
        , Method
        , ActionType(..)
        , dummyAction
        , usedAuthIds
        , stringToType
        , config
        , update
        )

import Dict
import Set exposing (Set)
import Json.Decode as Decode
import Json.Encode as Encode
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


type ActionType
    = Hipchat
    | Http


type alias Action =
    { label : Maybe Label
    , method : Method
    , url : Utils.Url
    , auth : Maybe Repo.EntityId
    , bodyTemplate : StringTemplate
    , type_ : ActionType
    }


dummyAction : Action
dummyAction =
    Action Nothing "post" "https://example.com" Nothing (StringTemplate "{}" []) Http


usedAuthIds : Repo.EntityDict Action -> Set Repo.EntityId
usedAuthIds actions =
    actions
        |> Dict.values
        |> List.map (.data >> .auth >> Maybe.withDefault "")
        |> Set.fromList


stringToType : String -> ActionType
stringToType string =
    case string of
        "hipchat" ->
            Hipchat

        _ ->
            -- "http"
            Http



-- Config


config : Config Action
config =
    Config "/api/action" dataDecoder dataEncoder (always "/actions")


dataDecoder : Decode.Decoder Action
dataDecoder =
    Decode.map6 Action
        (Decode.field "label" (Decode.maybe Decode.string))
        (Decode.field "method" Decode.string)
        (Decode.field "url" Decode.string)
        (Decode.field "auth" (Decode.maybe Decode.string))
        (Decode.field "body_template" bodyTemplateDecoder)
        (Decode.field "type" (Decode.map stringToType Decode.string))


bodyTemplateDecoder : Decode.Decoder StringTemplate
bodyTemplateDecoder =
    Decode.map2 StringTemplate
        (Decode.field "body" Decode.string)
        (Decode.field "variables" (Decode.list Decode.string))


dataEncoder : Action -> Encode.Value
dataEncoder { label, method, url, auth, bodyTemplate, type_ } =
    Encode.object
        [ ( "label", Utils.encodeMaybe Encode.string label )
        , ( "method", Encode.string method )
        , ( "url", Encode.string url )
        , ( "auth", Utils.encodeMaybe Encode.string auth )
        , ( "body_template", bodyTemplateEncoder bodyTemplate )
        , ( "type", type_ |> toString |> String.toLower |> Encode.string )
        ]


bodyTemplateEncoder : StringTemplate -> Encode.Value
bodyTemplateEncoder { body, variables } =
    Encode.object
        [ ( "body", Encode.string body )
        , ( "variables", variables |> List.map Encode.string |> Encode.list )
        ]



-- Update


update : Msg Action -> Repo Action -> ( Repo Action, Cmd (Msg Action) )
update msg resource =
    Repo.Update.update dummyAction config msg resource
