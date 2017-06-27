defmodule Mix.Tasks.Yubot.Assets do
  @moduledoc """
  Upload assets and compiled Elm application to CDN.

  # Usage

      $ mix yubot.assets (dev|prod)
  """

  use Mix.Task

  @shortdoc "Upload assets and compiled Elm application to CDN"

  def run([]) do
    run(["dev"])
  end
  def run([env]) do
    Mix.Tasks.Yubot.Assets.Upload.run([env, "files"])
    :timer.sleep(300)
    Mix.Tasks.Yubot.Assets.CompileElmApp.run([])
    :timer.sleep(300)
    Mix.Tasks.Yubot.Assets.Upload.run([env, "app"])
  end
end
