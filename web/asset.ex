defmodule Yubot.Asset do
  use Antikythera.Asset

  def bootstrap4(), do: url("vendor/css/bootstrap.min.css")
end
