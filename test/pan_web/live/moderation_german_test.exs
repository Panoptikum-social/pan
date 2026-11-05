defmodule PanWeb.Live.ModerationGermanTest do
  use PanWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Pan.Repo
  alias PanWeb.{Category, CategoryPodcast, Community, Moderation, Podcast, User}

  defp insert_user(attrs) do
    n = System.unique_integer([:positive])

    Repo.insert!(
      struct(
        %User{name: "Test", username: "german_#{n}", email: "german_#{n}@example.com"},
        attrs
      )
    )
  end

  setup %{conn: conn} do
    n = System.unique_integer([:positive])
    moderator = insert_user(moderator: true, locale: "de")
    category = Repo.insert!(%Category{title: "German category #{n}"})

    community =
      Repo.insert!(%Community{
        title: "German community #{n}",
        slug: "german-community-#{n}",
        category_id: category.id
      })

    Repo.insert!(%Moderation{user_id: moderator.id, community_id: community.id})
    podcast = Repo.insert!(%Podcast{title: "German podcast #{n}", description: "d"})
    Repo.insert!(%CategoryPodcast{category_id: category.id, podcast_id: podcast.id})

    %{
      conn: init_test_session(conn, %{"user_id" => moderator.id}),
      category: category,
      community: community,
      podcast: podcast
    }
  end

  test "the moderation page renders in German", %{conn: conn, community: community} do
    {:ok, _view, html} = live(conn, "/moderator/moderation/#{community.slug}")

    assert html =~ "Moderation von German category"
    assert html =~ "Feed hinzufügen"
  end

  test "edit pages use the admin layout but follow the user's language", %{
    conn: conn,
    community: community,
    podcast: podcast
  } do
    {:ok, _view, html} =
      live(conn, "/moderator/moderation/#{community.slug}/podcast/#{podcast.id}")

    assert html =~ "Bearbeiten:"
    assert html =~ "Speichern"
  end

  test "My Moderations renders in German", %{conn: conn} do
    html = conn |> get("/moderator/my_moderations") |> html_response(200)

    assert html =~ "Meine Moderationen"
  end

  test "admin stays English for a German admin" do
    admin = insert_user(admin: true, locale: "de")

    {:ok, _view, html} =
      build_conn()
      |> init_test_session(%{"user_id" => admin.id, "admin" => true})
      |> live("/admin/databrowser/podcast")

    assert html =~ "Page 1 of"
    refute html =~ "Seite 1 von"
  end
end
