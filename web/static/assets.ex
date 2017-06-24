use Croma

defmodule Yubot.Assets do
  @moduledoc """
  Resolver for static assets URL.

  In this gear, there are two places where static assets can be placed.

  - Under "priv/static/assets/"
  - Under "priv/static/" other than "assets" directory

  "priv/static/assets" directory is gitignored, and only used from local server.
  Assets under "priv/static/assets" directory can be uploaded to CDN using `Mix.Tasks.Yubot.UploadAssets` task.

  Asset paths relative from "priv/static/assets" directory can be resolved to corresponding CDN URL using `url/1`.
  This function embeds CDN URL (or "/static/assets/*" path, when local) to templates.

  Other files and directories under "priv/static" are served from both local/cloud server, and included in git.
  """

  defmodule AssetPath do
    @moduledoc """
    Path pattern with very limited character class.

    Only word-composing characters (`a-zA-Z0-9_`), `.` and `/` are allowed.
    """
    use Croma.SubtypeOfString, pattern: ~r{\A[a-zA-Z0-9/_.]+\Z}

    @doc """
    Converts slashes into hyphens to be used as file entity _id.
    """
    defun to_file_entity_id(asset_path :: v[t], commit_hash :: v[String.t]) :: String.t do
      String.replace(asset_path, "/", "-") <> "-" <> commit_hash
    end
  end

  alias SolomonLib.Httpc

  @collection_name  "Assets"
  @external_resource Path.expand("assets", __DIR__)

  @assets_file @external_resource |> File.read!() |> String.split("\n", trim: true)
  @commit_hash hd(@assets_file)
  @inventory   @assets_file |> tl() |> Map.new(&List.to_tuple(String.split(&1, " ")))
  def inventory(), do: @inventory

  #
  # APIs for template precompiler (compile-time APIs)
  #

  @doc """
  Resolve `asset_path` at runtime.
  """
  defun url(asset_path :: v[AssetPath.t]) :: SolomonLib.Url.t do
    case SolomonLib.Env.runtime_env() do
      :prod -> raise("not ready!")
      :dev -> cdn_url(asset_path)
      _local -> local_path(asset_path)
    end
  end

  defp local_path(asset_path) do
    "/static/assets/#{asset_path}"
  end

  for {asset_path, public_url} <- @inventory do
    defp cdn_url(unquote(asset_path)), do: unquote(public_url)
  end

  def bootstrap4(), do: url("bootstrap.min.css")

  #
  # APIs for upload task (runtime APIs)
  #

  def retrieve_list(root_key, env) do
    req = Dodai.RetrieveDedicatedFileEntityListRequest.new(Yubot.Dodai.group_id(env), @collection_name, root_key)
    case Dodai.Client.send(dodai_client(env), req) do
      %Dodai.RetrieveDedicatedFileEntityListSuccess{} = res -> Dodai.Model.FileEntityList.from_response(res)
      error -> error
    end
  end

  @doc """
  Revoke currently active assets by deleting all file entities of target commit hash.

  Uploaded files in S3 will be cleaned automatically.
  """
  def revoke_current(root_key, env) do
    Enum.each(@inventory, fn {asset_path, _} -> revoke(asset_path, @commit_hash, root_key, env) end)
  end

  def revoke(id, root_key, env) do
    query = %Dodai.DeleteDedicatedFileEntityRequestQuery{allVersions: true}
    req = Dodai.DeleteDedicatedFileEntityRequest.new(Yubot.Dodai.group_id(env), @collection_name, id, root_key, query)
    Dodai.Client.send(dodai_client(env), req)
  end

  def revoke(asset_path, commit_hash, root_key, env) do
    revoke(AssetPath.to_file_entity_id(asset_path, commit_hash), root_key, env)
  end

  @doc """
  Create or Update dedicated file entity for new upload URL.
  """
  def upsert(asset_path, file_size, root_key, env, commit_hash) do
    group_id = Yubot.Dodai.group_id(env)
    client = dodai_client(env)
    base_body = upsert_body(asset_path, file_size, commit_hash)
    body0 = Dodai.CreateDedicatedFileEntityRequestBody.new!(base_body)
    req0 = Dodai.CreateDedicatedFileEntityRequest.new(group_id, @collection_name, root_key, body0)
    case Dodai.Client.send(client, req0) do
      %Dodai.DuplicatedKeyError{} ->
        body1 = Dodai.UpdateDedicatedFileEntityRequestBody.new!(base_body)
        req1 = Dodai.UpdateDedicatedFileEntityRequest.new(group_id, @collection_name, base_body[:_id], root_key, body1)
        Dodai.Client.send(client, req1)
      otherwise -> otherwise
    end
  end

  defp upsert_body(asset_path, file_size, commit_hash) do
    %{
      _id: AssetPath.to_file_entity_id(asset_path, commit_hash),
      filename: Path.basename(asset_path),
      contentType: :mimerl.filename(asset_path),
      public: true,
      size: file_size,
    }
  end

  @doc """
  Upload asset file to S3 and notify finish.

  Now that `commit_hash` is attached to files, it creates basically-non-expiring (immutable) cache on CloudFront.
  """
  def upload_and_notify(asset_full_path, asset_path, upload_url, root_key, env, commit_hash) do
    case upload(asset_full_path, asset_path, upload_url) do
      {:ok, %Httpc.Response{status: 200}} -> notify_finish(asset_path, root_key, env, commit_hash)
      otherwise -> otherwise
    end
  end

  defp upload(asset_full_path, _asset_path, upload_url) do
    headers = %{
      "content-type" => :mimerl.filename(asset_full_path),
      "cache-control" => "public, max-age=300000000, immutable",
    }
    Httpc.put(upload_url, File.read!(asset_full_path), headers, recv_timeout: 60_000)
  end

  defp notify_finish(asset_path, root_key, env, commit_hash) do
    id = AssetPath.to_file_entity_id(asset_path, commit_hash)
    req = Dodai.NotifyDedicatedFileUploadFinishedRequest.new(Yubot.Dodai.group_id(env), @collection_name, id, root_key)
    Dodai.Client.send(dodai_client(env), req)
  end

  defp dodai_client("prod"), do: raise("not ready!")
  defp dodai_client(_dev_or_local), do: Dodai.Client.new(:dev, Yubot.Dodai.app_id("dev"))
end
