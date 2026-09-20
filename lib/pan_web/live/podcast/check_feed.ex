defmodule PanWeb.Live.Podcast.CheckFeed do
  use PanWeb, :live_view
  on_mount PanWeb.Live.Auth

  alias Pan.Parser.{Download, Feed}
  alias PanWeb.Podcast

  @severities [:error, :warning, :info]

  def mount(%{"id" => id}, _session, socket) do
    podcast = Pan.Repo.get(Podcast, id)

    if is_nil(podcast) or podcast.blocked == true do
      {:ok, push_navigate(socket, to: "/podcasts")}
    else
      socket =
        assign(socket,
          podcast: podcast,
          page_title: "Feed check for #{podcast.title}",
          status: :running,
          feed_url: nil,
          findings: [],
          passed: [],
          error: nil
        )

      {:ok, if(connected?(socket), do: start_check(socket), else: socket)}
    end
  end

  def handle_event("recheck", _, socket), do: {:noreply, start_check(socket)}

  def handle_async(:check, {:ok, {:ok, feed_url, report}}, socket) do
    {:noreply,
     assign(socket,
       status: :done,
       feed_url: feed_url,
       findings: report.findings,
       passed: report.passed
     )}
  end

  def handle_async(:check, {:ok, {:error, message}}, socket) do
    {:noreply, assign(socket, status: :failed, error: message)}
  end

  def handle_async(:check, {:exit, _reason}, socket) do
    {:noreply, assign(socket, status: :failed, error: "The check crashed unexpectedly.")}
  end

  defp start_check(socket) do
    podcast_id = socket.assigns.podcast.id

    socket
    |> assign(status: :running, findings: [], passed: [], error: nil)
    |> start_async(:check, fn -> run_check(podcast_id) end)
  end

  defp run_check(podcast_id) do
    with {:ok, feed} <- Feed.get_by_podcast_id(podcast_id),
         url = String.trim(feed.self_link_url),
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           Download.get(url, follow_redirect: true),
         {:ok, report} <- CheckMyFeed.check(body) do
      {:ok, url, report}
    else
      {:error, "not found"} ->
        {:error, "This podcast has no feed."}

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "The feed server answered with HTTP #{code}."}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "The feed could not be downloaded: #{inspect(reason)}"}

      {:error, {:invalid_xml, reason}} ->
        {:error, "The feed is not well-formed XML: #{inspect(reason)}"}

      other ->
        {:error, "The feed could not be checked: #{inspect(other)}"}
    end
  end

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

  def render(assigns) do
    ~H"""
    <div class="m-4 max-w-4xl">
      <h1 class="text-3xl">Feed check</h1>
      <p class="mt-2">
        <.link navigate={"/podcasts/#{@podcast.id}"} class="text-link hover:text-link-dark">
          {@podcast.title}
        </.link>
      </p>
      <p :if={@feed_url} class="text-sm text-gray-dark break-all">
        Freshly downloaded from {@feed_url}
      </p>

      <p :if={@status == :running} class="mt-4">Downloading and checking the feed ...</p>
      <p :if={@status == :failed} class="mt-4 text-danger">{@error}</p>
      <p :if={@status == :done and @findings == []} class="mt-4">No problems found.</p>

      <div :for={{severity, rules} <- grouped(@findings)} :if={@status == :done} class="mt-6">
        <h2 class="text-xl font-bold">{severity |> Atom.to_string() |> String.capitalize()}</h2>
        <div :for={{finding, details} <- rules} class="mt-3">
          <p>
            {finding.description}
            <span class="text-sm text-gray-dark">
              ({finding.rule_id}, <a
                href={finding.spec_url}
                target="_blank"
                class="text-link hover:text-link-dark"
              >
                spec
              </a>)
            </span>
          </p>
          <ul class="list-disc ml-6">
            <li :for={detail <- details}>{detail}</li>
          </ul>
        </div>
      </div>

      <div :if={@status == :done and @passed != []} class="mt-6">
        <h2 class="text-xl font-bold">Passed</h2>
        <ul class="mt-3 list-disc ml-6">
          <li :for={rule <- @passed}>
            {rule.description}
            <span class="text-sm text-gray-dark">({rule.id})</span>
          </li>
        </ul>
      </div>

      <button
        phx-click="recheck"
        disabled={@status == :running}
        class="mt-6 border border-gray-darker rounded bg-info hover:bg-info-light text-white px-2 py-1
               disabled:opacity-50"
      >
        {if @status == :running, do: "Checking ...", else: "Check again"}
      </button>
    </div>
    """
  end
end
