defmodule PanWeb.Live.CheckFeedAccessTest do
  use PanWeb.ConnCase

  import Phoenix.LiveViewTest
  import PanWeb.Router.Helpers

  alias Pan.Repo
  alias PanWeb.Live.Podcast.CheckFeed
  alias PanWeb.{Podcast, User}

  defp insert_user(attrs \\ []) do
    n = System.unique_integer([:positive])

    %User{name: "Test", username: "feedcheck_#{n}", email: "feedcheck_#{n}@example.com"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp insert_podcast(attrs \\ []) do
    n = System.unique_integer([:positive])

    %Podcast{title: "Feed check podcast #{n}", description: "d"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp logged_in(conn, user), do: init_test_session(conn, %{"user_id" => user.id})

  test "manageable_by? is true for the owner, admins and moderators only" do
    owner = insert_user()
    podcast = insert_podcast(user_id: owner.id)

    assert Podcast.manageable_by?(podcast, owner.id)
    assert Podcast.manageable_by?(podcast, insert_user(admin: true).id)
    assert Podcast.manageable_by?(podcast, insert_user(moderator: true).id)
    refute Podcast.manageable_by?(podcast, insert_user().id)
    refute Podcast.manageable_by?(podcast, nil)
  end

  test "a user who does not manage the podcast is sent back to the podcast page", %{conn: conn} do
    podcast = insert_podcast(user_id: insert_user().id)
    path = podcast_frontend_path(@endpoint, :check_feed, podcast)

    assert {:error, {:live_redirect, %{to: to}}} = live(logged_in(conn, insert_user()), path)
    assert to == podcast_frontend_path(@endpoint, :show, podcast)
  end

  test "the owner, an admin and a moderator get the page", %{conn: conn} do
    owner = insert_user()
    podcast = insert_podcast(user_id: owner.id)
    path = podcast_frontend_path(@endpoint, :check_feed, podcast)

    for user <- [owner, insert_user(admin: true), insert_user(moderator: true)] do
      assert html_response(get(logged_in(conn, user), path), 200) =~ "Feed check"
    end
  end

  defp render_report(xml, selected, reads \\ nil) do
    {:ok, report} = CheckMyFeed.check(xml)

    html =
      %{
        podcast: insert_podcast(),
        status: :done,
        feed_url: "https://example.com/feed",
        error: nil,
        findings: report.findings,
        passed: report.passed,
        not_applicable: report.not_applicable,
        standards: [:rss2, :apple, :podcasting20],
        selected: selected,
        reads: reads
      }
      |> CheckFeed.render()
      |> rendered_to_string()

    {report, html}
  end

  test "rules with nothing to check are listed apart from the passed ones" do
    {report, html} =
      render_report(~s(<rss version="2.0"><channel></channel></rss>), [
        :rss2,
        :apple,
        :podcasting20
      ])

    assert html =~ "Not applicable (#{length(report.not_applicable)})"
    [_before, not_applicable_section] = String.split(html, "Not applicable (")
    assert not_applicable_section =~ "apple.channel.type"
    refute not_applicable_section =~ "rss2.root"
  end

  test "switched-off rule sets are hidden everywhere" do
    xml = ~s(<rss version="2.0"><channel></channel></rss>)
    {_report, html} = render_report(xml, [:rss2])

    assert html =~ "rss2.root"
    refute html =~ "apple."
    refute html =~ "p20."

    {_report, html} = render_report(xml, [])
    assert html =~ "No rule set selected."
    refute html =~ "rss2.root"
  end

  test "the choice of rule sets is kept in the URL", %{conn: conn} do
    owner = insert_user()
    podcast = insert_podcast(user_id: owner.id)
    path = podcast_frontend_path(@endpoint, :check_feed, podcast)

    {:ok, view, _html} = live(logged_in(conn, owner), path <> "?standards=rss2,podcasting20")
    assert has_element?(view, ~s(input[value="rss2"][checked]))
    refute has_element?(view, ~s(input[value="apple"][checked]))

    view
    |> element("form[phx-change=select_standards]")
    |> render_change(%{"standards" => ["", "apple"]})

    assert_patch(view, path <> "?standards=apple")

    view
    |> element("form[phx-change=select_standards]")
    |> render_change(%{"standards" => ["", "rss2", "apple", "podcasting20"]})

    assert_patch(view, path)
  end

  test "what Panoptikum reads from the feed, by its own parser" do
    xml = """
    <rss version="2.0" xmlns:podcast="https://podcastindex.org/namespace/1.0"
         xmlns:psc="http://podlove.org/simple-chapters">
      <channel>
        <title>Reader Show</title>
        <link>https://example.com</link>
        <description>About the show</description>
        <language>de-at</language>
        <podcast:person role="host">Jane Doe</podcast:person>
        <item>
          <title>Episode 1</title>
          <guid>e1</guid>
          <enclosure url="https://example.com/1.mp3" length="1" type="audio/mpeg"/>
          <psc:chapters version="1.2"><psc:chapter start="00:00:00" title="Intro"/></psc:chapters>
        </item>
        <item><title>Episode 2</title><guid>e2</guid></item>
      </channel>
    </rss>
    """

    {:ok, reads} = Pan.Parser.RssFeed.parse_xml(xml, "https://example.com/feed")
    {_report, html} = render_report(xml, [:rss2], reads)

    assert html =~ "What Panoptikum reads from your feed"
    assert html =~ "Reader Show"
    assert html =~ "de-at"
    assert html =~ "Jane Doe (host)"
    assert html =~ "2 episodes, of them:"
    assert html =~ "1 with audio or video (enclosure)"
    assert html =~ "1 with chapters"

    {_report, html} = render_report(xml, [:rss2], nil)
    refute html =~ "What Panoptikum reads from your feed"
  end
end
