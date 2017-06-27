use Croma

defmodule Yubot.Model.User do
  @moduledoc """
  User of Poller app.
  """

  use Yubot.Dodai.Model.Users,
    data_fields: [
      display_name: Croma.String,
    ],
    readonly_fields: [
      poll_capacity: Yubot.Model.Poll.Capacity,
    ]
end
