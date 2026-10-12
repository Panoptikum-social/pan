defmodule PanWeb.MaintenanceControllerTest do
  use PanWeb.ConnCase

  alias Pan.Repo
  alias PanWeb.{Engagement, Persona, Podcast, User}

  defp logged_in_admin(conn) do
    n = System.unique_integer([:positive])

    admin =
      Repo.insert!(%User{
        name: "Admin",
        username: "maint_#{n}",
        email: "maint_#{n}@example.com",
        admin: true
      })

    init_test_session(conn, %{"user_id" => admin.id, "admin" => true})
  end

  test "fix_nameless_personas names email-only personas and re-flags their podcasts",
       %{conn: conn} do
    n = System.unique_integer([:positive])

    podcast =
      Repo.insert!(%Podcast{title: "Maintenance podcast #{n}", description: "d", full_text: true})

    persona =
      Repo.insert!(%Persona{pid: "maint-#{n}", email: "john.doe@example.com", full_text: true})

    Repo.insert!(%Engagement{podcast_id: podcast.id, persona_id: persona.id, role: "owner"})

    conn = get(logged_in_admin(conn), "/admin/maintenance/fix_nameless_personas")

    assert redirected_to(conn) == "/admin/databrowser/persona"
    assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "nameless personas got a name"

    persona = Repo.get!(Persona, persona.id)
    assert persona.name == "John Doe"
    refute persona.full_text
    refute Repo.get!(Podcast, podcast.id).full_text
  end
end
