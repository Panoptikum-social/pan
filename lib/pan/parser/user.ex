defmodule Pan.Parser.User do
  use Pan.Web, :controller

  def get_or_insert(user_map) do
    if user_map[:email] do
      user_map = Map.put_new(user_map, :name, "unknown")
                 |> Map.put_new(:username, user_map[:email])

      case Repo.all(from u in Pan.User, where: u.email == ^user_map[:email],
                                        limit: 1)
           |> List.first do
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