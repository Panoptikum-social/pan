defmodule Pan.OpmlParser.OpmlTest do
  use Pan.DataCase

  alias Pan.OpmlParser.Opml
  alias PanWeb.{FeedBacklog, User}

  setup do
    n = System.unique_integer([:positive])

    user =
      Repo.insert!(%User{name: "Test", username: "opml_#{n}", email: "opml_#{n}@example.com"})

    {:ok, user: user}
  end

  defp write_opml(outlines) do
    path = Path.join(System.tmp_dir!(), "opml_test_#{System.unique_integer([:positive])}.opml")

    File.write!(
      path,
      ~s(<?xml version="1.0"?><opml version="2.0"><head><title>Subscriptions</title></head><body>#{outlines}</body></opml>)
    )

    on_exit(fn -> File.rm(path) end)
    path
  end

  defp backlog_urls(user) do
    from(f in FeedBacklog, where: f.user_id == ^user.id, select: f.url, order_by: f.url)
    |> Repo.all()
  end

  test "rss outlines, also in folders, go to the feed backlog", %{user: user} do
    path =
      write_opml(~s"""
      <outline type="rss" text="A" xmlUrl="https://a.example.com/feed"/>
      <outline text="Folder">
        <outline type="rss" text="B" xmlUrl="http://b.example.com/feed"/>
      </outline>
      """)

    assert Opml.parse(path, user.id) == {:ok, 2}
    assert backlog_urls(user) == ["http://b.example.com/feed", "https://a.example.com/feed"]
  end

  test "outlines without an http(s) xmlUrl are skipped", %{user: user} do
    path =
      write_opml(~s"""
      <outline type="rss" text="ok" xmlUrl="https://ok.example.com/feed"/>
      <outline type="rss" text="script" xmlUrl="javascript:alert(1)"/>
      <outline type="rss" text="file" xmlUrl="file:///etc/passwd"/>
      <outline type="rss" text="missing"/>
      """)

    assert Opml.parse(path, user.id) == {:ok, 1}
    assert backlog_urls(user) == ["https://ok.example.com/feed"]
  end

  test "more than 1500 feeds are refused as a whole", %{user: user} do
    path =
      write_opml(
        Enum.map_join(1..1501, "", &~s(<outline type="rss" xmlUrl="https://example.com/#{&1}"/>))
      )

    assert {:error, message} = Opml.parse(path, user.id)
    assert message =~ "1501 feeds"
    assert backlog_urls(user) == []
  end

  test "a file with too many distinct names is refused before parsing", %{user: user} do
    path = write_opml(Enum.map_join(1..300, "", &~s(<x#{&1} y#{&1}="1"/>)))

    before = :erlang.system_info(:atom_count)
    assert {:error, message} = Opml.parse(path, user.id)
    assert message =~ "too many distinct"
    assert :erlang.system_info(:atom_count) == before
  end
end
