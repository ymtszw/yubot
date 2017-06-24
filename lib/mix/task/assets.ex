defmodule Mix.Tasks.Yubot.Assets do
  @moduledoc """
  Upload assets to CDN and generate Elm Assets module.

  # Usage

      $ mix yubot.assets (dev|prod)
  """

  use Mix.Task

  @shortdoc "Upload assets to CDN and generate Elm Assets module"

  def run(args) do
    Mix.Tasks.Yubot.Assets.Upload.run(args)
    :timer.sleep(300)
    Mix.Tasks.Yubot.Assets.GenElmModule.run(args)
  end
end
