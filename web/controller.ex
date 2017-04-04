defmodule Yubot.Controller do
  defmacro __using__(_) do
    quote do
      use SolomonLib.Controller
      import Yubot.Controller.{Result, Util}
    end
  end
end
