defmodule Pan.PodcastTest do
  use Pan.ModelCase

  alias Pan.Podcast

  @valid_attrs %{author: "some content",
                 description: "some content",
                 explicit: true,
                 image_title: "some content",
                 image_url: "some content",
                 last_build_date: "2010-04-17 14:00:00",
                 payment_link_title: "some content",
                 payment_link_url: "some content",
                 summary: "some content",
                 title: "some content",
                 unique_identifier: "7488a646-e31f-11e4-aace-600308960662",
                 website: "some content"}
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
