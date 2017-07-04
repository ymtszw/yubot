use Croma

defmodule Mix.Tasks.Yubot.Assets.Upload do
  @moduledoc """
  Upload assets to CDN (via Dodai Filestore API and S3).

  Uploaded assets are recorded to inventory file ("web/static/assets"),
  which will be used as compile-time resource for `Yubot.Assets` module.

  Inventory file is not VCS-commited, but uploaded to semi-permanent publicUrl.
  Solomon-Jenkins will fetch it with `$ make assets_inventory`.

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
  @application_js ["poller.js"]

  def run([env, target]), do: run_impl(env, target)
  def run([target]), do: run_impl("dev", target)
  def run(_), do: run_impl("dev", "files")

  defp run_impl(env, target) do
    System.put_env("PORT", "12121")
    Application.ensure_all_started(:solomon)
    config_file = if env == "prod", do: raise("not ready!"), else: "gear_config"
    root_key = File.read!(config_file) |> Poison.decode!() |> Map.get("dodai_root_key")
    if target == "files", do: Assets.revoke_current(root_key, env)
    upload_and_build_inventory(root_key, env, target)
  end

  defp upload_and_build_inventory(root_key, env, target) do
    {commit_hash0, 0} = System.cmd("git", ["rev-parse", "--short", "HEAD"])
    commit_hash1 = String.trim(commit_hash0)
    assets_to_upload(target)
    |> Enum.map(&request_upload_url(&1, root_key, env, commit_hash1))
    |> Enum.map(&upload_and_notify(&1, root_key, env))
    |> write_inventory(commit_hash0, target)
    |> upload_inventory(root_key, env, target)
  end

  defp assets_to_upload(target) do
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
    |> Enum.filter(fn
      {_, file_rel_path, _} when file_rel_path in @application_js -> target == "app"
      _otherwise -> target != "app"
    end)
  end

  defp ignore_external_cdn_assets(file_abs_paths) do
    external_cdn_assets_rel_paths = Map.keys(@external_cdn_assets)
    Enum.reject(file_abs_paths, fn file_abs_path ->
      Enum.any?(external_cdn_assets_rel_paths, &String.ends_with?(file_abs_path, &1))
    end)
  end

  defp request_upload_url({asset_abs_path, asset_rel_path, file_size}, root_key, env, commit_hash) do
    %_success{body: %{"_id" => id, "uploadUrl" => upload_url}} = Assets.upsert(asset_rel_path, file_size, root_key, env, commit_hash)
    {id, asset_abs_path, asset_rel_path, upload_url}
  end

  defp upload_and_notify({id, asset_abs_path, asset_rel_path, upload_url}, root_key, env) do
    %_success{body: res_body} = Assets.upload_and_notify(asset_abs_path, id, upload_url, root_key, env)
    %{"publicUrl" => "http://" <> noscheme_url} = res_body
    https_url = "https://#{noscheme_url}"
    IO.puts(IO.ANSI.light_cyan() <> asset_rel_path <> IO.ANSI.reset() <> "\n => " <> IO.ANSI.green() <> https_url <> IO.ANSI.reset())
    "#{asset_rel_path} #{https_url}\n"
  end

  defp write_inventory(lines, _, "app") do
    inventory_contents = Enum.join(lines)
    File.write!(@assets_inventory, inventory_contents, [:append])
    touch_assets_module()
    File.read!(@assets_inventory)
  end
  defp write_inventory(lines, commit_hash0, _) do
    lines_with_external_assets = Enum.into(@external_cdn_assets, lines, fn {asset_rel_path, cdn_url} -> "#{asset_rel_path} #{cdn_url}\n" end)
    inventory_contents = Enum.join([commit_hash0 | lines_with_external_assets])
    File.write!(@assets_inventory, inventory_contents)
    inventory_contents
  end

  defp touch_assets_module() do
    File.touch!(@assets_module)
    IO.puts("Refreshed " <> IO.ANSI.green() <> @assets_module <> IO.ANSI.reset())
  end

  defp upload_inventory(inventory_contents, root_key, env, "app") do
    %_success{body: %{"_id" => id, "uploadUrl" => upload_url}} = Assets.upsert_inventory(inventory_contents, root_key, env)
    %_success{body: res_body} = Assets.upload_and_notify(inventory_contents, "text/plain", id, upload_url, root_key, env)
    %{"publicUrl" => "http://" <> noscheme_url} = res_body
    https_url = "https://#{noscheme_url}"
    IO.puts(IO.ANSI.light_cyan() <> "Asset inventory" <> IO.ANSI.reset() <> "\n => " <> IO.ANSI.green() <> https_url <> IO.ANSI.reset())
  end
  defp upload_inventory(_, _, _, "files") do
    :ok
  end
end
