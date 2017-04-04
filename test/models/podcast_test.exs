defmodule Pan.PodcastTest do
  use Pan.ModelCase

  alias Pan.Podcast

  @valid_attrs %{author: "Podcast author",
                 description: "Podcast description",
                 explicit: false,
                 image_title: "Podcast image title",
                 image_url: "https://panoptikum.io/podcast/image",
                 last_build_date: "2010-04-17 14:00:00",
                 payment_link_title: "Podcast payment link",
                 payment_link_url: "https://panoptikum.io/podcast/payment",
                 summary: "Podcast summary",
                 title: "Podcast title",
                 unique_identifier: "7488a646-e31f-11e4-aace-600308960662",
                 website: "https://panoptikum.io/podcast/site",
                 update_intervall: 1,
                 next_update: "2010-04-17 14:00:00"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Podcast.changeset(%Podcast{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Podcast.changeset(%Podcast{}, @invalid_attrs)
    refute changeset.valid?
  end
end
