defmodule Mix.Tasks.Yubot.Assets do
  @moduledoc """
  Upload assets to CDN and generate Elm Assets module.

  # Usage

      $ mix yubot.assets (dev|prod)
  """

  use Mix.Task

  @shortdoc "Upload assets to CDN and generate Elm Assets module"

  def run(args) do
    Mix.Tasks.Yubot.UploadAssets.run(args)
    Mix.Tasks.Yubot.GenElmAssets.run(args)
  end
end
