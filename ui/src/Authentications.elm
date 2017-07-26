module Authentications
    exposing
        ( Authentication
        , AuthType(..)
        , isValid
        , dummyAuthentication
        , stringToType
        , hipchatToken
        , typeToFa
        , config
        , update
        , listForHttp
        , listForHipchat
        )

import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))
import Json.Encode as JE
import Utils
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


isValid : ( Repo.Entity Authentication, Repo.Audit ) -> Bool
isValid ( { data }, audit ) =
    Repo.isValid audit && data.name /= "" && data.token /= ""


dummyAuthentication : Authentication
dummyAuthentication =
    Authentication "" Raw ""


listForHttp : Repo.EntityDict Authentication -> List (Repo.Entity Authentication)
listForHttp =
    filterDict (\a -> List.member a.data.type_ [ Raw, Bearer ])


listForHipchat : Repo.EntityDict Authentication -> List (Repo.Entity Authentication)
listForHipchat =
    filterDict (\a -> a.data.type_ == Hipchat)


filterDict : (Repo.Entity Authentication -> Bool) -> Repo.EntityDict Authentication -> List (Repo.Entity Authentication)
filterDict filterFun authDict =
    authDict |> Repo.dictToList |> List.filter filterFun


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


typeToFa : AuthType -> String
typeToFa type_ =
    case type_ of
        Hipchat ->
            "fa-weixin"

        _ ->
            "fa-key"



-- Config


config : Config Authentication
config =
    Config "/api/authentication" "/credentials" dataDecoder dataEncoder (always "/credentials")


dataDecoder : JD.Decoder Authentication
dataDecoder =
    JD.succeed Authentication
        |: JD.field "name" JD.string
        |: JD.field "type" (JD.map stringToType JD.string)
        |: JD.field "token" JD.string


dataEncoder : Authentication -> JE.Value
dataEncoder { name, type_, token } =
    JE.object
        [ ( "name", JE.string name )
        , ( "type", JE.string (Utils.toLowerString type_) )
        , ( "token", JE.string token )
        ]



-- Update


update : Msg Authentication -> Repo {} Authentication -> ( Repo {} Authentication, Cmd (Msg Authentication), Repo.Update.StackCmd )
update =
    Repo.Update.update dummyAuthentication config
