defmodule Pan.FeedTest do
  use Pan.ModelCase

  alias Pan.Feed

  @valid_attrs %{feed_generator: "some content",
                 first_page_url: "some content",
                 hub_link_url: "some content",
                 last_page_url: "some content",
                 next_page_url: "some content",
                 prev_page_url: "some content",
                 self_link_title: "some content",
                 self_link_url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Feed.changeset(%Feed{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Feed.changeset(%Feed{}, @invalid_attrs)
    refute changeset.valid?
  end
end
