defmodule Yubot.Controller.User do
  use Yubot.Controller, auth: :cookie_only

  @key Yubot.Plug.Auth.session_key()

  # POST /api/user/logout
  @doc """
  Logout requesting user by deleting session information in the cookie.

  It does NOT forcibly destroy Dodai session, thus the user may keep his session on different user agent.
  Dodai sessions will eventually expire after several hours or days.
  Until then, users will not be asked for their identities.

  There is no Dodai logout API in this gear.

  This is somewhat non-RESTful API. Yeah, I know that.
  """
  def logout(conn) do
    conn
    |> delete_session(@key)
    |> put_status(204)
  end
end
