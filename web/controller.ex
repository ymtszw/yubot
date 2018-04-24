defmodule Yubot.Controller do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use SolomonLib.Controller
      alias Yubot.Controller.{Result, Util}

      case opts[:auth] do
        nil ->
          :ok
        :cookie_only ->
          plug Yubot.Plug.Auth, :cookie_only, []
        :cookie_or_header ->
          plug Yubot.Plug.Auth, :cookie_or_header, []
      end
    end
  end
end
