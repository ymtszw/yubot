defmodule Yubot.TypeGen do
  defmacro limited_byte_string_body(max_byte) do
    quote do
      @type t :: String.t
      def validate(str) when is_binary(str) and byte_size(str) < unquote(max_byte), do: {:ok, str}
      def validate(_), do: {:error, {:invalid_value, [__MODULE__]}}
    end
  end

  defmodule Nilable do
    defmacro __using__(opts) do
      quote bind_quoted: [opts: opts] do
        @module opts[:module]
        @type t :: nil | @module.t

        def validate(nil), do: {:ok, nil}
        def validate(other), do: @module.validate(other)

        def new(nil), do: {:ok, nil}
        def new(other), do: @module.new(other)

        def default(), do: nil
      end
    end
  end
end
