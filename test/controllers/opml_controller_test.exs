defmodule Pan.OpmlControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.Opml
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get(conn, opml_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing opmls"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get(conn, opml_path(conn, :new))
      assert html_response(conn, 200) =~ "New opml"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      user = insert_user()

      conn =
        post(conn, opml_path(conn, :create),
          opml: %{
            file: %Plug.Upload{
              path: "test/fixtures/opml.xml",
              filename: "opml.xml",
              content_type: "application/xml"
            },
            user_id: user.id
          }
        )

      assert redirected_to(conn) == opml_path(conn, :index)

      assert Repo.get_by(Opml, %{
               filename: "opml.xml",
               content_type: "application/xml",
               user_id: user.id
             })
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, opml_path(conn, :create), opml: @invalid_attrs)
      assert html_response(conn, 200) =~ "New opml"
    end

    test "shows chosen resource", %{conn: conn} do
      opml = Repo.insert!(%Opml{})
      conn = get(conn, opml_path(conn, :show, opml))
      assert html_response(conn, 200) =~ "Show opml"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent(404, fn ->
        get(conn, opml_path(conn, :show, -1))
      end)
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      opml = Repo.insert!(%Opml{})
      conn = get(conn, opml_path(conn, :edit, opml))
      assert html_response(conn, 200) =~ "Edit opml"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      user = insert_user()

      opml =
        Repo.insert!(%Opml{
          path: "test/fixtures/opml.xml",
          filename: "opml.xml",
          content_type: "application/xml",
          user_id: user.id
        })

      conn =
        put(conn, opml_path(conn, :update, opml),
          opml: %{
            file: %Plug.Upload{
              path: "test/fixtures/opml.xml",
              filename: "opml.xml",
              content_type: "application/xml"
            },
            user_id: user.id
          }
        )

      assert redirected_to(conn) == opml_path(conn, :show, opml)

      assert Repo.get_by(Opml, %{
               filename: "opml.xml",
               content_type: "application/xml",
               user_id: user.id
             })
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      opml = Repo.insert!(%Opml{})
      conn = put(conn, opml_path(conn, :update, opml), opml: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit opml"
    end

    test "deletes chosen resource", %{conn: conn} do
      user = insert_user()

      opml =
        Repo.insert!(%Opml{
          path: "test/fixtures/opml.xml",
          filename: "opml.xml",
          content_type: "application/xml",
          user_id: user.id
        })

      conn = delete(conn, opml_path(conn, :delete, opml))
      assert redirected_to(conn) == opml_path(conn, :index)
      refute Repo.get(Opml, opml.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each(
      [
        get(conn, opml_path(conn, :new)),
        get(conn, opml_path(conn, :index)),
        get(conn, opml_path(conn, :show, "123")),
        get(conn, opml_path(conn, :edit, "123")),
        put(conn, opml_path(conn, :update, "123")),
        post(conn, opml_path(conn, :create, %{})),
        delete(conn, opml_path(conn, :delete, "123"))
      ],
      fn conn ->
        assert html_response(conn, 302)
        assert conn.halted
      end
    )
  end
end
