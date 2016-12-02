use Croma

defmodule Yubot.Gettext do
  use Gettext, otp_app: :yubot

  defun put_locale(locale :: v[String.t]) :: nil do
    Gettext.put_locale(__MODULE__, locale)
  end
end
