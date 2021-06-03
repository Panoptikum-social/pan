defmodule PanWeb.PodcastView do
  use Pan.Web, :view
  alias PanWeb.Endpoint

  def render("datatable.json", %{
        podcasts: podcasts,
        draw: draw,
        records_total: records_total,
        records_filtered: records_filtered
      }) do
    %{
      draw: draw,
      recordsTotal: records_total,
      recordsFiltered: records_filtered,
      data: Enum.map(podcasts, &podcast_json/1)
    }
  end

  def render("datatable_stale.json", %{
        podcasts: podcasts,
        draw: draw,
        records_total: records_total,
        records_filtered: records_filtered
      }) do
    %{
      draw: draw,
      recordsTotal: records_total,
      recordsFiltered: records_filtered,
      data: Enum.map(podcasts, &podcast_stale_json/1)
    }
  end

  def podcast_json(podcast) do
    %{
      id: podcast.id,
      title: podcast.title,
      update_paused: podcast.update_paused,
      updated_at: format_for_vienna(podcast.updated_at),
      update_intervall: podcast.update_intervall,
      failure_count: podcast.failure_count,
      next_update: format_for_vienna(podcast.next_update),
      website: String.slice(podcast.website, 0, 100),
      episodes_count: podcast.episodes_count,
      actions: podcast_actions(podcast, &podcast_path/3)
    }
  end

  def podcast_stale_json(podcast) do
    %{
      id: podcast.id,
      title: podcast.title,
      update_paused: podcast.update_paused,
      updated_at: format_for_vienna(podcast.updated_at),
      update_intervall: podcast.update_intervall,
      failure_count: podcast.failure_count,
      next_update: format_for_vienna(podcast.next_update),
      feed_url: podcast.feed_url,
      actions: podcast_actions(podcast, &podcast_path/3)
    }
  end

  def podcast_actions(record, path) do
    [
      "<nobr>",
      link("Show",
        to: path.(Endpoint, :show, record.id),
        class: "btn btn-default btn-xs"
      ),
      " ",
      link("Edit",
        to: path.(Endpoint, :edit, record.id),
        class: "btn btn-warning btn-xs"
      ),
      " ",
      link("Pause",
        to: path.(Endpoint, :pause, record.id),
        class: "btn btn-info btn-xs"
      ),
      "</nobr>"
    ]
    |> Enum.map(&my_safe_to_string/1)
    |> Enum.join()
  end

  def format_for_vienna(datetime) do
    if datetime do
      datetime =
        datetime
        |> DateTime.from_naive!("Etc/UTC")
        |> Timex.Timezone.convert("Europe/Vienna")
        |> Timex.format!("{YYYY}-{0M}-{0D} {h24}:{m}:{s}")

      "<nobr>#{datetime}</nobr>"
    else
      "no datetime"
    end
  end
end
