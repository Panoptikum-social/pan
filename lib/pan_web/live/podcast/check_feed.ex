defmodule PanWeb.Live.Podcast.CheckFeed do
  use PanWeb, :live_view
  on_mount PanWeb.Live.Auth

  alias Pan.FeedProbe
  alias Pan.Parser.{Download, Feed, Leniency}
  alias PanWeb.Component.Pill
  alias PanWeb.Podcast
  import PanWeb.Router.Helpers

  @severities [:error, :warning, :info]

  def mount(%{"id" => id}, _session, socket) do
    podcast = Pan.Repo.get(Podcast, id)

    cond do
      is_nil(podcast) or podcast.blocked == true ->
        {:ok, push_navigate(socket, to: "/podcasts")}

      not Podcast.manageable_by?(podcast, socket.assigns.current_user_id) ->
        {:ok,
         socket
         |> put_flash(
           :error,
           dgettext("frontend", "The feed check is available to the podcast's owner only.")
         )
         |> push_navigate(to: podcast_frontend_path(PanWeb.Endpoint, :show, podcast))}

      true ->
        socket =
          assign(socket,
            podcast: podcast,
            page_title: dgettext("frontend", "Feed check for %{podcast}", podcast: podcast.title),
            status: :running,
            feed_url: nil,
            findings: [],
            passed: [],
            not_applicable: [],
            reads: nil,
            leniency: nil,
            check_error: nil,
            error: nil,
            probe_status: :idle,
            probe_findings: [],
            probe_passed: [],
            probe_not_applicable: [],
            audio_status: :idle,
            audio_findings: [],
            audio_passed: [],
            audio_not_applicable: [],
            standards: standards(),
            selected: standards()
          )

        {:ok, if(connected?(socket), do: start_check(socket), else: socket)}
    end
  end

  # ?standards=rss2,apple keeps the choice across reloads and in shared links;
  # without the parameter all rule sets are shown.
  def handle_params(params, _uri, socket) do
    selected =
      case params["standards"] do
        nil ->
          socket.assigns.standards

        list ->
          Enum.filter(socket.assigns.standards, &(Atom.to_string(&1) in String.split(list, ",")))
      end

    {:noreply, assign(socket, selected: selected)}
  end

  def handle_event("recheck", _, socket), do: {:noreply, start_check(socket)}

  # Downloads the artwork and asks for the newest media files, one request at
  # a time: on demand only, not with every check.
  def handle_event("probe", _, %{assigns: %{reads: reads}} = socket) when is_map(reads) do
    {:noreply,
     socket
     |> assign(probe_status: :running)
     |> start_async(:probe, fn -> reads |> FeedProbe.probe() |> CheckMyFeed.check_probes() end)}
  end

  def handle_event("probe", _, socket), do: {:noreply, socket}

  # The first megabyte of the newest episodes' media files, on demand only.
  def handle_event("probe_audio", _, %{assigns: %{reads: reads}} = socket) when is_map(reads) do
    {:noreply,
     socket
     |> assign(audio_status: :running)
     |> start_async(:probe_audio, fn ->
       reads |> FeedProbe.probe_audio() |> CheckMyFeed.check_probes()
     end)}
  end

  def handle_event("probe_audio", _, socket), do: {:noreply, socket}

  def handle_event("select_standards", params, socket) do
    chosen = Map.get(params, "standards", [])
    selected = Enum.filter(socket.assigns.standards, &(Atom.to_string(&1) in chosen))

    query =
      if selected == socket.assigns.standards,
        do: "",
        else: "?" <> URI.encode_query(standards: Enum.join(selected, ","))

    path = podcast_frontend_path(socket, :check_feed, socket.assigns.podcast)
    {:noreply, push_patch(socket, to: path <> query)}
  end

  def handle_async(:check, {:ok, {:ok, feed_url, {:ok, report}, reads, leniency}}, socket) do
    {:noreply,
     assign(socket,
       status: :done,
       feed_url: feed_url,
       findings: report.findings,
       passed: report.passed,
       not_applicable: report.not_applicable,
       reads: reads,
       leniency: leniency
     )}
  end

  # Not well-formed XML: the rules can't run, but Panoptikum may well read the
  # feed anyway, so its two sections still show.
  def handle_async(
        :check,
        {:ok, {:ok, feed_url, {:error, {:invalid_xml, reason}}, reads, leniency}},
        socket
      ) do
    {:noreply,
     assign(socket,
       status: :done,
       feed_url: feed_url,
       check_error:
         dgettext(
           "frontend",
           "The feed is not well-formed XML, so the standard rules couldn't be checked: %{reason}",
           reason: inspect(reason)
         ),
       reads: reads,
       leniency: leniency
     )}
  end

  def handle_async(:check, {:ok, {:error, message}}, socket) do
    {:noreply, assign(socket, status: :failed, error: message)}
  end

  def handle_async(:probe, {:ok, {:ok, report}}, socket) do
    {:noreply,
     assign(socket,
       probe_status: :done,
       probe_findings: report.findings,
       probe_passed: report.passed,
       probe_not_applicable: report.not_applicable
     )}
  end

  def handle_async(:probe, {:exit, _reason}, socket) do
    {:noreply, assign(socket, probe_status: :failed)}
  end

  def handle_async(:probe_audio, {:ok, {:ok, report}}, socket) do
    {:noreply,
     assign(socket,
       audio_status: :done,
       audio_findings: report.findings,
       audio_passed: report.passed,
       audio_not_applicable: report.not_applicable
     )}
  end

  def handle_async(:probe_audio, {:exit, _reason}, socket) do
    {:noreply, assign(socket, audio_status: :failed)}
  end

  def handle_async(:check, {:exit, _reason}, socket) do
    {:noreply,
     assign(socket,
       status: :failed,
       error: dgettext("frontend", "The check crashed unexpectedly.")
     )}
  end

  defp start_check(socket) do
    podcast_id = socket.assigns.podcast.id

    socket
    |> assign(
      status: :running,
      findings: [],
      passed: [],
      not_applicable: [],
      reads: nil,
      leniency: nil,
      check_error: nil,
      error: nil,
      probe_status: :idle,
      probe_findings: [],
      probe_passed: [],
      probe_not_applicable: [],
      audio_status: :idle,
      audio_findings: [],
      audio_passed: [],
      audio_not_applicable: []
    )
    |> start_async(:check, fn -> run_check(podcast_id) end)
  end

  defp run_check(podcast_id) do
    with {:ok, feed} <- Feed.get_by_podcast_id(podcast_id),
         url = String.trim(feed.self_link_url),
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           Download.get(url, follow_redirect: true),
         :ok <- Pan.Parser.XmlNames.check(body) do
      {reads, leniency} = read_by_panoptikum(body, url)
      {:ok, url, CheckMyFeed.check(body), reads, leniency}
    else
      {:error, "not found"} ->
        {:error, dgettext("frontend", "This podcast has no feed.")}

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, dgettext("frontend", "The feed server answered with HTTP %{code}.", code: code)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error,
         dgettext("frontend", "The feed could not be downloaded: %{reason}",
           reason: inspect(reason)
         )}

      {:error, message} when is_binary(message) ->
        {:error, message}

      other ->
        {:error,
         dgettext("frontend", "The feed could not be checked: %{reason}", reason: inspect(other))}
    end
  end

  # Pan's own parser on the same download: what Panoptikum takes from the feed
  # and what it repairs on the way. It is more lenient than the rules, but a
  # feed it can't read just leaves the sections out.
  defp read_by_panoptikum(body, url) do
    reads =
      case Pan.Parser.FeedXml.parse_xml(body, url) do
        {:ok, map} -> map
        {:error, _reason} -> nil
      end

    {reads, Leniency.report(body)}
  rescue
    _ -> {nil, nil}
  end

  defp date_line(%{kind: :unreadable, count: count, example: example}),
    do:
      dgettext(
        "frontend",
        "%{dates} Panoptikum can't read, e.g. %{example}: it uses the time of the import instead.",
        dates: dates(count),
        example: inspect(example)
      )

  defp date_line(%{kind: :yearless, count: count, example: example, read_as: read_as}),
    do:
      dgettext(
        "frontend",
        "%{dates} without a year, e.g. %{example}: Panoptikum assumes the current year (read as %{read_as}).",
        dates: dates(count),
        example: inspect(example),
        read_as: read_as
      )

  defp date_line(%{count: count, example: example, read_as: read_as}),
    do:
      dgettext("frontend", "%{dates} like %{example}, read as %{read_as}.",
        dates: dates(count),
        example: inspect(example),
        read_as: read_as
      )

  defp dates(count), do: dngettext("frontend", "%{count} date", "%{count} dates", count)

  defp channel_rows(map) do
    [
      {dgettext("frontend", "Title"), map[:title]},
      {dgettext("frontend", "Description"), shorten(map[:description], 300)},
      {dgettext("frontend", "Website"), map[:website]},
      {dgettext("frontend", "Artwork"), map[:image_url]},
      {dgettext("frontend", "Author"), get_in(map, [:author, :name])},
      {dgettext("frontend", "Owner"), owner(map[:owner])},
      {dgettext("frontend", "Languages"), joined(map[:languages], & &1[:shortcode])},
      {dgettext("frontend", "Categories"), joined(map[:categories], &category/1)},
      {dgettext("frontend", "Explicit"), yes_no(map[:explicit])},
      {dgettext("frontend", "Payment link"), map[:payment_link_url]},
      {dgettext("frontend", "Persons"), joined(map[:contributors], &person/1)},
      {dgettext("frontend", "Last build date"),
       map[:last_build_date] && to_string(map[:last_build_date])},
      {dgettext("frontend", "New feed URL"), map[:new_feed_url]},
      {dgettext("frontend", "Generator"), get_in(map, [:feed, :feed_generator])},
      {dgettext("frontend", "Hub"), get_in(map, [:feed, :hub_link_url])}
    ]
  end

  # [{label, count}] over all episodes the parser found.
  defp episode_summary(map) do
    episodes = map |> Map.get(:episodes, %{}) |> Map.values()

    for {label, key} <- [
          {dgettext("frontend", "with audio or video (enclosure)"), :enclosures},
          {dgettext("frontend", "with a publishing date"), :publishing_date},
          {dgettext("frontend", "with a duration"), :duration},
          {dgettext("frontend", "with artwork"), :image_url},
          {dgettext("frontend", "with show notes"), :shownotes},
          {dgettext("frontend", "with chapters (Podlove Simple Chapters in the feed)"),
           :chapters},
          {dgettext("frontend", "with persons"), :contributors}
        ],
        do: {label, Enum.count(episodes, &(&1[key] not in [nil, "", %{}, []]))}
  end

  defp episode_count(map), do: map_size(Map.get(map, :episodes, %{}))

  defp shorten(nil, _length), do: nil

  defp shorten(text, length) do
    if String.length(text) > length, do: String.slice(text, 0, length) <> " …", else: text
  end

  defp owner(%{name: name, email: email}) when is_binary(email), do: "#{name} <#{email}>"
  defp owner(%{name: name}), do: name
  defp owner(_owner), do: nil

  defp category(%{parent: nil, title: title}), do: title
  defp category(%{parent: parent, title: title}), do: "#{parent} › #{title}"

  defp person(%{name: name, role: role}) when is_binary(role), do: "#{name} (#{role})"
  defp person(%{name: name}), do: name

  defp joined(nil, _fun), do: nil
  defp joined(map, _fun) when map_size(map) == 0, do: nil
  defp joined(map, fun), do: map |> Map.values() |> Enum.map_join(", ", fun)

  defp yes_no(true), do: dgettext("frontend", "yes")
  defp yes_no(false), do: dgettext("frontend", "no")
  defp yes_no(_value), do: nil

  # The rule sets in the library's order, e.g. [:rss2, :apple, :podcasting20].
  defp standards, do: CheckMyFeed.Rules.all() |> Enum.map(& &1.standard) |> Enum.uniq()

  # Findings and rules both carry their rule set in `standard`.
  defp visible(things, selected), do: Enum.filter(things, &(&1.standard in selected))

  # [{severity, [{rule, [detail]}]}], most severe first.
  defp grouped(findings) do
    by_severity = Enum.group_by(findings, & &1.severity)

    for severity <- @severities, group = by_severity[severity] do
      rules =
        group
        |> Enum.group_by(& &1.rule_id)
        |> Enum.map(fn {_rule_id, [first | _] = rule_findings} ->
          {first, Enum.map(rule_findings, & &1.detail)}
        end)

      {severity, rules}
    end
  end

  defp severity_name(:error), do: dgettext("frontend", "Errors")
  defp severity_name(:warning), do: dgettext("frontend", "Warnings")
  defp severity_name(:info), do: dgettext("frontend", "Notes")

  # One colour per rule set, none of them looking like a severity.
  defp standard_color(:rss2), do: "bittersweet"
  defp standard_color(:apple), do: "lavender"
  defp standard_color(:podcasting20), do: "blue-jeans"
  defp standard_color(_standard), do: "gray"

  def render(assigns) do
    ~H"""
    <div class="m-4 max-w-4xl">
      <h1 class="text-3xl">{dgettext("frontend", "Feed check")}</h1>
      <p class="mt-2">
        <.link navigate={"/podcasts/#{@podcast.id}"} class="underline hover:text-primary">
          {@podcast.title}
        </.link>
      </p>
      <p :if={@feed_url} class="text-sm text-base-content/70 break-all">
        {dgettext("frontend", "Freshly downloaded from %{url}", url: @feed_url)}
      </p>

      <form
        :if={!@check_error}
        id="standards-form"
        phx-change="select_standards"
        class="mt-4 flex flex-wrap gap-4"
      >
        <input type="hidden" name="standards[]" value="" />
        <label :for={standard <- @standards} class="flex items-center gap-1 cursor-pointer">
          <input
            type="checkbox"
            name="standards[]"
            value={standard}
            checked={standard in @selected}
            class="checkbox checkbox-sm"
          />
          <Pill.render type={standard_color(standard)}>
            {CheckMyFeed.standard_name(standard)}
          </Pill.render>
        </label>
      </form>

      <p :if={@status == :running} class="mt-4">
        {dgettext("frontend", "Downloading and checking the feed ...")}
      </p>
      <p :if={@status == :failed} class="mt-4 text-error">{@error}</p>
      <div :if={@status == :done and !@check_error and @reads} class="mt-4">
        <p :if={@probe_status == :idle} class="text-sm text-base-content/70">
          {dgettext(
            "frontend",
            "So far only the feed text was checked. Probing downloads the artwork and asks for the media files of the newest 10 episodes."
          )}
        </p>
        <p :if={@probe_status == :done} class="text-sm text-base-content/70">
          {dgettext(
            "frontend",
            "The artwork and the media files of the newest 10 episodes were probed; their results are part of the report below."
          )}
        </p>
        <p :if={@probe_status == :failed} class="text-sm text-error">
          {dgettext("frontend", "Probing failed unexpectedly.")}
        </p>
        <p :if={@audio_status == :idle} class="text-sm text-base-content/70">
          {dgettext(
            "frontend",
            "Probing the audio reads the first megabyte of the newest 3 episodes' media files."
          )}
        </p>
        <p :if={@audio_status == :done} class="text-sm text-base-content/70">
          {dgettext(
            "frontend",
            "The audio of the newest 3 episodes was probed on its first megabyte; loudness and peak refer to that part only."
          )}
        </p>
        <p :if={@audio_status == :failed} class="text-sm text-error">
          {dgettext("frontend", "Probing the audio failed unexpectedly.")}
        </p>
        <button
          phx-click="probe"
          disabled={@probe_status == :running}
          class="mt-2 btn btn-outline btn-info btn-sm disabled:opacity-50"
        >
          {if @probe_status == :running,
            do: dgettext("frontend", "Probing ..."),
            else: dgettext("frontend", "Probe artwork and episodes")}
        </button>
        <button
          phx-click="probe_audio"
          disabled={@audio_status == :running}
          class="mt-2 btn btn-outline btn-info btn-sm disabled:opacity-50"
        >
          {if @audio_status == :running,
            do: dgettext("frontend", "Probing audio ..."),
            else: dgettext("frontend", "Probe audio")}
        </button>
      </div>

      <p :if={@status == :done and @check_error} class="mt-4 text-error">{@check_error}</p>
      <p :if={@status == :done and !@check_error and @selected == []} class="mt-4">
        {dgettext("frontend", "No rule set selected.")}
      </p>
      <p
        :if={
          @status == :done and !@check_error and @selected != [] and
            visible(@findings ++ @probe_findings ++ @audio_findings, @selected) == []
        }
        class="mt-4"
      >
        {dgettext("frontend", "No problems found.")}
      </p>

      <div
        :for={
          {severity, rules} <-
            grouped(visible(@findings ++ @probe_findings ++ @audio_findings, @selected))
        }
        :if={@status == :done}
        class="mt-6"
      >
        <h2 class="text-xl font-bold">{severity_name(severity)}</h2>
        <div :for={{finding, details} <- rules} class="mt-3">
          <p>
            <Pill.render type={standard_color(finding.standard)}>
              {CheckMyFeed.standard_name(finding.standard)}
            </Pill.render>
            {finding.description}
            <span class="text-sm text-base-content/70">
              ({finding.rule_id}, <a
                href={finding.spec_url}
                target="_blank"
                class="underline hover:text-primary"
              >
                {dgettext("frontend", "spec")}
              </a>)
            </span>
          </p>
          <ul class="list-disc ml-6">
            <li :for={detail <- details}>{detail}</li>
          </ul>
        </div>
      </div>

      <div
        :if={@status == :done and visible(@passed ++ @probe_passed ++ @audio_passed, @selected) != []}
        class="mt-6"
      >
        <h2 class="text-xl font-bold">{dgettext("frontend", "Passed")}</h2>
        <ul class="mt-3 list-disc ml-6">
          <li :for={rule <- visible(@passed ++ @probe_passed ++ @audio_passed, @selected)}>
            <Pill.render type={standard_color(rule.standard)}>
              {CheckMyFeed.standard_name(rule.standard)}
            </Pill.render>
            {rule.description}
            <span class="text-sm text-base-content/70">({rule.id})</span>
          </li>
        </ul>
      </div>

      <details
        :if={
          @status == :done and
            visible(@not_applicable ++ @probe_not_applicable ++ @audio_not_applicable, @selected) !=
              []
        }
        class="mt-6"
      >
        <summary class="text-xl font-bold cursor-pointer">
          {dgettext("frontend", "Not applicable (%{count})",
            count:
              length(
                visible(@not_applicable ++ @probe_not_applicable ++ @audio_not_applicable, @selected)
              )
          )}
        </summary>
        <p class="mt-2 text-sm text-base-content/70">
          {dgettext(
            "frontend",
            "The feed has nothing for these rules to check, e.g. an optional tag it doesn't use."
          )}
        </p>
        <ul class="mt-3 list-disc ml-6">
          <li :for={
            rule <-
              visible(@not_applicable ++ @probe_not_applicable ++ @audio_not_applicable, @selected)
          }>
            <Pill.render type={standard_color(rule.standard)}>
              {CheckMyFeed.standard_name(rule.standard)}
            </Pill.render>
            {rule.description}
            <span class="text-sm text-base-content/70">({rule.id})</span>
          </li>
        </ul>
      </details>

      <details :if={@status == :done and @leniency} open class="mt-6">
        <summary class="text-xl font-bold cursor-pointer">
          {dgettext("frontend", "Panoptikum reads this anyway")}
        </summary>
        <p class="mt-2 text-sm text-base-content/70">
          {dgettext(
            "frontend",
            "Not standard, but Panoptikum copes with it. Other podcast apps may not, so it's worth fixing in the feed."
          )}
        </p>
        <p :if={@leniency.xml == [] and @leniency.dates == []} class="mt-3">
          {dgettext("frontend", "Nothing: the feed needs none of Panoptikum's repairs.")}
        </p>
        <div :for={repair <- @leniency.xml} class="mt-3">
          <p>
            {repair.label} <span class="text-sm text-base-content/70">({repair.count}×)</span>
          </p>
          <ul class="list-disc ml-6">
            <li :for={example <- repair.examples}><code class="break-all">{example}</code></li>
          </ul>
        </div>
        <div :if={@leniency.dates != []} class="mt-3">
          <p>
            {dgettext(
              "frontend",
              "Dates in other formats than RFC 822 (such as \"Sat, 01 Apr 2023 19:00:00 GMT\"):"
            )}
          </p>
          <ul class="list-disc ml-6">
            <li :for={group <- @leniency.dates}>{date_line(group)}</li>
          </ul>
        </div>
      </details>

      <details :if={@status == :done and @reads} open class="mt-6">
        <summary class="text-xl font-bold cursor-pointer">
          {dgettext("frontend", "What Panoptikum reads from your feed")}
        </summary>
        <p class="mt-2 text-sm text-base-content/70">
          {dgettext(
            "frontend",
            "This is what Panoptikum takes from the feed and shows of the show. Its parser is more lenient than the rules above."
          )}
        </p>
        <table class="mt-3 table table-sm">
          <tbody>
            <tr :for={{label, value} <- channel_rows(@reads)}>
              <th class="align-top whitespace-nowrap">{label}</th>
              <td class="wrap-break-word">{value || "—"}</td>
            </tr>
          </tbody>
        </table>
        <p class="mt-3">
          {dgettext("frontend", "%{count} episodes, of them:", count: episode_count(@reads))}
        </p>
        <ul class="list-disc ml-6">
          <li :for={{label, count} <- episode_summary(@reads)}>{count} {label}</li>
        </ul>
      </details>

      <button
        phx-click="recheck"
        disabled={@status == :running}
        class="mt-6 btn btn-outline btn-info btn-sm disabled:opacity-50"
      >
        {if @status == :running,
          do: dgettext("frontend", "Checking ..."),
          else: dgettext("frontend", "Check again")}
      </button>
    </div>
    """
  end
end
