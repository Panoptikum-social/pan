defmodule PanWeb.Live.Admin.Podcast.New do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, "live_admin.html"},
    container: {:div, class: "flex-1 w-full"}

  alias PanWeb.Podcast
  alias PanWeb.Surface.Admin.{RecordForm, Column}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, podcast: %Podcast{})}
  end

  def handle_info({:redirect, %{path: path,
                                flash_type: flash_type,
                                message: message}}, socket) do
    {:noreply,
     socket
     |> put_flash(flash_type, message)
     |> push_redirect(to: path)}
  end

  def render(assigns) do
    ~H"""
    <RecordForm id="record_form"
                record={{ @podcast }}
                model={{ Podcast }}
                path_helper={{ :podcast_path }}>
      <Column field={{ :id }}
              type={{ :integer }} />
      <Column field={{ :title }} />
      <Column field={{ :website }} />
      <Column field={{ :description }}
              type={{ Ecto.EctoText }}/>
      <Column field={{ :summary }}
              type={{ Ecto.EctoText }}/>
      <Column field={{ :image_title }} />
      <Column field={{ :image_url }} />
      <Column field={{ :last_build_date }}
              type={{ :naive_datetime }} />
      <Column field={{ :payment_link_title }} />
      <Column field={{ :payment_link_url }} />
      <Column field={{ :explicit }}
              type={{ :boolean }} />
      <Column field={{ :blocked }}
              type={{ :boolean }} />
      <Column field={{ :update_paused }}
              type={{ :boolean }} />
      <Column field={{ :update_intervall }}
              type={{ :integer }} />
      <Column field={{ :next_update }}
              type={{ :naive_datetime }}/>
      <Column field={{ :retired }}
              type={{ :boolean }} />
      <Column field={{ :failure_count }}
              type={{ :integer }} />
      <Column field={{ :unique_identifier }}
              type={{ Ecto.UUID }}/>
      <Column field={{ :episodes_count }}
              type={{ :integer }} />
      <Column field={{ :followers_count }}
              type={{ :integer }} />
      <Column field={{ :likes_count }}
              type={{ :integer }} />
      <Column field={{ :subscriptions_count }}
              type={{ :integer }} />
      <Column field={{ :latest_episode_publishing_date }}
              type={{ :naive_datetime }} />
      <Column field={{ :publication_frequency }}
              type={{ :float }} />
      <Column field={{ :manually_updated_at }}
              type={{ :naive_datetime }} />
      <Column field={{ :elastic }}
              type={{ :boolean }} />
      <Column field={{ :thumbnailed }}
              type={{ :boolean }} />
      <Column field={{ :last_error_message }} />
      <Column field={{ :last_error_occured }}
              type={{ :naive_datetime }} />
    </RecordForm>
    """
  end
end
