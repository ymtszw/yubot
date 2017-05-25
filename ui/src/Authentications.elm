module Authentications exposing (Authentication, dummyAuthentication, config, update, listForPoll)

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


type alias AuthType =
    String


type alias DecodedToken =
    String


dummyAuthentication : Authentication
dummyAuthentication =
    Authentication "" "" ""


listForPoll : List (Repo.Entity Authentication) -> List (Repo.Entity Authentication)
listForPoll authList =
    let
        filterFun auth =
            List.member auth.data.type_ [ "raw", "bearer" ]
    in
        List.filter filterFun authList



-- Config


config : Config Authentication
config =
    Config "/api/authentication" dataDecoder


dataDecoder : Decode.Decoder Authentication
dataDecoder =
    Decode.map3 Authentication
        (Decode.field "name" Decode.string)
        (Decode.field "type" Decode.string)
        (Decode.field "token" Decode.string)



-- Update


update : Msg Authentication -> Repo Authentication -> ( Repo Authentication, Cmd (Msg Authentication) )
update msg resource =
    Repo.Update.update dummyAuthentication config msg resource
