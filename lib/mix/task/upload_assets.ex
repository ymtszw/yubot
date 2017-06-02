use Croma

defmodule Mix.Tasks.Yubot.UploadAssets do
  use Mix.Task
  alias Yubot.Assets

  @shortdoc "Upload assets to S3 (Dodai Filestore), allowing CDN serve"

  @assets_directory Path.join(["priv", "static", "assets"])
  @assets_inventory Path.join(["web", "static", "assets"])

  def run([env]) do
    System.put_env("PORT", "12121")
    Application.ensure_all_started(:solomon)
    upload_and_build_inventory(env)
  end

  def upload_and_build_inventory(env) do
    config_file = if env == "prod", do: raise("not ready!"), else: "gear_config"
    root_key = File.read!(config_file) |> Poison.decode!() |> Map.get("dodai_root_key")
    assets_to_serve()
    |> filter_directories()
    |> Enum.map(&request_upload_url(&1, root_key, env))
    |> Enum.map(&upload_and_notify(&1, root_key, env))
    |> write_inventory()
  end

  defp assets_to_serve() do
    Path.wildcard(Path.join(@assets_directory, "**"))
  end

  defp filter_directories(asset_full_paths) do
    asset_full_paths
    |> Enum.map(fn asset_full_path ->
      case File.stat!(asset_full_path) do
        %File.Stat{type: :regular, size: file_size} -> {asset_full_path, Path.relative_to(asset_full_path, @assets_directory), file_size}
        _otherwise -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp request_upload_url({asset_full_path, asset_path, file_size}, root_key, env) do
    %_success{body: %{"uploadUrl" => upload_url}} = Assets.upsert(asset_path, file_size, root_key, env)
    {asset_full_path, asset_path, upload_url}
  end

  defp upload_and_notify({asset_full_path, asset_path, upload_url}, root_key, env) do
    %_success{body: %{"publicUrl" => "http://" <> noscheme_url}} = Assets.upload_and_notify(asset_full_path, asset_path, upload_url, root_key, env)
    https_url = "https://#{noscheme_url}"
    IO.puts(IO.ANSI.green() <> "#{asset_path} => #{https_url}" <> IO.ANSI.reset())
    "#{asset_path} #{https_url}"
  end

  defp write_inventory(lines) do
    inventory = Enum.join(lines, "\n")
    File.write!(@assets_inventory, inventory)
  end
end
