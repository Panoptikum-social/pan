defmodule PanWeb.MaintenanceController do
  use PanWeb, :controller
  import Pan.Parser.MyDateTime, only: [now: 0]

  alias PanWeb.{
    Category,
    Delegation,
    Engagement,
    Episode,
    Feed,
    FeedBacklog,
    Follow,
    Gig,
    Language,
    Like,
    Manifestation,
    Opml,
    Persona,
    Podcast,
    Recommendation,
    Subscription,
    User,
    PageFrontendView,
    Journal
  }

  # title is stored as plain text after a single XML-decode pass, so a
  # leftover double-escape bug shows up there as a *singly*-escaped entity.
  @single_escaped_entities_pattern "&(quot|apos|#0?39|lt|gt|amp);"

  # description/summary/shownotes are stored as serialized HTML: they've
  # already been through one HTML-parse-then-reserialize pass via the
  # scrubber at import time, which is the identity transform for anything
  # that was double-escaped in the source (decoding &amp;quot; once yields
  # text "&quot;", which the serializer re-escapes right back to
  # &amp;quot; on the way out). So here the leftover bug still shows up
  # *doubly*-escaped in the stored value.
  @double_escaped_entities_pattern "&amp;(quot|apos|amp|lt|gt|#\\d+|#x[0-9A-Fa-f]+);"
  @double_escaped_entities Regex.compile!(@double_escaped_entities_pattern)

  def vienna_beamers(conn, _params) do
    redirect(conn, external: "https://blog.panoptikum.social/vienna-beamers/")
  end

  def blog_2016(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.social/2016/#{month}/#{day}/#{file}")
  end

  def blog_2017(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.social/2017/#{month}/#{day}/#{file}")
  end

  def exception_notification(_conn, _params) do
    raise "exception_notification"
  end

  def fix_nils(conn, _params) do
    boolean_columns = [
      {Podcast, :explicit},
      {Podcast, :blocked},
      {Podcast, :update_paused},
      {Podcast, :retired},
      {Podcast, :full_text},
      {Podcast, :thumbnailed},
      {User, :admin},
      {User, :email_confirmed},
      {User, :podcaster},
      {User, :share_subscriptions},
      {User, :share_follows},
      {User, :moderator},
      {Persona, :full_text},
      {Persona, :thumbnailed},
      {Feed, :trust_last_modified},
      {Feed, :no_headers_available},
      {FeedBacklog, :in_progress},
      {Gig, :self_proclaimed},
      {Category, :full_text},
      {Episode, :full_text}
    ]

    Enum.each(boolean_columns, fn {repo, field_name} ->
      Task.start(fn -> update_nil_records_async(repo, field_name) end)
    end)

    put_view(conn, PageFrontendView)
    |> render("done.html")
  end

  defp update_nil_records_async(repo, field_name) do
    update_args = Keyword.new([{field_name, false}])

    from(r in repo, where: is_nil(field(r, ^field_name)))
    |> Repo.aggregate(:count, :id, timeout: :timer.minutes(10))

    from(r in repo,
      where: is_nil(field(r, ^field_name)),
      update: [set: ^update_args]
    )
    |> Repo.update_all([], timeout: :timer.minutes(10))
  end

  def catch_up_thumbnailed(conn, _params) do
    podcast_candidates =
      from(p in Podcast,
        where: not p.thumbnailed and not is_nil(p.image_url),
        limit: 1_000,
        select: p.id
      )
      |> Repo.all()

    podcasts_missing_thumbnailed =
      from(p in Podcast,
        where: p.id in ^podcast_candidates,
        left_join: i in assoc(p, :thumbnails),
        where: not is_nil(i.podcast_id),
        select: p.id
      )
      |> Repo.all()

    from(p in Podcast, where: p.id in ^podcasts_missing_thumbnailed)
    |> Repo.update_all(set: [thumbnailed: true])

    persona_candidates =
      from(p in Persona,
        where: not p.thumbnailed and not is_nil(p.image_url),
        limit: 1_000,
        select: p.id
      )
      |> Repo.all()

    personas_missing_thumbnailed =
      from(p in Persona,
        where: p.id in ^persona_candidates,
        left_join: i in assoc(p, :thumbnails),
        where: not is_nil(i.persona_id),
        select: p.id
      )
      |> Repo.all()

    from(p in Persona, where: p.id in ^personas_missing_thumbnailed)
    |> Repo.update_all(set: [thumbnailed: true])

    conn
    |> put_view(PageFrontendView)
    |> render("done.html")
  end

  # Some feed producers double-encode their own output (e.g. re-escaping an
  # already-escaped title when it's edited through their CMS), so the raw
  # XML holds &amp;quot; instead of &quot;. A conformant single-pass XML
  # parser only decodes &amp; -> &, so episodes imported before
  # Pan.Parser.Helpers.unescape_double_escaped_entities/1 existed ended up
  # with the literal entity text (e.g. &quot;) stored in their title,
  # description, summary or shownotes instead of the actual character. This
  # backfills those already-stored values; new imports are fixed at parse
  # time going forward.
  def fix_double_escaped_html_entities(conn, _params) do
    Task.start(fn -> unescape_episode_titles_async() end)
    Task.start(fn -> unescape_episode_html_fields_async() end)

    conn
    |> put_view(PageFrontendView)
    |> render("done.html")
  end

  defp unescape_episode_titles_async do
    candidates =
      from(e in Episode,
        where: fragment("? ~ ?", e.title, ^@single_escaped_entities_pattern),
        select: {e.id, e.title}
      )
      |> Repo.all(timeout: :timer.minutes(10))

    changed = candidates |> Enum.map(&fix_episode_title/1) |> Enum.count(& &1)

    Journal.log(%{
      module: __MODULE__,
      method: "unescape_episode_titles_async",
      text:
        "scanned #{length(candidates)} candidate episode titles, fixed #{changed} " <>
          "(see individual entries below for before/after per episode)"
    })
  end

  defp fix_episode_title({id, title}) do
    new_title = unescape_single_escaped_entities(title)

    if new_title != title do
      from(e in Episode, where: e.id == ^id)
      |> Repo.update_all([set: [title: new_title]], timeout: :timer.minutes(1))

      Journal.log(%{
        module: __MODULE__,
        method: "unescape_episode_titles_async",
        text: "episode #{id}: unescaped double-escaped HTML entities in title",
        before: title,
        after: new_title
      })

      true
    end
  end

  defp unescape_single_escaped_entities(text) do
    text
    |> String.replace("&quot;", "\"")
    |> String.replace(~r/&(apos|#0?39);/, "'")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
  end

  # description/summary/shownotes hold real HTML (already run through the
  # scrubber at import time), unlike title's plain text. Blindly unescaping
  # &lt;/&gt; the way the title fix does could resurrect real markup (a
  # double-escaped &amp;lt;script&amp;gt; would decode straight to a live
  # <script> tag), so each touched value is re-run through the same
  # scrubber normal imports use before being saved.
  defp unescape_episode_html_fields_async do
    candidates =
      from(e in Episode,
        where:
          fragment("? ~ ?", e.description, ^@double_escaped_entities_pattern) or
            fragment("? ~ ?", e.summary, ^@double_escaped_entities_pattern) or
            fragment("? ~ ?", e.shownotes, ^@double_escaped_entities_pattern),
        select: {e.id, e.description, e.summary, e.shownotes}
      )
      |> Repo.all(timeout: :timer.minutes(10))

    changed = candidates |> Enum.map(&fix_episode_html_fields/1) |> Enum.count(& &1)

    Journal.log(%{
      module: __MODULE__,
      method: "unescape_episode_html_fields_async",
      text:
        "scanned #{length(candidates)} candidate episodes (description/summary/shownotes), " <>
          "fixed #{changed} (see individual entries below for before/after per episode)"
    })
  end

  defp fix_episode_html_fields({id, description, summary, shownotes}) do
    original = %{description: description, summary: summary, shownotes: shownotes}
    updated = Map.new(original, fn {field, value} -> {field, unescape_and_resanitize(value)} end)
    changes = for {field, value} <- updated, value != original[field], do: {field, value}

    if changes != [] do
      from(e in Episode, where: e.id == ^id)
      |> Repo.update_all([set: changes], timeout: :timer.minutes(1))

      changed_fields = Enum.map_join(changes, ", ", &elem(&1, 0))

      Journal.log(%{
        module: __MODULE__,
        method: "unescape_episode_html_fields_async",
        text: "episode #{id}: unescaped double-escaped HTML entities in #{changed_fields}",
        before: Map.new(changes, fn {field, _new} -> {field, original[field]} end),
        after: Map.new(changes)
      })

      true
    end
  end

  defp unescape_and_resanitize(html) when is_binary(html) do
    if html =~ @double_escaped_entities do
      html
      |> Pan.Parser.Helpers.unescape_double_escaped_entities()
      |> HtmlSanitizeEx.Scrubber.BasicHTMLReduced.sanitize()
    else
      html
    end
  end

  defp unescape_and_resanitize(other), do: other

  def stats(conn, _params) do
    stale_podcasts =
      from(p in Podcast,
        where:
          p.next_update <= ^now() and
            not p.update_paused and
            not p.retired
      )
      |> Repo.aggregate(:count)
      |> delimit_integer(" ")

    inactive_podcasts =
      from(p in Podcast, where: p.update_paused == true and not p.retired)
      |> Repo.aggregate(:count)

    retired_podcasts =
      from(p in Podcast, where: p.retired == true)
      |> Repo.aggregate(:count)

    average_update_intervall =
      from(p in Podcast, where: not p.update_paused and not p.retired)
      |> Repo.aggregate(:avg, :update_intervall)
      |> Decimal.round(2)

    total_podcasts =
      Repo.aggregate(Podcast, :count, :id)
      |> delimit_integer(" ")

    feeds_without_headers =
      from(f in Feed, where: f.no_headers_available == ^true)
      |> Repo.aggregate(:count)

    feeds_with_etag =
      from(f in Feed, where: not is_nil(f.etag))
      |> Repo.aggregate(:count)

    feeds_with_last_modified =
      from(f in Feed, where: not is_nil(f.last_modified))
      |> Repo.aggregate(:count)

    total_episodes =
      Repo.aggregate(Podcast, :sum, :episodes_count)
      |> delimit_integer(" ")

    unindexed_episodes =
      from(e in Episode, where: not e.full_text)
      |> Repo.aggregate(:count, timeout: :timer.minutes(10))
      |> delimit_integer(" ")

    podcasts_per_hour =
      (Repo.aggregate(Podcast, :count, :id) - inactive_podcasts)
      |> Decimal.new()
      |> Decimal.div(average_update_intervall)
      |> Decimal.round()

    total_users = Repo.aggregate(User, :count, :id)

    total_gigs =
      Repo.aggregate(Gig, :count, :id)
      |> delimit_integer(" ")

    total_engagements =
      Repo.aggregate(Engagement, :count, :id)
      |> delimit_integer(" ")

    total_personas =
      Repo.aggregate(Persona, :count, :id)
      |> delimit_integer(" ")

    total_subscriptions =
      Repo.aggregate(Subscription, :count, :id)
      |> delimit_integer(" ")

    total_likes = Repo.aggregate(Like, :count, :id)
    total_recommendations = Repo.aggregate(Recommendation, :count, :id)
    total_categories = Repo.aggregate(Category, :count, :id)

    total_categorizations =
      Repo.aggregate("categories_podcasts", :count, :podcast_id)
      |> delimit_integer(" ")

    total_languages = Repo.aggregate(Language, :count, :id)
    total_opmls = Repo.aggregate(Opml, :count, :id)
    total_feed_backlogs = Repo.aggregate(FeedBacklog, :count, :id)
    total_follows = Repo.aggregate(Follow, :count, :id)
    total_manifestations = Repo.aggregate(Manifestation, :count, :id)
    total_delegations = Repo.aggregate(Delegation, :count, :id)

    podcasts_without_image =
      from(p in Podcast, where: not p.thumbnailed and not is_nil(p.image_url))
      |> Repo.aggregate(:count)

    podcasts_with_zero_publication_frequency =
      from(p in Podcast,
        where:
          p.publication_frequency == 0.0 and
            p.episodes_count > 1
      )
      |> Repo.aggregate(:count)

    personas_without_image =
      from(p in Persona, where: not p.thumbnailed and not is_nil(p.image_url))
      |> Repo.aggregate(:count)

    render(conn, "stats.html",
      stale_podcasts: stale_podcasts,
      inactive_podcasts: inactive_podcasts,
      retired_podcasts: retired_podcasts,
      average_update_intervall: average_update_intervall,
      total_podcasts: total_podcasts,
      total_episodes: total_episodes,
      podcasts_per_hour: podcasts_per_hour,
      total_users: total_users,
      total_gigs: total_gigs,
      total_engagements: total_engagements,
      total_personas: total_personas,
      total_subscriptions: total_subscriptions,
      total_likes: total_likes,
      total_recommendations: total_recommendations,
      total_categories: total_categories,
      total_categorizations: total_categorizations,
      total_languages: total_languages,
      total_opmls: total_opmls,
      total_feed_backlogs: total_feed_backlogs,
      total_follows: total_follows,
      total_manifestations: total_manifestations,
      total_delegations: total_delegations,
      unindexed_episodes: unindexed_episodes,
      podcasts_without_image: podcasts_without_image,
      personas_without_image: personas_without_image,
      feeds_without_headers: feeds_without_headers,
      feeds_with_etag: feeds_with_etag,
      feeds_with_last_modified: feeds_with_last_modified,
      podcasts_with_zero_publication_frequency: podcasts_with_zero_publication_frequency
    )
  end

  defp delimit_integer(number, delimiter) do
    abs(number)
    |> Integer.to_charlist()
    |> :lists.reverse()
    |> delimit_integer(delimiter, [])
  end

  defp delimit_integer([a, b, c, d | tail], delimiter, acc) do
    delimit_integer([d | tail], delimiter, [delimiter, c, b, a | acc])
  end

  defp delimit_integer(list, _, acc) do
    :lists.reverse(list) ++ acc
  end
end
