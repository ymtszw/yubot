use Croma

defmodule Mix.Tasks.Yubot.Assets.Upload do
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
  @assets_module    Path.join(["web", "static", "assets.ex"])
  @external_cdn_assets %{
    "bootstrap.min.css" => "https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-alpha.6/css/bootstrap.min.css",
  }

  def run([env]), do: run_impl(env)
  def run(_), do: run_impl("dev")

  defp run_impl(env) do
    System.put_env("PORT", "12121")
    Application.ensure_all_started(:solomon)
    config_file = if env == "prod", do: raise("not ready!"), else: "gear_config"
    root_key = File.read!(config_file) |> Poison.decode!() |> Map.get("dodai_root_key")
    Assets.revoke_current(root_key, env)
    upload_and_build_inventory(root_key, env)
  end

  defp upload_and_build_inventory(root_key, env) do
    {commit_hash0, 0} = System.cmd("git", ["rev-parse", "--short", "HEAD"])
    commit_hash1 = String.trim(commit_hash0)
    assets_to_serve()
    |> Enum.map(&request_upload_url(&1, root_key, env, commit_hash1))
    |> Enum.map(&upload_and_notify(&1, root_key, env, commit_hash1))
    |> write_inventory(commit_hash0)
  end

  defp assets_to_serve() do
    Path.join(@assets_directory, "**")
    |> Path.wildcard()
    |> ignore_external_cdn_assets()
    |> Enum.map(fn file_abs_path ->
      case File.stat!(file_abs_path) do
        %File.Stat{type: :regular, size: file_size} -> {file_abs_path, Path.relative_to(file_abs_path, @assets_directory), file_size}
        _otherwise -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp ignore_external_cdn_assets(file_abs_paths) do
    external_cdn_assets_rel_paths = Map.keys(@external_cdn_assets)
    Enum.reject(file_abs_paths, fn file_abs_path ->
      Enum.any?(external_cdn_assets_rel_paths, &String.ends_with?(file_abs_path, &1))
    end)
  end

  defp request_upload_url({asset_abs_path, asset_rel_path, file_size}, root_key, env, commit_hash) do
    %_success{body: %{"uploadUrl" => upload_url}} = Assets.upsert(asset_rel_path, file_size, root_key, env, commit_hash)
    {asset_abs_path, asset_rel_path, upload_url}
  end

  defp upload_and_notify({asset_abs_path, asset_rel_path, upload_url}, root_key, env, commit_hash) do
    %_success{body: res_body} = Assets.upload_and_notify(asset_abs_path, asset_rel_path, upload_url, root_key, env, commit_hash)
    %{"publicUrl" => "http://" <> noscheme_url} = res_body
    https_url = "https://#{noscheme_url}"
    IO.puts(IO.ANSI.light_cyan() <> asset_rel_path <> IO.ANSI.reset() <> "\n => " <> IO.ANSI.green() <> https_url <> IO.ANSI.reset())
    "#{asset_rel_path} #{https_url}\n"
  end

  defp write_inventory(lines, commit_hash0) do
    lines_with_external_assets = lines ++ Enum.map(@external_cdn_assets, fn {asset_rel_path, cdn_url} -> "#{asset_rel_path} #{cdn_url}\n" end)
    File.write!(@assets_inventory, Enum.join([commit_hash0 | lines_with_external_assets]))
    File.touch!(@assets_module)
    IO.puts("Refreshed " <> IO.ANSI.green() <> @assets_module <> IO.ANSI.reset())
  end
end
