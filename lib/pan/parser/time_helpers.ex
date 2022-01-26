defmodule Pan.Parser.MyDateTime do
  def now() do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
  end
end
