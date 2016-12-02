defmodule Yubot.Router do
  use SolomonLib.Router

  static_prefix "/static"

  get "/hello", Hello, :hello
end
