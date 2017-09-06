defmodule Pan.ManifestationControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.Manifestation
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get conn, manifestation_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing manifestations"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get conn, manifestation_path(conn, :new)
      assert html_response(conn, 200) =~ "New manifestation"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      user = insert_user()
      persona = insert_persona()

      conn = post conn, manifestation_path(conn, :create),
                        manifestation: %{user_id: user.id,
                                         persona_id: persona.id}
      assert redirected_to(conn) == manifestation_path(conn, :index)
      assert Repo.get_by(Manifestation, %{user_id: user.id,
                                          persona_id: persona.id})
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post conn, manifestation_path(conn, :create), manifestation: @invalid_attrs
      assert html_response(conn, 200) =~ "New manifestation"
    end

    test "shows chosen resource", %{conn: conn} do
      manifestation = Repo.insert! %Manifestation{}
      conn = get conn, manifestation_path(conn, :show, manifestation)
      assert html_response(conn, 200) =~ "Show manifestation"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, manifestation_path(conn, :show, -1)
      end
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      manifestation = Repo.insert! %Manifestation{}
      conn = get conn, manifestation_path(conn, :edit, manifestation)
      assert html_response(conn, 200) =~ "Edit manifestation"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      user = insert_user()
      persona = insert_persona()

      manifestation = Repo.insert! %Manifestation{}
      conn = put conn, manifestation_path(conn, :update, manifestation),
                       manifestation: %{user_id: user.id,
                                        persona_id: persona.id}
      assert redirected_to(conn) == manifestation_path(conn, :show, manifestation)
      assert Repo.get_by(Manifestation, %{user_id: user.id,
                                          persona_id: persona.id})
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      manifestation = Repo.insert! %Manifestation{}
      conn = put conn, manifestation_path(conn, :update, manifestation), manifestation: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit manifestation"
    end

    test "deletes chosen resource", %{conn: conn} do
      manifestation = Repo.insert! %Manifestation{}
      conn = delete conn, manifestation_path(conn, :delete, manifestation)
      assert redirected_to(conn) == manifestation_path(conn, :index)
      refute Repo.get(Manifestation, manifestation.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, manifestation_path(conn, :new)),
      get(conn, manifestation_path(conn, :index)),
      get(conn, manifestation_path(conn, :show, "123")),
      get(conn, manifestation_path(conn, :edit, "123")),
      put(conn, manifestation_path(conn, :update, "123")),
      post(conn, manifestation_path(conn, :create, %{})),
      delete(conn, manifestation_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end