use Croma

defmodule Yubot.Model.Poll do
  @max_history 30
  @moduledoc """
  Central model of this gear. Holds polling target, interval, actions and their trigger conditions.

  # Basic procedure

  - If an HTTP request for a Poll resulted in success, the response body will be evaluated by `Trigger`s in order.
  - If all `Condition`s in a `Trigger` are met, an `Action` specified in the `Trigger` will be executed.
      - Only the first satisfied `Trigger` will be executed per request, so an order of `Trigger`s matters.
  - If an HTTP request resulted in failure somehow (either on Poll, or on Action),
    they are logged (and the User will be notified. NYI).

  # History (NYI)

  Recent execution history of a Poll will be logged in `:history` field, in time-descending order.
  Up to #{@max_history} entires will be kept. Older ones will be discarded.
  """

  import Croma.TypeGen, only: [nilable: 1, list_of: 1]
  alias Croma.Result, as: R
  alias Yubot.Jq
  alias Yubot.Grasp, as: G
  alias Yubot.Model.{Authentication, Action}

  defmodule Capacity do
    use Croma.SubtypeOfInt, min: 5_000, default: 5_000
  end

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

  defmodule Trigger do
    defmodule Condition do
      @moduledoc """
      Trigger condition. Basically `Grasp.Instruction`, but with `BooleanResponder`.
      """

      @type t :: G.Instruction.t

      def validate(term) do
        G.Instruction.validate(term) |> R.bind(fn
          %G.Instruction{responder: %G.BooleanResponder{}} = i -> {:ok, i}
          _not_boolean_responder -> {:error, {:invalid_value, [__MODULE__]}}
        end)
      end

      def new(term), do: validate(term)
    end

    defmodule Material do
      @moduledoc """
      Dict for Action variables.

      Keys are string variables of an Action, values are `Grasp.Instruction`.
      Should be an empty map if the Action does not take any variables.
      """

      use Croma.SubtypeOfMap, key_module: Croma.String, value_module: G.Instruction, default: %{}

      def new(term), do: validate(term)
    end

    defmodule ConditionList do
      use Croma.SubtypeOfList, elem_module: Condition, max_length: 5, default: []

      defun new(term :: term) :: R.t(t) do
        (list) when is_list(list) -> Enum.map(list, &Condition.new/1) |> R.sequence()
        (_non_list) -> {:error, {:invalid_value, [__MODULE__]}}
      end
    end

    use Croma.Struct, recursive_new?: true, fields: [
      action_id: Action.Id,
      conditions: ConditionList,
      material: Material,
    ]
  end

  defmodule TriggerList do
    use Croma.SubtypeOfList, elem_module: Trigger, max_length: 5, default: []

    defun new(term :: term) :: R.t(t) do
      (list) when is_list(list) -> Enum.map(list, &Trigger.new/1) |> R.sequence()
      (_non_list) -> {:error, {:invalid_value, [__MODULE__]}}
    end
  end

  use SolomonAcs.Dodai.Model.Datastore, data_fields: [
    interval: Interval,
    url: SolomonLib.Url,
    # auth: Croma.TypeGen.nilable(Authentication.Id), # DEPRECATED; Eliminating since nilable field cannot be distinguished its version by itself
    auth_id: nilable(Authentication.Id),
    action: nilable(Action.Id), # DEPRECATED
    filters: nilable(list_of(Jq.Filter)), # DEPRECATED
    is_enabled: nilable(Croma.Boolean), # TODO strip nilable
    triggers: TriggerList,
    last_run_at: nilable(SolomonLib.Time),
    next_run_at: nilable(SolomonLib.Time),
    # history: list_of(History), # TODO enable
  ]

  defmodule ShallowTrialRequest do
    use Croma.Struct, fields: [
      url: SolomonLib.Url,
      auth_id: nilable(Authentication.Id),
    ]
  end
end
