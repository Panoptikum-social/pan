defmodule Pan.Parser.Owner do
  use Pan.Web, :controller
  alias Pan.Parser.Persona

  def get_or_insert(owner_map, podcast_id) do
    {:ok, owner} = Persona.get_or_insert(owner_map)

    %Engagement{persona_id: owner.id,
                podcast_id: podcast_id,
                role: "owner"}
    |> Repo.insert()
  end
end