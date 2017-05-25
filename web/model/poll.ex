use Croma

defmodule Yubot.Model.Poll do
  alias Croma.Result, as: R
  alias Yubot.Jq
  alias Yubot.Model.{Authentication, Action}

  defmodule Interval do
    @type t :: String.t

    @spec validate(term) :: R.t(t)
    def validate(i) when i in ["1", "3", "10", "30", "hourly", "daily"], do: {:ok, i}
    def validate(i) when i in [1, 3, 10, 30, :hourly, :daily], do: {:ok, to_string(i)}
    def validate(_), do: {:error, {:invalid_value, [__MODULE__]}}

    def default(), do: "10"

    @spec to_cron(t) :: String.t
    def to_cron("1"), do: "* * * * *"
    def to_cron(minute) when minute in ["3", "10", "30"], do: "*/#{minute} * * * *"
    def to_cron("hourly"), do: "0 * * * *"
    def to_cron("daily"), do: "0 0 * * *"
  end

  use SolomonAcs.Dodai.Model.Datastore, data_fields: [
    interval: Interval,
    url: SolomonLib.Url,
    auth: Croma.TypeGen.nilable(Authentication.Id),
    action: Action.Id,
    filters: Croma.TypeGen.list_of(Jq.Filter),
  ]
end
