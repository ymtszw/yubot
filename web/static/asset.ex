defmodule Yubot.Asset do
  use SolomonLib.Asset

  def bootstrap4(), do: url("vendor/css/bootstrap.min.css")
end
