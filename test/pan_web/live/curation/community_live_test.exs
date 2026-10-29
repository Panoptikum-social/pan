defmodule PanWeb.Live.Curation.CommunityLiveTest do
  use PanWeb.ConnCase

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Pan.Repo
  alias PanWeb.{Category, CategoryPodcast, Community, Journal, Moderation, Podcast, User}

  setup %{conn: conn} do
    n = System.unique_integer([:positive])

    moderator =
      Repo.insert!(%User{
        name: "Moderator",
        username: "curation_#{n}",
        email: "curation_#{n}@example.com",
        moderator: true
      })

    category = Repo.insert!(%Category{title: "Curation category #{n}"})

    community =
      Repo.insert!(%Community{title: "Curation community #{n}", category_id: category.id})

    Repo.insert!(%Moderation{user_id: moderator.id, community_id: community.id})
    podcast = Repo.insert!(%Podcast{title: "Curation podcast #{n}", description: "d"})
    Repo.insert!(%CategoryPodcast{category_id: category.id, podcast_id: podcast.id})

    %{
      conn: init_test_session(conn, %{"user_id" => moderator.id}),
      moderator: moderator,
      category: category,
      community: community,
      podcast: podcast
    }
  end

  defp open?(category, podcast) do
    Repo.get_by!(CategoryPodcast, category_id: category.id, podcast_id: podcast.id).open_for_curation
  end

  test "mark done asks first, reopen doesn't; both are journaled", %{
    conn: conn,
    moderator: moderator,
    category: category,
    community: community,
    podcast: podcast
  } do
    {:ok, view, _html} = live(conn, "/curator/communities/#{community.id}")

    button = element(view, "button[phx-value-podcast_id='#{podcast.id}']")
    assert render(button) =~ "data-confirm=\"Mark this podcast as done?"

    render_click(button)
    refute open?(category, podcast)
    refute has_element?(button)

    view |> element("#curation-filter") |> render_change(%{"filter" => "all", "search" => ""})
    refute render(button) =~ "data-confirm"

    render_click(button)
    assert open?(category, podcast)

    texts =
      from(j in Journal, where: j.module == "PanWeb.Curation", order_by: j.id, select: j.text)
      |> Repo.all()
      |> Enum.filter(&(&1 =~ "podcast #{podcast.id} in community #{community.id}"))

    assert texts == [
             "podcast #{podcast.id} in community #{community.id} marked done by user #{moderator.id}",
             "podcast #{podcast.id} in community #{community.id} reopened by user #{moderator.id}"
           ]
  end
end
