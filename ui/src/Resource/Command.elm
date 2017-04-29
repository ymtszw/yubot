module Resource.Command exposing (Config, fetchAll, delete)

import Http
import HttpBuilder exposing (withExpect, send)
import Json.Decode as Decode exposing (field, at)
import Utils exposing (EntityId)
import Resource.Messages exposing (Msg(OnFetchAll, OnDelete))


type alias Config resource =
    { resourcePath : String
    , fetchDecoder : Decode.Decoder resource
    }


fetchAll : Config resource -> Cmd (Msg resource)
fetchAll config =
    HttpBuilder.get config.resourcePath
        |> withExpect (Http.expectJson (Decode.list config.fetchDecoder))
        |> send OnFetchAll


delete : Config resource -> EntityId -> Cmd (Msg resource)
delete config id =
    HttpBuilder.delete (config.resourcePath ++ "/" ++ id)
        |> send OnDelete
