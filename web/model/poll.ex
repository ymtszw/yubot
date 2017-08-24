use Croma

defmodule Yubot.Model.Poll do
  @moduledoc """
  Central model of this gear. Holds polling target, interval, actions and their trigger conditions.

  # Basic procedure

  - Target URL will be polled with HTTP GET request at specified interval
  - If an HTTP request for a Poll resulted in success, the response body will be evaluated by `Trigger`s in order.
  - If all `Condition`s in a `Trigger` are met, an `Action` specified in the `Trigger` will be executed.
      - Only the first satisfied `Trigger` will be executed per request, so an order of `Trigger`s matters.
  - If an HTTP request resulted in failure somehow (either on Poll, or on Action),
    they are logged (and the User will be notified. NYI).
  """

  import Croma.TypeGen, only: [nilable: 1]
  alias Croma.Result, as: R
  alias Dodai.GroupId
  alias SolomonLib.{Cron, Time}
  alias Yubot.Grasp, as: G
  alias Yubot.Model.{Authentication, Action}

  defmodule Capacity do
    use Croma.SubtypeOfInt, min: 5_000, default: 5_000
  end

  defmodule Interval do
    @type t :: String.t

    defun valid?(term :: term) :: boolean do
      i when i in ["1", "3", "10", "30", "hourly", "daily"] -> true
      _otherwise -> false
    end

    @spec new(term) :: R.t(t)
    def new(i) when i in ["1", "3", "10", "30", "hourly", "daily"], do: {:ok, i}
    def new(i) when i in [1, 3, 10, 30, :hourly, :daily], do: {:ok, to_string(i)}
    def new(_), do: {:error, {:invalid_value, [__MODULE__]}}

    def default(), do: "10"

    @doc """
    Take interval and _id of a Poll, then generate cron string.

    It takes _ids and assign actual execution minute of hours per Polls
    calculated from hashed value of them.

    With this, each Polls are guaranteed to executed at static interval,
    while spreading out global loads across minutes of hours.

    Note that hours of days of daily Polls will not be hashed,
    and always use UTC 0 o'clock (minutes will be hased though).
    They are innately sparse and should not cause significant problem
    if they are packed in a single hour of day.
    """
    @spec to_cron(t, String.t) :: String.t
    def to_cron("1"     , _id), do: "* * * * *"
    def to_cron("hourly",  id), do: "#{minute_from_hash(id)} * * * *"
    def to_cron("daily" ,  id), do: "#{minute_from_hash(id)} 0 * * *"
    def to_cron(interval,  id) when interval in ["3", "10", "30"] do
      minutes = interval |> String.to_integer() |> minutes_from_hash([minute_from_hash(id)])
      ~s[#{Enum.join(minutes, ",")} * * * *]
    end

    defp minute_from_hash(id) do
      <<first_byte, _ :: binary>> = :crypto.hash(:sha256, id)
      div(first_byte * 60, 256)
    end

    defp minutes_from_hash(interval, minutes) when length(minutes) >= div(60, interval), do: Enum.sort(minutes)
    defp minutes_from_hash(interval, [m | _] = minutes), do: minutes_from_hash(interval, [rem(m + interval, 60) | minutes])
  end

  defmodule Trigger do
    defmodule Condition do
      @moduledoc """
      Trigger condition. Basically `Grasp.Instruction`, but with `BooleanResponder`.
      """

      @type t :: G.Instruction.t

      defun valid?(term :: term) :: boolean do
        %G.Instruction{responder: %G.BooleanResponder{}} -> true
        _otherwise -> false
      end

      defun new(term :: term) :: R.t(t) do
        G.Instruction.new(term) |> R.bind(fn
          %G.Instruction{responder: %G.BooleanResponder{}} = i -> {:ok, i}
          _not_boolean_responder -> {:error, {:invalid_value, [__MODULE__]}}
        end)
      end
    end

    defmodule Material do
      @moduledoc """
      Dict for Action variables.

      Keys are string variables of an Action, values are `Grasp.Instruction`.
      Should be an empty map if the Action does not take any variables.
      """

      use Croma.SubtypeOfMap, key_module: Croma.String, value_module: G.Instruction, default: %{}
    end

    defmodule ConditionList do
      use Croma.SubtypeOfList, elem_module: Condition, max_length: 5, default: []
    end

    use Croma.Struct, recursive_new?: true, fields: [
      action_id: Action.Id,
      conditions: ConditionList,
      material: Material,
    ]
  end

  defmodule TriggerList do
    use Croma.SubtypeOfList, elem_module: Trigger, max_length: 5, default: []
  end

  defmodule PollResult do
    use Croma.Struct, fields: [
      status: SolomonLib.Http.Status,
      body_hash: Croma.String,
    ]
  end

  defmodule TriggerResult do
    use Croma.Struct, fields: [
      action_id: Action.Id,
      status: SolomonLib.Http.Status,
      variables: Croma.Map,
    ]
  end

  defmodule HistoryEntry do
    use Croma.Struct, recursive_new?: true, fields: [
      run_at: Time,
      poll_result: PollResult,
      trigger_result: nilable(TriggerResult),
    ]

    def from_tuple({pr, tr}, ra), do: new(%{run_at: ra, poll_result: pr, trigger_result: tr})
  end

  defmodule History do
    @max_length 20
    @moduledoc """
    Recent execution history of a Poll, in time-descending order.

    Up to #{@max_length} entires will be kept. Older ones will be discarded.
    """

    use Croma.SubtypeOfList, elem_module: HistoryEntry, max_length: @max_length, default: []
  end

  defmodule TrialRequest do
    use Croma.Struct, fields: [
      url: SolomonLib.Url,
      auth_id: nilable(Authentication.Id),
    ]
  end

  use SolomonAcs.Dodai.Model.Datastore, data_fields: [
    interval: Interval,
    url: SolomonLib.Url,
    auth_id: nilable(Authentication.Id),
    is_enabled: nilable(Croma.Boolean), # TODO strip nilable
    triggers: TriggerList,
    last_run_at: nilable(SolomonLib.Time),
    next_run_at: nilable(SolomonLib.Time),
    history: History,
  ]

  @doc """
  Schedules next run of a Poll.

  Should be called BEFORE the Poll is run.
  So that `last_run_at` and `next_run_at` will be updated before current execution is finished,
  ensuring it will not be run again when the execution does not succeed or failed within one minute.

  Note that this does not require previous `last_run_at` or `next_run_at`,
  so it can be used for brand-new Polls.
  """
  defun schedule_next(%__MODULE__{_id: id, data: %Data{interval: i}},
                      now      :: v[Time.t],
                      key      :: v[String.t],
                      group_id :: v[GroupId.t]) :: R.t(t) do
    i |> Interval.to_cron(id) |> Cron.parse!() |> Cron.next(now) |> set_run_at(now, id, key, group_id)
  end

  def set_run_at(next_run_at, last_run_at, id, key, group_id) do
    %{data: %{"$set" => %{next_run_at: next_run_at, last_run_at: last_run_at}}}
    |> update(id, key, group_id)
  end

  @doc """
  Records `entry` to `:history` field of a Poll.

  Will be called after the Poll execution finished, regardless of success or failure.
  """
  defun record_history(%HistoryEntry{} = entry,
                       id       :: v[Id.t],
                       key      :: v[String.t],
                       group_id :: v[GroupId.t]) :: R.t(t) do
    entry
    |> push_history_action()
    |> update(id, key, group_id)
  end

  defp push_history_action(entry) do
    %{
      data: %{
        "$push" => %{
          history: %{
            "$each" => [entry],
            "$position" => 0,
            "$slice" => History.max_length(),
          }
        }
      }
    }
  end

  @doc """
  Disable a Poll on server side error.

  Inspected `error` string will be dumped to `:body_hash` field of `PollResult`.

  FIXME: better place to store recent error?
  """
  defun disable_with_error_history(error :: any, run_at :: v[Time.t], id :: v[Id.t], key :: v[String.t], group_id :: v[GroupId.t]) :: R.t(t) do
    %HistoryEntry{
      run_at: run_at,
      poll_result: %PollResult{status: 500, body_hash: inspect(error)},
      trigger_result: nil,
    }
    |> push_history_action()
    |> put_in([:data, "$set"], %{is_enabled: false})
    |> update(id, key, group_id)
  end

  @doc """
  Retrieve list of ready-to-execute Polls.

  Using comparison query operator (`$lte`) against `:next_run_at` field with `now` as threshold.
  Also, fetching Polls with `next_run_at: nil` using `$or` operator.

  ## Note about comparison query

  In MongoDB, cross-BSON-type comparison will not work for most type combinations.
  For instance, comparison operand with string value will always return false against null values.

  This is somewhat contradicting to [document](https://docs.mongodb.com/v2.6/reference/bson-types/#comparison-sort-order),
  however the behavior is elaborated in [later version](https://docs.mongodb.com/v3.2/reference/method/db.collection.find/#type-bracketing).
  In that it states that cross-BSON-type comparison only works for selected type combinations (i.e. numeric types).
  """
  defun retrieve_executables(now :: v[Time.t], key :: v[String.t], group_id :: v[GroupId.t]) :: R.t([t]) do
    %{
      query: %{
        "data.is_enabled" => true,
        "$or" => [
          %{"data.next_run_at" => nil},
          %{"data.next_run_at" => %{"$lte" => Time.to_iso_timestamp(now)}},
        ]
      }
    }
    |> retrieve_list(key, group_id)
  end
end
