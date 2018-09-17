defmodule Pan.Parser.Persona do
  import Ecto.Query
  alias Pan.Repo

  def get_or_insert(persona_map) do
    # The idea is to set the pid to be imported as strong as possible
    # That is panoptikum:pid > uri > email > name; but if the pid in
    # the database does not fit, we still fall back to weaker matches,
    # but not on the name, as names are no unique identifiers.

    persona_map = Map.put_new(persona_map, :pid,
                              UUID.uuid5(:url, persona_map[:uri] ||
                                               persona_map[:email] ||
                                               persona_map[:name]))

    persona_map =
      if persona_map[:email] do
        Map.put_new(persona_map, :name, persona_map[:email]
        |> String.split("@")
        |> hd()
        |> String.split(".")
        |> Stream.map(&String.capitalize/1)
        |> Enum.join(" "))
      else
        persona_map
      end

    persona_map = Map.put_new(persona_map, :uri, persona_map[:email])
    uri = persona_map[:uri] || ""
    email = persona_map[:email] || ""

    case Repo.get_by(PanWeb.Persona, pid:   persona_map[:pid]) ||
         Repo.get_by(PanWeb.Persona, pid:   uri) ||
         Repo.get_by(PanWeb.Persona, uri:   uri) ||
         Repo.one(from p in PanWeb.Persona, where: p.email == ^email,
                                            limit: 1) do
      nil ->
        %PanWeb.Persona{}
        |> Map.merge(persona_map)
        |> Repo.insert()
      persona ->
        {:ok, persona}
    end
  end
end