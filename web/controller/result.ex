use Croma

defmodule Yubot.Controller.Result do
  use SolomonLib.Controller
  alias SolomonLib.Http.Status

  # Result generators

  def bad_request(request_element), do: {:error, {:bad_request, request_element}}

  # Convenient wrappers of handle/2

  def handle_with_204(result, conn) do
    handle(result, conn, fn _val, conn -> put_status(conn, 204) end)
  end

  def handle_with_200_json(result, conn) do
    handle(result, conn, fn val, conn -> json(conn, 200, val) end)
  end

  def handle_with_201_json(result, conn) do
    handle(result, conn, fn val, conn -> json(conn, 201, val) end)
  end

  @doc """
  Generic result tuple handler. Also handles Dodai error structs.
  """
  defun handle(result :: Croma.Result.t(any), %Conn{} = conn, success_fun :: (any, Conn.t -> Conn.t)) :: Conn.t do
    ({:ok, val}, conn, fun) -> fun.(val, conn)
    ({:error, err}, conn, _fun) -> handle_error(err, conn)
  end

  defunp handle_error(err :: any, %Conn{} = conn) :: Conn.t do
    json(conn, to_status(err), to_body(err))
  end

  defp to_body(%OAuth2.Response{body: body}), do: body
  defp to_body(%{} = err), do: err
  defp to_body(err), do: %{"error" => inspect(err)}

  @dodai_error_integers [400, 401, 402, 403, 404, 408, 409, 413, 500]
  @status_atoms Status.Atom.values()
  for dodai_error_integer <- @dodai_error_integers do
    @status_str "#{dodai_error_integer}-"
    defp to_status(%__dodai_error_struct__{code: @status_str <> _}), do: unquote(dodai_error_integer)
  end
  defp to_status(%OAuth2.Response{status_code: status}), do: status
  defp to_status({reason, _}) when reason in [:invalid, :invalid_value, :value_missing], do: 400
  defp to_status({reason, _}) when reason in @status_atoms,                              do: Status.code(reason)
  defp to_status({code, _})   when code in 100..599,                                     do: code
end
