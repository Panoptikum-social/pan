defmodule Pan.Parser.Persona do
  use Pan.Web, :controller

  def get_or_insert(persona_map) do
    persona_map
    |> Map.put_new(:pid, UUID.uuid5(:url, persona_map[:uri]))
    |> Map.put_new(:pid, UUID.uuid5(:url, persona_map[:email]))
    |> Map.put_new(:pid, UUID.uuid5(:url, persona_map[:name]))

    case Repo.get_by(Pan.Persona, pid: persona_map[:pid]) do
      nil ->
        %Pan.Persona{}
        |> Map.merge(persona_map)
        |> Repo.insert()
      persona ->
        {:ok, persona}
    end
  end
end