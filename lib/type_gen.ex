defmodule Yubot.TypeGen do
  defmacro limited_byte_string_body(max_byte) do
    quote do
      @type t :: String.t
      def validate(str) when is_binary(str) and byte_size(str) < unquote(max_byte), do: {:ok, str}
      def validate(_), do: {:error, {:invalid_value, [__MODULE__]}}
    end
  end
end
