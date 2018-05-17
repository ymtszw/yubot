defmodule Yubot.Websocket do
  use Antikythera.Websocket
  alias Antikythera.Registry.Group, as: RG

  @live_reload_group "yubot_live_reload"
  @default_epool_id  {:gear, :yubot}
  @reload_frame      {:text, "reload"}

  # Callbacks

  def init(_conn) do
    RG.join(@live_reload_group, @default_epool_id)
    Yubot.Logger.debug("Client connected for live reload!")
    {nil, [{:text, "Live reload enabled!"}]}
  end

  def handle_client_message(state, _conn, _frame) do
    {state, []}
  end

  def handle_server_message(state, _conn, @reload_frame) do
    Yubot.Logger.debug("Live reload is triggered by file change.")
    {state, [@reload_frame]}
  end
  def handle_server_message(state, _conn, {:text, _} = text_frame) do
    {state, [text_frame]}
  end
  def handle_server_message(state, _conn, _frame) do
    {state, []}
  end

  # APIs

  def broadcast_reload() do
    broadcast(@reload_frame)
  end

  def broadcast(frame) do
    RG.publish(@live_reload_group, @default_epool_id, frame)
  end
end
