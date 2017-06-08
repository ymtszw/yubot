use Croma

defmodule Mix.Tasks.Yubot.UploadAssets do
  @moduledoc """
  Upload assets to CDN (via Dodai Filestore API and S3).

  Uploaded assets are recorded to inventory file ("web/static/assets"),
  which will be used as compile-time resource for `Yubot.Assets` module.

  # Usage

      mix yubot.upload_assets (dev|prod)
  """
  use Mix.Task
  alias Yubot.Assets

  @shortdoc "Upload assets to CDN (via Dodai Filestore API and S3)"

  @assets_directory Path.join(["priv", "static", "assets"])
  @assets_inventory Path.join(["web", "static", "assets"])

  def run([env]), do: run_impl(env)
  def run(_), do: run_impl("dev")

  defp run_impl(env) do
    System.put_env("PORT", "12121")
    Application.ensure_all_started(:solomon)
    upload_and_build_inventory(env)
  end

  defp upload_and_build_inventory(env) do
    config_file = if env == "prod", do: raise("not ready!"), else: "gear_config"
    root_key = File.read!(config_file) |> Poison.decode!() |> Map.get("dodai_root_key")
    assets_to_serve()
    |> Enum.map(&request_upload_url(&1, root_key, env))
    |> Enum.map(&upload_and_notify(&1, root_key, env))
    |> write_inventory()
  end

  defp assets_to_serve() do
    Path.join(@assets_directory, "**")
    |> Path.wildcard()
    |> Enum.map(fn file_abs_path ->
      case File.stat!(file_abs_path) do
        %File.Stat{type: :regular, size: file_size} -> {file_abs_path, Path.relative_to(file_abs_path, @assets_directory), file_size}
        _otherwise -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp request_upload_url({asset_abs_path, asset_rel_path, file_size}, root_key, env) do
    %_success{body: %{"uploadUrl" => upload_url}} = Assets.upsert(asset_rel_path, file_size, root_key, env)
    {asset_abs_path, asset_rel_path, upload_url}
  end

  defp upload_and_notify({asset_abs_path, asset_rel_path, upload_url}, root_key, env) do
    %_success{body: %{"publicUrl" => "http://" <> noscheme_url}} = Assets.upload_and_notify(asset_abs_path, asset_rel_path, upload_url, root_key, env)
    https_url = "https://#{noscheme_url}"
    IO.puts(IO.ANSI.green() <> "#{asset_rel_path} => #{https_url}" <> IO.ANSI.reset())
    "#{asset_rel_path} #{https_url}\n"
  end

  defp write_inventory(lines) do
    File.write!(@assets_inventory, Enum.join(lines))
  end
end
