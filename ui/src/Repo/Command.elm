module Repo.Command exposing (Config, submitNew, fetchAll, delete)

import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Encode as Encode
import Utils
import Repo
import Repo.Messages exposing (Msg(..))


type alias Config t =
    { repoPath : String
    , dataDecoder : Decode.Decoder t
    , dataEncoder : t -> Encode.Value
    , navigateOnWrite : Repo.Entity t -> Utils.Url
    }


submitNew : Config t -> t -> Cmd (Msg t)
submitNew config newData =
    HttpBuilder.post config.repoPath
        |> HttpBuilder.withJsonBody (config.dataEncoder newData)
        |> HttpBuilder.withExpect (Http.expectJson (entityDecoder config.dataDecoder))
        |> HttpBuilder.send OnCreate


fetchAll : Config t -> Cmd (Msg t)
fetchAll config =
    HttpBuilder.get config.repoPath
        |> HttpBuilder.withExpect (Http.expectJson (Decode.list (entityDecoder config.dataDecoder)))
        |> HttpBuilder.send OnFetchAll


entityDecoder : Decode.Decoder t -> Decode.Decoder (Repo.Entity t)
entityDecoder dataDecoder =
    Decode.map3 Repo.Entity
        (Decode.field "_id" Decode.string)
        (Decode.field "updated_at" Decode.string)
        (Decode.field "data" dataDecoder)


delete : Config t -> Repo.EntityId -> Cmd (Msg t)
delete config id =
    HttpBuilder.delete (config.repoPath ++ "/" ++ id)
        |> HttpBuilder.send OnDelete
