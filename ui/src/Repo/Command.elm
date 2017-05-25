module Repo.Command exposing (Config, fetchAll, delete)

import Http
import HttpBuilder
import Json.Decode as Decode
import Repo
import Repo.Messages exposing (Msg(..))


type alias Config t =
    { repoPath : String
    , dataDecoder : Decode.Decoder t
    }


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
