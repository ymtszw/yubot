defmodule Mix.Tasks.Yubot.InitDodai do
  use Mix.Task

  @models (
    (:code.lib_dir(:yubot) ++ '/ebin/*.beam')
    |> Path.wildcard()
    |> Enum.filter_map(&(&1 =~ ~r/Yubot\.Model\.[A-Z]\w+\.beam/), fn filename ->
      String.replace(filename, ~r|\A(.+/)+|, "")
      |> String.trim_trailing(".beam")
      |> String.to_existing_atom()
    end)
  )
  @gear_config Path.join([__DIR__, "..", "..", "..", "gear_config"]) |> File.read!()

  def run(_) do
    System.put_env("PORT", "12345")
    System.put_env("YUBOT_GEAR_CONFIG_JSON", @gear_config)
    Application.ensure_all_started(:yubot)
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
