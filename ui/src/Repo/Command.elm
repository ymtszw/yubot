module Repo.Command exposing (Config, create, update, navigateAndFetchOne, justFetchOne, fetchAll, delete)

import Http
import HttpBuilder
import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))
import Json.Encode as JE
import Utils
import Repo
import Repo.Messages exposing (Msg(..))


type alias Config t =
    { repoPath : String
    , indexPath : Utils.Url
    , dataDecoder : JD.Decoder t
    , dataEncoder : t -> JE.Value
    , navigateOnWrite : Repo.Entity t -> Utils.Url
    }


create : Config t -> Repo.EntityId -> t -> Cmd (Msg t)
create config dirtyId newData =
    HttpBuilder.post config.repoPath
        |> HttpBuilder.withJsonBody (config.dataEncoder newData)
        |> HttpBuilder.withExpect (Http.expectJson (entityDecoder config.dataDecoder))
        |> HttpBuilder.send (OnCreate dirtyId)


update : Config t -> Repo.EntityId -> t -> Cmd (Msg t)
update config dirtyId newData =
    -- TODO: take difference from original entity and compose partial update body
    HttpBuilder.put (config.repoPath ++ "/" ++ dirtyId)
        |> HttpBuilder.withJsonBody (config.dataEncoder newData)
        |> HttpBuilder.withExpect (Http.expectJson (entityDecoder config.dataDecoder))
        |> HttpBuilder.send OnUpdate


navigateAndFetchOne : Config t -> Repo.EntityId -> Cmd (Msg t)
navigateAndFetchOne =
    fetchOne OnNavigateAndFetchOne


justFetchOne : Config t -> Repo.EntityId -> Cmd (Msg t)
justFetchOne =
    fetchOne OnFetchOne


fetchOne : (Result Http.Error (Repo.Entity t) -> Msg t) -> Config t -> Repo.EntityId -> Cmd (Msg t)
fetchOne onFetchOneMsg config id =
    HttpBuilder.get (config.repoPath ++ "/" ++ id)
        |> HttpBuilder.withExpect (Http.expectJson (entityDecoder config.dataDecoder))
        |> HttpBuilder.send onFetchOneMsg


fetchAll : Config t -> Cmd (Msg t)
fetchAll config =
    HttpBuilder.get config.repoPath
        |> HttpBuilder.withExpect (Http.expectJson (JD.list (entityDecoder config.dataDecoder)))
        |> HttpBuilder.send OnFetchAll


entityDecoder : JD.Decoder t -> JD.Decoder (Repo.Entity t)
entityDecoder dataDecoder =
    JD.succeed Repo.Entity
        |: JD.field "_id" JD.string
        |: JD.field "updated_at" JD.string
        |: JD.field "data" dataDecoder


delete : Config t -> Repo.EntityId -> Cmd (Msg t)
delete config id =
    HttpBuilder.delete (config.repoPath ++ "/" ++ id)
        |> HttpBuilder.send OnDelete
