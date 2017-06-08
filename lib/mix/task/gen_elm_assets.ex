defmodule Mix.Tasks.Yubot.GenElmAssets do
  @moduledoc """
  Generate Assets Elm module.

  # Usage

      $ mix yubot.gen_elm_assets (dev|prod)
  """

  use Mix.Task
  alias Yubot.Assets

  @shortdoc "Generate Assets Elm module"
  @template Path.expand(Path.join([__DIR__, "gen_elm_assets", "Assets.elm.eex"]))
  @target   Path.expand(Path.join(["ui", "src", "Assets.elm"]))

  def run(_) do
    File.write!(@target, EEx.eval_file(@template, inventory: Assets.inventory()))
  end
end
