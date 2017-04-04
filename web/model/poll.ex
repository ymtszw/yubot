use Croma

defmodule Yubot.Model.Poll do
  alias Croma.Result, as: R
  alias Yubot.Jq
  alias Yubot.Model.{Authentication, Action}

  defmodule Interval do
    @type t :: 1 | 3 | 10 | 30 | :hourly | :daily

    @spec validate(term) :: R.t(t)
    def validate(i) when i in ["hourly", "daily"], do: {:ok, String.to_existing_atom(i)}
    def validate(i) when i in [3, 10, 30, :hourly, :daily], do: {:ok, i}
    def validate(_), do: {:error, {:invalid_value, [__MODULE__]}}

    def default(), do: 10

    @spec to_cron(t) :: SolomonLib.Cron.t
    def to_cron(minute) when minute in [3, 10, 30], do: "*/#{minute} * * * *"
    def to_cron(:hourly), do: "0 * * * *"
    def to_cron(:daily), do: "0 0 * * *"
  end

  use SolomonAcs.Dodai.Model.Datastore, data_fields: [
    interval: Interval,
    url: SolomonLib.Url,
    auth: Croma.TypeGen.nilable(Authentication.Id),
    action: Action,
    filters: Croma.TypeGen.list_of(Jq.Filter),
  ]
end