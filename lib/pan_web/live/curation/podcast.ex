defmodule PanWeb.Live.Curation.Podcast do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Community, Curation, Podcast}
  alias PanWeb.Component.{CurationGrade, OvertypeField}
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => id, "podcast_id" => podcast_id}, _session, socket) do
    community = Community.get_by_id(id)
    podcast_id = String.to_integer(podcast_id)
    permissions = Curation.permissions(socket.assigns.current_user_id, community.id)
    category_podcast = Curation.category_podcast(community, podcast_id)

    if permissions.read && category_podcast do
      {:ok,
       socket
       |> assign(
         community: community,
         podcast: Podcast.get_by_id(podcast_id),
         permissions: permissions,
         open: category_podcast.open_for_curation
       )
       |> fetch()}
    else
      {:ok,
       socket
       |> put_flash(:error, "This podcast is not up for curation in this community.")
       |> redirect(to: Routes.curation_frontend_path(socket, :index))}
    end
  end

  defp fetch(%{assigns: %{community: community, podcast: podcast} = assigns} = socket) do
    mine = Curation.mine(community.id, podcast.id, assigns.current_user_id)

    assign(socket,
      curations: Curation.for_podcast(community.id, podcast.id),
      mine: mine,
      form: to_form(Curation.changeset(mine))
    )
  end

  # Curators write only while the podcast is open, checked again on saving in
  # case it was marked done in the meantime.
  def handle_event("save", %{"curation" => params}, %{assigns: assigns} = socket) do
    category_podcast = Curation.category_podcast(assigns.community, assigns.podcast.id)
    open = category_podcast && category_podcast.open_for_curation

    cond do
      !(assigns.permissions.curate && open) ->
        {:noreply,
         socket
         |> assign(open: open)
         |> put_flash(:error, "This podcast is no longer open for curation.")}

      match?({:ok, _}, Curation.save(assigns.mine, params)) ->
        {:noreply, socket |> put_flash(:info, "Curation saved.") |> fetch()}

      true ->
        {:noreply, put_flash(socket, :error, "Saving failed, please choose a grade.")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="m-4 max-w-4xl">
      <.link
        navigate={Routes.curation_frontend_path(@socket, :community, @community)}
        class="text-link hover:text-link-dark text-sm"
      >
        ← {@community.title}
      </.link>

      <h1 class="text-3xl">
        <.link
          href={Routes.podcast_frontend_path(@socket, :show, @podcast)}
          class="text-link hover:text-link-dark"
        >
          {@podcast.title}
        </.link>
      </h1>
      <p :if={!@open} class="my-2">Curation of this podcast is done.</p>

      <div
        :for={curation <- @curations}
        class="my-4 rounded-box border border-base-content/20 bg-base-300 p-4"
      >
        <div class="flex items-center gap-2">
          <CurationGrade.badge grade={curation.grade} />
          <span class="font-semibold">
            {if curation.user, do: curation.user.name, else: "former curator"}
          </span>
          <span class="text-xs text-gray-dark">
            {Calendar.strftime(curation.updated_at, "%Y-%m-%d %H:%M")}
          </span>
        </div>
        <div class="prose mt-2">{markdown(curation.text)}</div>
      </div>

      <p :if={@curations == []} class="my-4">No curations yet.</p>

      <.form
        :if={@permissions.curate && @open}
        for={@form}
        id="curation-form"
        phx-submit="save"
        class="my-6"
      >
        <h2 class="text-xl">My curation</h2>
        <.input
          type="select"
          field={@form[:grade]}
          label="Grade"
          prompt="Choose a grade"
          options={Enum.map(Curation.grades(), &{Curation.grade_label(&1), &1})}
        />
        <OvertypeField.render field={@form[:text]} label="Text (Markdown)" />
        <.button class="btn btn-primary">Save</.button>
      </.form>
    </div>
    """
  end
end
