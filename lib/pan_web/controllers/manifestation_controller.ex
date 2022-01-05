defmodule PanWeb.ManifestationController do
  use PanWeb, :controller
  alias PanWeb.Manifestation

  def get_by_user(conn, %{"id" => id}) do
    manifestations =
      from(m in Manifestation,
        where: m.user_id == ^id,
        preload: :persona
      )
      |> Repo.all()

    conn
    |> put_layout(false)
    |> render("get_by_user.html", manifestations: manifestations)
  end

  def get_by_persona(conn, %{"id" => id}) do
    manifestations =
      from(m in Manifestation,
        where: m.persona_id == ^id,
        preload: :user
      )
      |> Repo.all()

    conn
    |> put_layout(false)
    |> render("get_by_persona.html", manifestations: manifestations)
  end

  def toggle(conn, %{"user_id" => user_id, "persona_id" => persona_id}) do
    case Repo.get_by(Manifestation,
           user_id: user_id,
           persona_id: persona_id
         ) do
      nil ->
        %Manifestation{
          user_id: String.to_integer(user_id),
          persona_id: String.to_integer(persona_id)
        }
        |> Repo.insert()

      manifestation ->
        Repo.delete!(manifestation)
    end

    text(conn, "OK.")
  end
end
