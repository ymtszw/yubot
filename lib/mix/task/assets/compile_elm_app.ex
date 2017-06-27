defmodule Mix.Tasks.Yubot.Assets.CompileElmApp do
  @moduledoc """
  Compile Elm application with latest assets.

  Read inventory file (web/static/assets) at runtime so that it can always fetch latest inventory.

  # Usage

      $ mix yubot.assets.compile_elm_app
  """

  use Mix.Task

  @shortdoc "Compile Elm application"
  @external_resource Path.expand(Path.join(["web", "static", "assets"]))
  @template Path.expand(Path.join([__DIR__, "Assets.elm.eex"]))
  @target   Path.expand(Path.join(["ui", "src", "Assets.elm"]))

  def run(_) do
    IO.puts("Generating Assets.elm module for commit: " <> IO.ANSI.green() <> commit_hash() <> IO.ANSI.reset())
    File.write!(@target, EEx.eval_file(@template, inventory: inventory() |> Map.delete("poller.js")))
    case System.cmd("make", ["ui"], stderr_to_stdout: true, into: IO.stream(:stdio, :line)) do
      {_, 0} -> IO.puts(IO.ANSI.green() <> "Successfully compiled Elm application." <> IO.ANSI.reset())
      {o, _} ->
        IO.puts(IO.ANSI.red() <> "Failed to compile Elm application!\n#{o}" <> IO.ANSI.reset())
        exit({:shutdown, 1})
    end
  end

  defp assets_file(), do: @external_resource |> File.read!() |> String.split("\n", trim: true)

  defp commit_hash(), do: hd(assets_file())

  defp inventory(), do: assets_file() |> tl() |> Map.new(&List.to_tuple(String.split(&1, " ")))
end
