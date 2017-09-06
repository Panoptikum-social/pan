defmodule Pan.OpmlFrontendControllerTest do
  use PanWeb.ConnCase
  alias PanWeb.FeedBacklog

  describe "when user is logged in and is a user" do
    setup do
      user = insert_user()
      conn = assign(build_conn(), :current_user, user)
      {:ok, conn: conn}
    end

    alias PanWeb.Opml

    test "lists all entries on index", %{conn: conn} do
      conn = get conn, opml_frontend_path(conn, :index)
      assert html_response(conn, 200) =~ "My OPML files"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get conn, opml_frontend_path(conn, :new)
      assert html_response(conn, 200) =~ "Upload OPML File"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      user = conn.assigns.current_user

      conn = post conn, opml_frontend_path(conn, :create),
                        opml: %{file: %Plug.Upload{path: "test/fixtures/opml.xml",
                                                   filename: "opml.xml",
                                                   content_type: "application/xml"},
                                user_id: user.id}

      assert redirected_to(conn) == opml_frontend_path(conn, :index)
      assert Repo.get_by(Opml, %{filename: "opml.xml",
                                 content_type: "application/xml",
                                 user_id: user.id})
    end


    test "responds with flash, if no file provided", %{conn: conn} do
      conn = post conn, opml_frontend_path(conn, :create), nil
      assert redirected_to(conn) == opml_frontend_path(conn, :new)
    end


    test "deletes chosen resource", %{conn: conn} do
      user = conn.assigns.current_user

      opml = Repo.insert! %Opml{path: "test/fixtures/opml.xml",
                                filename: "opml.xml",
                                content_type: "application/xml",
                                user_id: user.id}
      conn = delete conn, opml_frontend_path(conn, :delete, opml)
      assert redirected_to(conn) == opml_frontend_path(conn, :index)
      refute Repo.get(Opml, opml.id)
    end


    test "imports feeds into feed backlog", %{conn: conn} do
      user = conn.assigns.current_user
      opml = Repo.insert! %Opml{path: "materials/minimal_opml.xml",
                                filename: "minimal_opml.xml",
                                content_type: "application/xml",
                                user_id: user.id}

      conn = get conn, opml_frontend_path(conn, :import, opml)

      assert redirected_to(conn) == opml_frontend_path(conn, :index)
      assert Repo.get_by(FeedBacklog, %{url: "http://feeds.feedburner.com/mobile-macs-podcast",
                                        user_id: user.id})
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, opml_frontend_path(conn, :new)),
      get(conn, opml_frontend_path(conn, :index)),
      post(conn, opml_frontend_path(conn, :create, %{})),
      delete(conn, opml_frontend_path(conn, :delete, "123")),
      get(conn, opml_frontend_path(conn, :import, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end