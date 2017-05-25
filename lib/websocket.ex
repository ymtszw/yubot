defmodule Yubot.Websocket do
  use SolomonLib.Websocket
  alias SolomonLib.Registry.Group, as: RG

  @live_reload_group "yubot_live_reload"
  @default_epool_id  {:gear, :yubot}
  @reload_frame      {:text, "reload"}

  # Callbacks

  def init(_conn) do
    Yubot.Logger.debug("A client connected with websocket to live reloader.")
    RG.join(@live_reload_group, @default_epool_id)
    {nil, []}
  end

  def handle_client_message(state, _conn, _frame) do
    {state, []}
  end

  def handle_server_message(state, _conn, @reload_frame) do
    Yubot.Logger.debug("Reload is triggered by file change.")
    {state, [@reload_frame]}
  end
  def handle_server_message(state, _conn, _frame) do
    {state, []}
  end

  # APIs

  def broadcast_reload() do
    RG.publish(@live_reload_group, @default_epool_id, @reload_frame)
  end
end
