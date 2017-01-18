defmodule Pan.Parser.Persona do
  use Pan.Web, :controller

  def get_or_insert(persona_map) do
    if persona_map[:email] do
      persona_map = Map.put_new(persona_map, :name, "unknown")
                    |> Map.put_new(:username, persona_map[:email])

      case Repo.all(from u in Pan.Persona, where: u.email == ^persona_map[:email],
                                           limit: 1)
           |> List.first do
        nil ->
          %Pan.Persona{}
          |> Map.merge(persona_map)
          |> Repo.insert()
        persona ->
          {:ok, persona}
      end
    else
      {:ok, Repo.get_by(Pan.Persona, email: "jane@podcasterei.at")}
    end
  end
end