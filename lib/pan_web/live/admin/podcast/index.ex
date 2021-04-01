defmodule PanWeb.Live.Admin.Podcast.Index do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Podcast
  alias PanWeb.Surface.Admin.{Grid, Column}

  def render(assigns) do
    ~H"""
    <Grid id="podcasts_grid"
          heading="Listing Podcasts"
          path_helper={{ :podcast_path }}
          model={{ Podcast }}>
      <Column field={{ :id }}
              label="ID"
              type={{ :integer }} />
      <Column field={{ :title }}
              label="Title" />
      <Column field={{ :update_paused }}
              label="Update paused"
              type={{ :boolean }}/>
      <Column field={{ :updated_at }}
              label="Updated at"
              type={{ :datetime }} />
      <Column field={{ :update_intervall }}
              label="Update intervall"
              type={{ :integer }} />
      <Column field={{ :next_update }}
              label="Next Update"
              type={{ :datetime }}/>
      <Column field={{ :failure_count }}
              label="Failure count"
              type={{ :integer }}/>
      <Column field={{ :website }}
              label="Website" />
      <Column field={{ :episodes_count }}
              label="Episodes count"
              type={{ :integer }}/>
    </Grid>
    """
  end
end
