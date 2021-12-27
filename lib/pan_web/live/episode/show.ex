defmodule PanWeb.Live.Episode.Show do
  use Surface.LiveView
  alias PanWeb.{Episode, Recommendation}
  alias PanWeb.Live.Episode.Header

  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     assign(socket,
       episode: Episode.get_by_id_for_episode_show(id),
       recommendation_changeset: Recommendation.changeset(%Recommendation{})
     )}
  end

  def render(assigns) do
    ~F"""
    {#if @episode.podcast.blocked}
      This episode may not be published here, sorry.
    {#else}
      <Header episode={@episode}, current_user_id={@current_user_id} />

      <%= render "_recommendations.html", episode: @episode,
                                          current_user: @current_user,
                                          changeset: @changeset,
                                          conn: @conn %>

      <div class="row">
        <div class="col-md-6" id="player">
          <%= case major_mimetype(@episode) do %>
            <% "video" -> %>
              <video width="640" height="480" controls>
                <%= for enclosure <- @episode.enclosures do %>
                  <source src={enclosure.url}>
                <% end %>
                Your browser does not support the video tag.
              </video>
            <% _ -> %>
              <%= render "_podlove_webplayer4.html", episode: @episode,
                                                    conn: @conn %>
          <% end %>
        </div>

        <div class="col-md-6" id="shownotes">
          <%= if @episode.shownotes do %>
            <h3>Shownotes</h3>
            <p><%= raw(@episode.shownotes) %></p>
          <% end %>
        </div>
      </div>

      <%= render "_chapters.html", episode: @episode,
                                  current_user: @current_user,
                                  changeset: @changeset,
                                  player: @player,
                                  conn: @conn %>
    <% end %>
    """
  end
end
