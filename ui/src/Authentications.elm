module Authentications exposing (Authentication, AuthType(..), dummyAuthentication, config, update, listForPoll)

import Json.Decode as Decode
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


hipchatToken : String -> Authentication
hipchatToken token =
    Authentication
        ("Notification Token: " ++ (String.left 5 token) ++ "***")
        Hipchat
        token



-- Config


config : Config Authentication
config =
    Config "/api/authentication" dataDecoder


dataDecoder : Decode.Decoder Authentication
dataDecoder =
    Decode.map3 Authentication
        (Decode.field "name" Decode.string)
        (Decode.field "type" typeDecoder)
        (Decode.field "token" Decode.string)


typeDecoder : Decode.Decoder AuthType
typeDecoder =
    let
        stringToType string =
            case string of
                "hipchat" ->
                    Hipchat

                "bearer" ->
                    Bearer

                _ ->
                    Raw
    in
        Decode.map stringToType Decode.string



-- Update


update : Msg Authentication -> Repo Authentication -> ( Repo Authentication, Cmd (Msg Authentication) )
update msg resource =
    Repo.Update.update dummyAuthentication config msg resource
