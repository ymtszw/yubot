defmodule Yubot do
  use SolomonLib.GearApplication
  alias SolomonLib.{ExecutorPool, Conn}

  @spec children :: [Supervisor.Spec.spec]
  def children() do
    dev_only_children() ++ [
      # gear-specific workers/supervisors
    ]
  end

  if Mix.env == :dev do
    defp dev_only_children() do
      [
        Yubot.LiveReload.child_spec(),
      ]
    end
  else
    defp dev_only_children(), do: []
  end

  @spec executor_pool_for_web_request(Conn.t) :: ExecutorPool.Id.t
  def executor_pool_for_web_request(_conn) do
    # specify executor pool to use; change the following line if your gear serves to multiple tenants
    {:gear, :yubot}
  end
end
