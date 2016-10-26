defmodule Pan.Parser.User do
  use Pan.Web, :controller

  def find_or_create(owner_map) do
    case Repo.get_by(Pan.User, email: owner_map[:email]) do
      nil -> %Pan.User{}
             |> Map.merge(owner_map)
             |> Map.merge(%{username: owner_map[:name]})
             |> Repo.insert()
      user -> {:ok, user}
    end
  end
end