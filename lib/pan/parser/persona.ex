defmodule Pan.Parser.Persona do
  import Ecto.Query
  alias Pan.Repo

  def get_or_insert(persona_map) do
    # itunes:owner/contributor sub-fields sometimes contain embedded HTML
    # instead of plain text (e.g. Cloudflare's email-obfuscation snippet,
    # <a data-cfemail="...">[email protected]</a>, parsed into a nested
    # %{name: :a, value: [...], attr: [...]} map rather than a string) —
    # drop any non-string value here rather than let it reach UUID.uuid5/2
    # (requires a binary) or an Ecto :string column insert later.
    # The key is dropped, not set to nil, so the put_new defaults for
    # :name and :uri below still apply.
    persona_map =
      Map.reject(persona_map, fn {key, value} ->
        key in [:uri, :email, :name] and not is_binary(value)
      end)

    # The idea is to set the pid to be imported as strong as possible
    # That is panoptikum:pid > uri > email > name; but if the pid in
    # the database does not fit, we still fall back to weaker matches,
    # but not on the name, as names are no unique identifiers.

    persona_map =
      Map.put_new(
        persona_map,
        :pid,
        UUID.uuid5(
          :url,
          persona_map[:uri] ||
            persona_map[:email] ||
            persona_map[:name] ||
            ""
        )
      )

    persona_map =
      if persona_map[:email] do
        Map.put_new(persona_map, :name, name_from_email(persona_map[:email]))
      else
        persona_map
      end

    persona_map = Map.put_new(persona_map, :uri, persona_map[:email])
    uri = Map.get(persona_map, :uri, "")
    email = Map.get(persona_map, :email, "")

    case find_persona(persona_map[:pid], uri, email) do
      nil ->
        %PanWeb.Persona{}
        |> Map.merge(persona_map)
        |> Repo.insert()

      persona ->
        {:ok, persona}
    end
  end

  @doc ~s("john.doe@example.com" -> "John Doe")
  def name_from_email(email) do
    email
    |> String.split("@")
    |> List.first()
    |> String.split(".")
    |> Stream.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp find_persona(pid, uri, email) do
    (pid && Repo.get_by(PanWeb.Persona, pid: pid)) ||
      (uri && Repo.get_by(PanWeb.Persona, pid: uri)) ||
      (uri && Repo.get_by(PanWeb.Persona, uri: uri)) ||
      (email && Repo.one(from(p in PanWeb.Persona, where: p.email == ^email, limit: 1)))
  end
end
