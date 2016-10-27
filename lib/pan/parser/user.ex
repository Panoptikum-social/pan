defmodule Pan.Parser.User do
  use Pan.Web, :controller

  def find_or_create(user_map) do
    user_map = Map.put_new(user_map, :name, "unknown")

    case Repo.get_by(Pan.User, username: user_map[:name]) do
      nil ->
        %Pan.User{}
        |> Map.merge(user_map)
        |> Map.merge(%{username: user_map[:name]})
        |> Repo.insert()
      user ->
        {:ok, user}
    end
  end
end