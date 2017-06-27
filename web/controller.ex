defmodule Yubot.Controller do
  defmacro __using__(opts) do
    shared_ast = quote do
      use SolomonLib.Controller
      import Yubot.Controller.{Result, Util}
    end
    [shared_ast | auth_plug_asts(opts)]
  end

  defp auth_plug_asts(opts) do
    case opts[:auth] do
      nil -> []
      :cookie_only -> [cookie_only_auth_ast(Keyword.get(opts, :auth_opts, []))]
      :cookie_or_header -> [cookie_or_header_auth_ast(Keyword.get(opts, :auth_opts, []))]
    end
  end

  defp cookie_only_auth_ast(auth_opts) do
    quote do
      plug Yubot.Plug.Auth, :cookie_only, unquote(auth_opts)
    end
  end

  defp cookie_or_header_auth_ast(auth_opts) do
    quote do
      plug Yubot.Plug.Auth, :cookie_or_header, unquote(auth_opts)
    end
  end
end
