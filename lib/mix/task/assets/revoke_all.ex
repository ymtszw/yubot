defmodule Mix.Tasks.Yubot.Assets.RevokeAll do
  @moduledoc """
  Revoke *ALL* existing assets.

  # Usage

      $ mix yubot.assets.revoke_all (dev|prod)
  """

  use Mix.Task
  alias Yubot.Assets

  @shortdoc "Revoke ALL existing assets"

  def run([env]) do
    System.put_env("PORT", "12122")
    Application.ensure_all_started(:solomon)
    config_file = if env == "prod", do: raise("not ready!"), else: "gear_config"
    root_key = File.read!(config_file) |> Poison.decode!() |> Map.get("dodai_root_key")
    revoke_all_impl(root_key, env)
  end
  def run(_) do
    run(["dev"])
  end

  defp revoke_all_impl(root_key, env) do
    Assets.retrieve_list(root_key, env)
    |> Enum.each(fn %Dodai.Model.FileEntity{_id: id, public_url: public_url} ->
      case Assets.revoke(id, root_key, env) do
        %Dodai.DeleteDedicatedFileEntitySuccess{} ->
          IO.puts(IO.ANSI.green() <> "Revoked #{public_url}" <> IO.ANSI.reset())
        error ->
          IO.puts(IO.ANSI.red() <> "Failed to revoke #{public_url}\n" <> inspect(error) <> IO.ANSI.reset())
      end
    end)
  end
end
