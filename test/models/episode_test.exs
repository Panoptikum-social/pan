defmodule Pan.EpisodeTest do
  use Pan.ModelCase

  alias Pan.Episode

  @valid_attrs %{author: "Episode author",
                 deep_link: "https://panoptikum.io/path/episode/deeplink",
                 description: "Description text",
                 duration: "some content",
                 guid: "episode-guid-a1b2c3d4",
                 link: "https://panoptikum.io/path/episode",
                 payment_link_title: "Episode payment link title",
                 payment_link_url: "https://panoptikum.io/path/episode/payment",
                 publishing_date: "2010-04-17 14:00:00",
                 shownotes: "Episode shownotes",
                 subtitle: "Episode subtitle",
                 summary: "Episode summary",
                 title: "Episode title"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    podcast = insert_podcast()

    changeset = Episode.changeset(%Episode{}, Map.merge(@valid_attrs, %{podcast_id: podcast.id}))
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Episode.changeset(%Episode{}, @invalid_attrs)
    refute changeset.valid?
  end
end
