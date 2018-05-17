use Croma

defmodule Yubot.Service.RunPoll do
  alias Croma.Result, as: R
  alias Antikythera.Http.Status
  alias Yubot.Grasp
  alias Yubot.External.Http, as: ExHttp
  alias Yubot.Model.{Poll, Action}
  alias Yubot.Model.Poll.{PollResult, TriggerResult}

  @type t :: {:ok, {PollResult.t, nil | TriggerResult.t}} | {:error, term}

  @doc """
  Poll the URL, evaluate the body then execute registered Actions.

  If a hash of retrieved body is exactly the same as the last time,
  Triggers won't be evaluated and thus Actions will not be executed,
  unless `force?` option is `true`.
  """
  defun exec(%Poll.Data{url: u, auth_id: nil_or_auth_id, triggers: ts, history: h},
             key :: v[String.t],
             group_id :: v[Dodai.GroupId.t],
             force? :: v[boolean] \\ false) :: t do
    R.m do
      nil_or_auth <- fetch_auth(nil_or_auth_id, key, group_id)
      %{body: b} = r <- ExHttp.request(:get, u, "", nil_or_auth)
      nil_or_matched_trigger <- evaluate_triggers(b, ts)
      exec_action(r, nil_or_matched_trigger, h, key, group_id, force?)
    end
  end

  defp evaluate_triggers(_body, []) do
    {:ok, nil}
  end
  defp evaluate_triggers(body, [%Poll.Trigger{conditions: cs} = t | ts]) do
    case cs |> Enum.map(&Grasp.run(body, &1, false)) |> R.sequence() do
      {:ok, bools} -> if Enum.all?(bools), do: {:ok, t}, else: evaluate_triggers(body, ts)
      {:error, _} = e -> e
    end
  end

  defp exec_action(r, nil, _history, _key, _group_id, _force?),
    do: PollResult.new(r) |> R.map(&{&1, nil})
  defp exec_action(%{body_hash: bh} = r, _trigger, [%Poll.HistoryEntry{poll_result: %PollResult{body_hash: bh}} | _], _key, _group_id, false),
    do: %{r | status: Status.code(:not_modified)} |> PollResult.new() |> R.map(&{&1, nil})
  defp exec_action(%{status: s} = r, _trigger, _history, _key, _group_id, _fource?) when s < 200 or s >= 300,
    do: PollResult.new(r) |> R.map(&{&1, nil})
  defp exec_action(%{body: b} = r, %Poll.Trigger{action_id: ai, material: m}, _history, key, group_id, _force?) do
    R.m do
      %Action{data: %Action.Data{auth_id: nil_or_auth_id} = d} <- Yubot.Repo.Action.retrieve(ai, key, group_id)
      nil_or_auth <- fetch_auth(nil_or_auth_id, key, group_id)
      dict <- build_variable_dict(b, m, d.body_template.variables)
      %{status: s} <- Action.exec(d, dict, nil_or_auth)
      poll_result <- PollResult.new(r)
      trigger_result <- TriggerResult.new(%{action_id: ai, status: s, variables: dict})
      pure {poll_result, trigger_result}
    end
  end

  defp build_variable_dict(body, material, variables) do
    material
    |> Map.take(variables)
    |> Enum.map(fn {k, i} -> Grasp.run(body, i) |> R.map(&{k, elem(&1, 1)}) end)
    |> R.sequence()
    |> R.map(&Map.new/1)
  end

  defp fetch_auth(nil, _key, _group_id), do: {:ok, nil}
  defp fetch_auth(auth_id, key, group_id), do: Yubot.Repo.Authentication.retrieve(auth_id, key, group_id)
end
