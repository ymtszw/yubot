module Authentications exposing (Authentication, dummyAuthentication, config, update, listForPoll)

import Json.Decode as Decode
import Utils exposing (EntityId, Timestamp)
import Resource exposing (Resource)
import Resource.Update
import Resource.Messages exposing (Msg(..))
import Resource.Command exposing (Config)


-- Model


type alias Authentication =
    { id : EntityId
    , updatedAt : Timestamp
    , name : String
    , type_ : AuthType
    , token : DecodedToken
    }


type alias AuthType =
    String


type alias DecodedToken =
    String


dummyAuthentication : Authentication
dummyAuthentication =
    Authentication "" "2015-01-01T00:00:00Z" "" "" ""


listForPoll : List Authentication -> List Authentication
listForPoll authList =
    let
        filterFun auth =
            List.member auth.type_ [ "raw", "bearer" ]
    in
        List.filter filterFun authList



-- Config


config : Config Authentication
config =
    Config "/api/authentication" fetchDecoder


fetchDecoder : Decode.Decoder Authentication
fetchDecoder =
    Decode.map5 Authentication
        (Decode.field "_id" Decode.string)
        (Decode.field "updated_at" Decode.string)
        (Decode.at [ "data", "name" ] Decode.string)
        (Decode.at [ "data", "type" ] Decode.string)
        (Decode.at [ "data", "token" ] Decode.string)



-- Update


update : Msg Authentication -> Resource Authentication -> ( Resource Authentication, Cmd (Msg Authentication) )
update msg resource =
    Resource.Update.update dummyAuthentication config msg resource
