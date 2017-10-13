use Croma

defmodule Yubot.Repo.Poll do
  alias Croma.Result, as: R
  alias Dodai.GroupId
  alias SolomonLib.{Cron, Time}
  alias Yubot.Model.Poll, as: MP
  use SolomonAcs.Dodai.Repo.Datastore, [
    datastore_models: [MP],
  ]

  @doc """
  Schedules next run of a Poll.

  Should be called BEFORE the Poll is run.
  So that `last_run_at` and `next_run_at` will be updated before current execution is finished,
  ensuring it will not be run again when the execution does not succeed or failed within one minute.

  Note that this does not require previous `last_run_at` or `next_run_at`,
  so it can be used for brand-new Polls.
  """
  defun schedule_next(%MP{_id: id, data: %MP.Data{interval: i}},
                      now      :: v[Time.t],
                      key      :: v[String.t],
                      group_id :: v[GroupId.t]) :: R.t(MP.t) do
    i |> MP.Interval.to_cron(id) |> Cron.parse!() |> Cron.next(now) |> set_run_at(now, id, key, group_id)
  end

  def set_run_at(next_run_at, last_run_at, id, key, group_id) do
    %{data: %{"$set" => %{next_run_at: next_run_at, last_run_at: last_run_at}}}
    |> update(id, key, group_id)
  end

  @doc """
  Records `entry` to `:history` field of a Poll.

  Will be called after the Poll execution finished, regardless of success or failure.
  """
  defun record_history(%MP.HistoryEntry{} = entry,
                       id       :: v[MP.Id.t],
                       key      :: v[String.t],
                       group_id :: v[GroupId.t]) :: R.t(MP.t) do
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
            "$slice" => MP.History.max_length(),
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
  defun disable_with_error_history(error :: any, run_at :: v[Time.t], id :: v[MP.Id.t], key :: v[String.t], group_id :: v[GroupId.t]) :: R.t(MP.t) do
    %MP.HistoryEntry{
      run_at: run_at,
      poll_result: %MP.PollResult{status: 500, body_hash: inspect(error)},
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
  defun retrieve_executables(now :: v[Time.t], key :: v[String.t], group_id :: v[GroupId.t]) :: R.t([MP.t]) do
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
