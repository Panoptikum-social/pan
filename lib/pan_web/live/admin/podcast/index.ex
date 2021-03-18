defmodule PanWeb.Live.Admin.Podcast.Index do
  use Surface.LiveView
  alias PanWeb.Podcast
  alias PanWeb.Surface.Admin.Grid

  def mount(_params, _session, socket) do
    socket = assign(socket, options: %{})
    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    paginate_options =
      %{page: String.to_integer(params["page"] || "1"),
        per_page: String.to_integer(params["per_page"] || "10")}
    sort_options =
      %{sort_by: (params["sort_by"] || "id") |> String.to_atom(),
        sort_order: (params["sort_order"] || "asc") |> String.to_atom()}

    socket = assign(socket, options: Map.merge(paginate_options, sort_options))
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Grid id="podcasts_grid"
          heading="Listing Podcasts"
          resource={{ Podcast }}
          path_helper={{ :podcast_path }}>
      <Column field="id" label="ID" />
      <Column field="title" label="Title" />
      <Column field="update_paused" label="Update paused" />
      <Column field="updated_at" label="Updated at" />
      <Column field="update_intervall" label="Update intervall" />
      <Column field="next_update" label="Next Update" />
      <Column field="failure_count" label="Failure count" />
      <Column field="website" label="Website" />
      <Column field="episodes_count" label="Episodes count" />
    </Grid>
    """
  end
end
