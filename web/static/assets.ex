use Croma

defmodule Yubot.Assets do
  @moduledoc """
  Resolver for static assets URL.

  Static assets are served from CloudFront (via Dodai filestore API),
  though in local development they are served from priv/static/assets directory.
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
    defun to_file_entity_id(asset_path :: v[t]) :: String.t do
      String.replace(asset_path, "/", "-")
    end
  end

  alias SolomonLib.Httpc

  @collection_name  "Assets"
  @external_resource Path.expand("assets", __DIR__)

  @inventory         File.read!(@external_resource) |> String.split("\n") |> Enum.map(&List.to_tuple(String.split(&1, " ")))
  def inventory(), do: @inventory

  #
  # APIs for template precompiler (compile-time APIs)
  #

  @doc """
  Embed resolved `asset_path` at compile time.

  `asset_path` must be compile-time string literal.
  """
  defmacro url(asset_path) do
    asset_url = Yubot.Assets.url_impl(asset_path)
    quote do
      unquote(asset_url)
    end
  end

  @doc false
  def url_impl(asset_path) when is_binary(asset_path) do
    case SolomonLib.Env.runtime_env() do
      :prod -> raise("not ready!")
      :dev -> cdn_path(asset_path)
      _local -> local_path(asset_path)
    end
  end

  def local_path(asset_path) do
    "/static/assets/#{asset_path}"
  end

  for {asset_path, public_url} <- @inventory do
    def cdn_path(unquote(asset_path)), do: unquote(public_url)
  end

  #
  # APIs for upload task (runtime APIs)
  #

  @doc """
  Create or Update dedicated file entity for new upload URL.
  """
  def upsert(asset_path, file_size, root_key, env) do
    group_id = Yubot.Dodai.group_id(env)
    client = dodai_client(env)
    base_body = upsert_body(asset_path, file_size)
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

  defp upsert_body(asset_path, file_size) do
    id = AssetPath.to_file_entity_id(asset_path)
    %{
      _id: id,
      filename: asset_path,
      contentType: :mimerl.filename(asset_path),
      public: true,
      size: file_size,
    }
  end

  @doc """
  Upload asset file to S3 and notify finish.
  """
  def upload_and_notify(asset_full_path, asset_path, upload_url, root_key, env) do
    case upload(asset_full_path, asset_path, upload_url) do
      {:ok, %Httpc.Response{status: 200}} -> notify_finish(asset_path, root_key, env)
      otherwise -> otherwise
    end
  end

  defp upload(asset_full_path, asset_path, upload_url) do
    headers = %{
      "content-type" => :mimerl.filename(asset_full_path),
      "content-disposition" => "attachment; filename=#{asset_path}",
      "cache-control" => "max-age=0",
    }
    body = case headers["content-type"] do
      "image/" <> _ -> File.read!(asset_full_path)
      _text_or_app  -> File.read!(asset_full_path)
    end
    Httpc.put(upload_url, body, headers, recv_timeout: 60_000)
  end

  defp notify_finish(asset_path, root_key, env) do
    req = Dodai.NotifyDedicatedFileUploadFinishedRequest.new(Yubot.Dodai.group_id(env), @collection_name, AssetPath.to_file_entity_id(asset_path), root_key)
    Dodai.Client.send(dodai_client(env), req)
  end

  defp dodai_client("prod"), do: raise("not ready!")
  defp dodai_client(_dev_or_local), do: Dodai.Client.new(:dev, Yubot.Dodai.app_id("dev"))
end
