use Croma

defmodule Yubot.Assets do
  @moduledoc """
  Resolver for static assets URL.

  In this gear, there are two places where static assets can be placed.

  - Under "priv/static/assets/"
  - Under "priv/static/" other than "assets" directory

  "priv/static/assets" directory is gitignored, and only used from local server.
  Assets under "priv/static/assets" directory can be uploaded to CDN using `Mix.Tasks.Yubot.Assets` task.

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

  @collection_name "Assets"

  @external_resource Path.expand("assets", __DIR__)
  @remote_inventory_filename "inventory"

  @assets_file @external_resource |> File.read!() |> String.split("\n", trim: true)
  @commit_hash hd(@assets_file)
  @inventory @assets_file |> tl() |> Map.new(&List.to_tuple(String.split(&1, " ")))
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

  def retrieve_list(query \\ %{}, root_key, env) do
    q = struct(Dodai.RetrieveDedicatedFileEntityListRequestQuery, query)
    req = Dodai.RetrieveDedicatedFileEntityListRequest.new(Yubot.Dodai.group_id(env), @collection_name, root_key, q)
    case Dodai.Client.send(dodai_client(env), req) do
      %Dodai.RetrieveDedicatedFileEntityListSuccess{} = res -> Dodai.Model.FileEntityList.from_response(res)
      error -> error
    end
  end

  @doc """
  Revoke two generations (or more) older assets by deleting file entities of target commit hash.

  Uploaded files in S3 will be cleaned automatically.
  """
  def revoke_outdated(root_key, env) do
    current_asset_ids = Enum.map(@inventory, &AssetPath.to_file_entity_id(elem(&1, 0), @commit_hash))
    %{query: %{_id: %{"$nin" => [@remote_inventory_filename | current_asset_ids]}}}
    |> retrieve_list(root_key, env)
    |> Enum.each(&revoke(&1._id, root_key, env))
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
    asset_path
    |> upsert_body(file_size, commit_hash)
    |> upsert(root_key, env)
  end
  def upsert(upsert_body, root_key, env) when is_map(upsert_body) do
    group_id = Yubot.Dodai.group_id(env)
    client = dodai_client(env)
    body0 = Dodai.CreateDedicatedFileEntityRequestBody.new!(upsert_body)
    req0 = Dodai.CreateDedicatedFileEntityRequest.new(group_id, @collection_name, root_key, body0)
    case Dodai.Client.send(client, req0) do
      %Dodai.DuplicatedKeyError{} ->
        body1 = Dodai.UpdateDedicatedFileEntityRequestBody.new!(upsert_body)
        req1 = Dodai.UpdateDedicatedFileEntityRequest.new(group_id, @collection_name, upsert_body[:_id], root_key, body1)
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
  Create or Update dedicated file entity for asset inventory file entity with semi-permanent publicUrl.
  """
  def upsert_inventory(inventory_contents, root_key, env) do
    %{
      _id: @remote_inventory_filename,
      filename: @remote_inventory_filename,
      contentType: "text/plain",
      public: true,
      size: byte_size(inventory_contents),
    }
    |> upsert(root_key, env)
  end

  @doc """
  Upload asset file to S3 and notify finish.

  Perpetual assets (ones that revoked on deploy) creates basically-non-expiring (immutable) cache on CloudFront.
  """
  def upload_and_notify(asset_full_path, id, upload_url, root_key, env) do
    asset_full_path
    |> File.read!()
    |> upload_and_notify(:mimerl.filename(asset_full_path), "public, max-age=300000000, immutable", id, upload_url, root_key, env)
  end
  def upload_and_notify(body, content_type, cache_control \\ "max-age=0", id, upload_url, root_key, env) do
    case upload(body, content_type, upload_url, cache_control) do
      {:ok, %Httpc.Response{status: 200}} -> notify_finish(id, root_key, env)
      otherwise -> otherwise
    end
  end

  defp upload(body, content_type, upload_url, cache_control) do
    headers = %{
      "content-type" => content_type,
      "cache-control" => cache_control,
    }
    Httpc.put(upload_url, body, headers, recv_timeout: 60_000)
  end

  defp notify_finish(id, root_key, env) do
    req = Dodai.NotifyDedicatedFileUploadFinishedRequest.new(Yubot.Dodai.group_id(env), @collection_name, id, root_key)
    Dodai.Client.send(dodai_client(env), req)
  end

  defp dodai_client("prod"), do: raise("not ready!")
  defp dodai_client(_dev_or_local), do: Dodai.Client.new(:dev, Yubot.Dodai.app_id("dev"))
end
