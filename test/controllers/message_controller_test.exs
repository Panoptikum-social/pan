defmodule Pan.MessageControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.Message
    @valid_attrs %{content: "some content",
                   event: "some content",
                   subtopic: "some content",
                   topic: "some content",
                   type: "some content"}
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get conn, message_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing messages"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get conn, message_path(conn, :new)
      assert html_response(conn, 200) =~ "New message"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      conn = post conn, message_path(conn, :create), message: @valid_attrs
      assert redirected_to(conn) == message_path(conn, :index)
      assert Repo.get_by(Message, @valid_attrs)
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post conn, message_path(conn, :create), message: @invalid_attrs
      assert html_response(conn, 200) =~ "New message"
    end

    test "shows chosen resource", %{conn: conn} do
      message = Repo.insert! %Message{}
      conn = get conn, message_path(conn, :show, message)
      assert html_response(conn, 200) =~ "Show message"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, message_path(conn, :show, -1)
      end
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      message = Repo.insert! %Message{}
      conn = get conn, message_path(conn, :edit, message)
      assert html_response(conn, 200) =~ "Edit message"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      message = Repo.insert! %Message{}
      conn = put conn, message_path(conn, :update, message), message: @valid_attrs
      assert redirected_to(conn) == message_path(conn, :show, message)
      assert Repo.get_by(Message, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      message = Repo.insert! %Message{}
      conn = put conn, message_path(conn, :update, message), message: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit message"
    end

    test "deletes chosen resource", %{conn: conn} do
      message = Repo.insert! %Message{}
      conn = delete conn, message_path(conn, :delete, message)
      assert redirected_to(conn) == message_path(conn, :index)
      refute Repo.get(Message, message.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, message_path(conn, :new)),
      get(conn, message_path(conn, :index)),
      get(conn, message_path(conn, :show, "123")),
      get(conn, message_path(conn, :edit, "123")),
      put(conn, message_path(conn, :update, "123")),
      post(conn, message_path(conn, :create, %{})),
      delete(conn, message_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end