defmodule PanWeb.PersonaControllerTest do
  use PanWeb.ConnCase

  import Ecto.Query

  alias Pan.Repo
  alias PanWeb.{Manifestation, Persona, User}

  defp insert_user(attrs \\ []) do
    n = System.unique_integer([:positive])

    %User{name: "Test", username: "merge_#{n}", email: "merge_#{n}@example.com"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp insert_persona(attrs \\ []) do
    n = System.unique_integer([:positive])

    %Persona{pid: "merge-#{n}", name: "Persona #{n}", uri: "merge-#{n}"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp claim(persona, user),
    do: Repo.insert!(%Manifestation{persona_id: persona.id, user_id: user.id})

  defp merge(conn, from, to) do
    admin = insert_user(admin: true)

    conn
    |> init_test_session(%{"user_id" => admin.id, "admin" => true})
    |> get("/admin/personas/merge", %{"from" => from.id, "to" => to.id})
    |> tap(fn _conn ->
      # let the background task of Search.Persona.reset_copies/1 finish
      # before the sandbox owner exits
      Process.sleep(100)
    end)
  end

  defp claimants(persona) do
    from(m in Manifestation, where: m.persona_id == ^persona.id, select: m.user_id)
    |> Repo.all()
    |> Enum.sort()
  end

  test "claims on both personas end up on the target", %{conn: conn} do
    from_persona = insert_persona()
    to_persona = insert_persona()
    from_user = insert_user()
    to_user = insert_user()
    claim(from_persona, from_user)
    claim(to_persona, to_user)

    conn = merge(conn, from_persona, to_persona)

    assert conn.status == 200
    refute Repo.get(Persona, from_persona.id)
    assert claimants(to_persona) == Enum.sort([from_user.id, to_user.id])
  end

  test "a user claiming both personas keeps one claim", %{conn: conn} do
    from_persona = insert_persona()
    to_persona = insert_persona()
    user = insert_user()
    claim(from_persona, user)
    claim(to_persona, user)

    merge(conn, from_persona, to_persona)

    assert claimants(to_persona) == [user.id]
  end

  test "the target inherits the owner of the source", %{conn: conn} do
    owner = insert_user()
    from_persona = insert_persona(user_id: owner.id)
    to_persona = insert_persona()

    merge(conn, from_persona, to_persona)

    assert Repo.get!(Persona, to_persona.id).user_id == owner.id
  end

  test "refuses to merge personas owned by different users", %{conn: conn} do
    from_persona = insert_persona(user_id: insert_user().id)
    to_persona = insert_persona(user_id: insert_user().id)
    claim(from_persona, insert_user())

    conn = merge(conn, from_persona, to_persona)

    assert redirected_to(conn) == "/admin/personas/merge_candidates"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "owned by different users"
    assert Repo.get(Persona, from_persona.id)
    assert length(claimants(from_persona)) == 1
  end
end
