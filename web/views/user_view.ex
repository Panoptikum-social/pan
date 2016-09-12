defmodule Pan.UserView do
  use Pan.Web, :view
  alias Pan.User

  def first_name(%User{name: name}) do
    name
    |> String.split(" ")
    |> Enum.at(0)
  end
end
