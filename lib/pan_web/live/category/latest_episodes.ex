defmodule PanWeb.Live.Category.LatestEpisodes do
  use Phoenix.LiveView
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [icon: 1, truncate_string: 2]
  alias PanWeb.{Category, Podcast, Episode}

  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(page: 1, per_page: 10, category: Category.get_by_id_with_parent(id))
     |> fetch(), temporary_assigns: [latest_episodes: []]}
  end

  defp fetch(%{assigns: %{page: page, per_page: per_page, category: category}} = socket) do
    podcast_ids = Podcast.ids_by_category_id(category.id)

    assign(socket,
      latest_episodes: Episode.latest_episodes_by_podcast_ids(podcast_ids, page, per_page)
    )
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  def render(assigns) do
    ~H"""
    <div class="panel panel-warning">
      <div class="panel-heading">
        <%= @category.title %> -
        <a href={episode_frontend_path @socket, :index}>Latest Episodes</a>
        <span class="pull-right">
          <a href={episode_frontend_path @socket, :index}>more ...</a>
        </span>
      </div>
    </div>

    <div class="col-md-12">
      <table class="table table-condensed">
        <tbody id="latest_episodes" phx-update="append">
          <%= for episode <- @latest_episodes do %>
            <tr class="active" id={"episode-#{episode.id}"}>
              <td>
                <nobr>
                  <%= if episode.publishing_date do %>
                    <%= icon("calendar-heroicons-outline") %> <%= Timex.format!(episode.publishing_date, "{ISOdate}") %>
                  <% end %>
                </nobr> <br/>
                <%= if episode.duration do %>
                  <%= icon("clock-horoicons-outline") %> <%= episode.duration %>
                <% end %>
              </td>
              <td style="line-height: 200%;">
                <a href={episode_frontend_path @socket, :show, episode.id}>
                  <%= icon("headphones-lineawesome-solid") %> <%= truncate_string(episode.title, 80) %>
                </a>
                <br/>
                <a href={podcast_frontend_path @socket, :show, episode.podcast_id}>
                  <%= icon("podcast-lineawesome-solid")%> <%= episode.podcast.title %>
                </a>
              </td>
              <td>
                FIXME! author button
              </td>
            </tr>
            <%= if episode.subtitle do %>
              <tr id={"subtitle-#{episode.id}"}>
                <td colspan="3">
                  <%= icon("photograph-heroicons-outline") %> <%= episode.subtitle %>
                </td>
              </tr>
            <% end %>
            <tr id={"spacing-#{episode.id}"}> <td colspan="3"> &nbsp; </td> </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    """
  end
end
