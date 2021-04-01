defmodule PanWeb.Live.Admin.Databrowser.Index do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.{Grid}

  def mount(%{"resource" => resource}, _session, socket) do
    {:ok, assign(socket, resource: resource)}
  end

  def render(assigns) do
    ~H"""
    <Grid id="podcasts_grid"
          heading="Listing Podcasts"
          resource={{ String.to_atom(@resource) }}
          path_helper={{ :podcast_path }}>
      <Column :for={{ field <- Naming.index_fields(@resource) }}
              field={{ field }}
              label={{ Naming.title_from_field(field) }}
              type={{ Naming.type_of_field(@resource, field) }} />
    </Grid>
    """
  end
end
