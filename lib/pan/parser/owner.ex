defmodule Pan.Parser.Owner do
  use Pan.Web, :controller
  alias Pan.Parser.Persona

  def get_or_insert(owner_map, podcast_id) do
    if owner_map[:email] || owner_map[:name] do
      {:ok, owner} = Persona.get_or_insert(owner_map)


      case Repo.get_by(Pan.Engagement, persona_id: owner.id,
                                       podcast_id: podcast_id,
                                       role: "owner") do
        nil ->
          %Pan.Engagement{persona_id: owner.id,
                          podcast_id: podcast_id,
                          role: "owner"}
          |> Repo.insert()
        engagement ->
          {:ok, engagement}
      end
    end
  end
end