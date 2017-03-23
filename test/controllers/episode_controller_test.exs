defmodule Pan.EpisodeControllerTest do
  use Pan.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias Pan.Episode
    @valid_attrs %{deep_link: "some content",
                   description: "some content",
                   duration: "some content",
                   guid: "some content",
                   link: "some content",
                   payment_link_title: "some content",
                   payment_link_url: "some content",
                   publishing_date: ~N[2010-04-17 12:13:14],
                   shownotes: "some content",
                   subtitle: "some content",
                   summary: "some content",
                   title: "some content"}
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get conn, episode_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing"
      assert html_response(conn, 200) =~ "episodes"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get conn, episode_path(conn, :new)
      assert html_response(conn, 200) =~ "New episode"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      podcast = insert_podcast()

      conn = post conn, episode_path(conn, :create),
                        episode: Map.merge(@valid_attrs, %{podcast_id: podcast.id})
      assert redirected_to(conn) == episode_path(conn, :index)
      assert Repo.get_by(Episode, Map.merge(@valid_attrs, %{podcast_id: podcast.id}))
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post conn, episode_path(conn, :create), episode: @invalid_attrs
      assert html_response(conn, 200) =~ "New episode"
    end

    test "shows chosen resource", %{conn: conn} do
      podcast = insert_podcast()

      episode = %Episode{podcast_id: podcast.id}
                |> Map.merge(@valid_attrs)
                |> Repo.insert!()

      conn = get conn, episode_path(conn, :show, episode)
      assert html_response(conn, 200) =~ "Show episode"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, episode_path(conn, :show, -1)
      end
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      episode = Repo.insert! %Episode{}
      conn = get conn, episode_path(conn, :edit, episode)
      assert html_response(conn, 200) =~ "Edit episode"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      podcast = insert_podcast()

      episode = Repo.insert! %Episode{}
      conn = put conn, episode_path(conn, :update, episode),
                       episode: Map.merge(@valid_attrs, %{podcast_id: podcast.id})
      assert redirected_to(conn) == episode_path(conn, :show, episode)
      assert Repo.get_by(Episode, Map.merge(@valid_attrs, %{podcast_id: podcast.id}))
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      episode = Repo.insert! %Episode{}
      conn = put conn, episode_path(conn, :update, episode), episode: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit episode"
    end

    test "deletes chosen resource", %{conn: conn} do
      episode = Repo.insert! %Episode{}
      conn = delete conn, episode_path(conn, :delete, episode)
      assert redirected_to(conn) == episode_path(conn, :index)
      refute Repo.get(Episode, episode.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, episode_path(conn, :new)),
      get(conn, episode_path(conn, :index)),
      get(conn, episode_path(conn, :show, "123")),
      get(conn, episode_path(conn, :edit, "123")),
      put(conn, episode_path(conn, :update, "123")),
      post(conn, episode_path(conn, :create, %{})),
      delete(conn, episode_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end