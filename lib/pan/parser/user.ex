defmodule Pan.Parser.User do
  use Pan.Web, :controller

  def find_or_create(user_map) do
    if user_map[:email] do
      user_map = Map.put_new(user_map, :name, "unknown")
                 |> Map.put_new(:username, user_map[:email])

      case Repo.get_by(Pan.User, email: user_map[:email]) do
        nil ->
          %Pan.User{}
          |> Map.merge(user_map)
          |> Repo.insert()
        user ->
          {:ok, user}
      end
    else
      {:ok, Repo.get_by(Pan.User, email: "jane@podcasterei.at")}
    end
  end
end