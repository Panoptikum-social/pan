defmodule Pan.PersonaControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.Persona
    @valid_attrs %{description: "some content",
                   email: "some content",
                   image_title: "some content",
                   image_url: "some content",
                   name: "some content",
                   pid: "some content",
                   uri: "some content"}
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get conn, persona_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing personas"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get conn, persona_path(conn, :new)
      assert html_response(conn, 200) =~ "New persona"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      conn = post conn, persona_path(conn, :create), persona: @valid_attrs
      assert redirected_to(conn) == persona_path(conn, :index)
      assert Repo.get_by(Persona, @valid_attrs)
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post conn, persona_path(conn, :create), persona: @invalid_attrs
      assert html_response(conn, 200) =~ "New persona"
    end

    test "shows chosen resource", %{conn: conn} do
      persona = Repo.insert! %Persona{}
      conn = get conn, persona_path(conn, :show, persona)
      assert html_response(conn, 200) =~ "Show persona"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, persona_path(conn, :show, -1)
      end
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      persona = Repo.insert! %Persona{}
      conn = get conn, persona_path(conn, :edit, persona)
      assert html_response(conn, 200) =~ "Edit persona"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      persona = Repo.insert! %Persona{}
      conn = put conn, persona_path(conn, :update, persona), persona: @valid_attrs
      assert redirected_to(conn) == persona_path(conn, :show, persona)
      assert Repo.get_by(Persona, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      persona = Repo.insert! %Persona{}
      conn = put conn, persona_path(conn, :update, persona), persona: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit persona"
    end

    test "deletes chosen resource", %{conn: conn} do
      persona = Repo.insert! %Persona{}
      conn = delete conn, persona_path(conn, :delete, persona)
      assert redirected_to(conn) == persona_path(conn, :index)
      refute Repo.get(Persona, persona.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, persona_path(conn, :new)),
      get(conn, persona_path(conn, :index)),
      get(conn, persona_path(conn, :show, "123")),
      get(conn, persona_path(conn, :edit, "123")),
      put(conn, persona_path(conn, :update, "123")),
      post(conn, persona_path(conn, :create, %{})),
      delete(conn, persona_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end