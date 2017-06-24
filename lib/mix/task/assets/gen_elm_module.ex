defmodule Mix.Tasks.Yubot.Assets.GenElmModule do
  @moduledoc """
  Generate Assets Elm module.

  Read inventory file (web/static/assets) at runtime so that it can always fetch latest inventory.

  # Usage

      $ mix yubot.gen_elm_assets (dev|prod)
  """

  use Mix.Task

  @shortdoc "Generate Assets Elm module"
  @external_resource Path.expand(Path.join(["web", "static", "assets"]))
  @template Path.expand(Path.join([__DIR__, "Assets.elm.eex"]))
  @target   Path.expand(Path.join(["ui", "src", "Assets.elm"]))

  def run(_) do
    IO.puts("Generating Assets.elm module for commit: " <> IO.ANSI.green() <> commit_hash() <> IO.ANSI.reset())
    File.write!(@target, EEx.eval_file(@template, inventory: inventory()))
  end

  defp assets_file(), do: @external_resource |> File.read!() |> String.split("\n", trim: true)

  defp commit_hash(), do: hd(assets_file())

  defp inventory(), do: assets_file() |> tl() |> Map.new(&List.to_tuple(String.split(&1, " ")))
end
