defmodule Yubot.Controller.Util do
  def group_id(conn) do
    case conn.request.headers["x-yubot-blackbox"] do
      "true" ->
        Yubot.Dodai.test_group_id()
      _otherwise ->
        Yubot.Dodai.default_group_id()
    end
  end

  # Require any authentication plug
  def key(conn) do
    case conn.request.headers["x-yubot-blackbox"] do
      "true" ->
        Yubot.Dodai.root_key()
      _otherwise ->
        conn.assigns.key
    end
  end

  def reject_on_rate_limit(conn, predicate \\ &try_call_limit_reached?/1) do
    if predicate.(conn) do
      {:error, {:too_many_requests, "Too many requests. Try again later."}}
    else
      {:ok, conn}
    end
  end

  defp try_call_limit_reached?(conn) do
    # Rather strict limitation, since they are managed per-instance (there are 3 Solomon instances normally)
    # Using user_key as target; somewhat clunky, but it allows omitting retrieve_self
    Yubot.RateLimiter.push(key(conn), [{2, 5_000}, {10, 60_000}])
  end
end
