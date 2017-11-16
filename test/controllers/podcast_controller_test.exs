defmodule Pan.PodcastControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.Podcast
    @valid_attrs %{description: "some content",
                   explicit: true,
                   image_title: "some content",
                   image_url: "some content",
                   last_build_date: "2010-04-17 14:00:00",
                   payment_link_title: "some content",
                   payment_link_url: "some content",
                   summary: "some content",
                   title: "some content",
                   unique_identifier: "7488a646-e31f-11e4-aace-600308960662",
                   website: "some content",
                   update_intervall: 1,
                   next_update: "2010-04-17 14:00:00"}
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      podcast = insert_podcast()
      insert_episode(%{podcast_id: podcast.id})

      conn = get conn, podcast_path(conn, :index)
      assert html_response(conn, 200) =~ "Podcasts"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get conn, podcast_path(conn, :new)
      assert html_response(conn, 200) =~ "New podcast"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      conn = post conn, podcast_path(conn, :create), podcast: @valid_attrs
      assert redirected_to(conn) == podcast_path(conn, :index)
      assert Repo.get_by(Podcast, @valid_attrs)
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post conn, podcast_path(conn, :create), podcast: @invalid_attrs
      assert html_response(conn, 200) =~ "New podcast"
    end

    test "shows chosen resource", %{conn: conn} do
      podcast = Repo.insert! %Podcast{}
      conn = get conn, podcast_path(conn, :show, podcast)
      assert html_response(conn, 200) =~ "Show podcast"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, podcast_path(conn, :show, -1)
      end
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      podcast = Repo.insert! %Podcast{}
      conn = get conn, podcast_path(conn, :edit, podcast)
      assert html_response(conn, 200) =~ "Edit podcast"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      podcast = Repo.insert! %Podcast{}
      conn = put conn, podcast_path(conn, :update, podcast), podcast: @valid_attrs
      assert redirected_to(conn) == podcast_path(conn, :show, podcast)
      assert Repo.get_by(Podcast, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      podcast = Repo.insert! %Podcast{}
      conn = put conn, podcast_path(conn, :update, podcast), podcast: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit podcast"
    end

    @tag :currently_broken # FIXME
    test "deletes chosen resource", %{conn: conn} do
      podcast = Repo.insert! %Podcast{}
      conn = delete conn, podcast_path(conn, :delete, podcast)
      assert redirected_to(conn) == podcast_path(conn, :index)
      refute Repo.get(Podcast, podcast.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, podcast_path(conn, :new)),
      get(conn, podcast_path(conn, :index)),
      get(conn, podcast_path(conn, :show, "123")),
      get(conn, podcast_path(conn, :edit, "123")),
      put(conn, podcast_path(conn, :update, "123")),
      post(conn, podcast_path(conn, :create, %{})),
      delete(conn, podcast_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end
