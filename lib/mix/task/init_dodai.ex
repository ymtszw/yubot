defmodule Mix.Tasks.Yubot.InitDodai do
  use Mix.Task

  @models (
    (:code.lib_dir(:yubot) ++ '/ebin/*.beam')
    |> Path.wildcard()
    |> Enum.filter(&(&1 =~ ~r/Yubot\.Model\.[A-Z]\w+\.beam/))
    |> Enum.map(fn filename ->
      String.replace(filename, ~r|\A(.+/)+|, "")
      |> String.trim_trailing(".beam")
      |> String.to_existing_atom()
    end)
  )
  @gear_config Path.join([__DIR__, "..", "..", "..", "gear_config"])

  def run(_) do
    System.put_env("YUBOT_GEAR_CONFIG_JSON", File.read!(@gear_config))
    SolomonLib.Mix.Task.prepare_solomon()
    Enum.each(@models, fn model ->
      case model.create_collection() do
        {:ok, %Dodai.Model.CollectionSetting{}} ->
          IO.puts(IO.ANSI.green() <> "Created: #{inspect(model)}" <> IO.ANSI.reset())
        {:error, %Dodai.DuplicatedKeyError{}} ->
          IO.puts(IO.ANSI.cyan() <> "Already created: #{inspect(model)}" <> IO.ANSI.reset())
      end
    end)
  end
end
