module Authentications exposing (Authentication, AuthType(..), dummyAuthentication, stringToType, hipchatToken, config, update, listForPoll)

import Json.Decode as Decode
import Json.Encode as Encode
import Repo exposing (Repo)
import Repo.Update
import Repo.Messages exposing (Msg(..))
import Repo.Command exposing (Config)


-- Model


type alias Authentication =
    { name : String
    , type_ : AuthType
    , token : DecodedToken
    }


type AuthType
    = Raw
    | Bearer
    | Hipchat


type alias DecodedToken =
    String


dummyAuthentication : Authentication
dummyAuthentication =
    Authentication "" Raw ""


listForPoll : List (Repo.Entity Authentication) -> List (Repo.Entity Authentication)
listForPoll authList =
    let
        filterFun auth =
            List.member auth.data.type_ [ Raw, Bearer ]
    in
        List.filter filterFun authList


stringToType : String -> AuthType
stringToType string =
    case string of
        "hipchat" ->
            Hipchat

        "bearer" ->
            Bearer

        _ ->
            Raw


hipchatToken : String -> Authentication
hipchatToken token =
    Authentication
        ("Token: " ++ (String.left 5 token) ++ "***")
        Hipchat
        token



-- Config


config : Config Authentication
config =
    Config "/api/authentication" dataDecoder dataEncoder (always "/credentials")


dataDecoder : Decode.Decoder Authentication
dataDecoder =
    Decode.map3 Authentication
        (Decode.field "name" Decode.string)
        (Decode.field "type" (Decode.map stringToType Decode.string))
        (Decode.field "token" Decode.string)


dataEncoder : Authentication -> Encode.Value
dataEncoder { name, type_, token } =
    Encode.object
        [ ( "name", Encode.string name )
        , ( "type", type_ |> toString |> String.toLower |> Encode.string )
        , ( "token", Encode.string token )
        ]



-- Update


update : Msg Authentication -> Repo Authentication -> ( Repo Authentication, Cmd (Msg Authentication), Bool )
update msg resource =
    Repo.Update.update dummyAuthentication config msg resource
