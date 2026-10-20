defmodule PanWeb.Live.Pad.Show do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin

  alias Pan.Repo
  alias PanWeb.{Community, Pad, PadChannel, PadServer, PadSnapshot, User, UserSocket}
  alias PanWeb.Component.Panel
  alias Phoenix.LiveView.JS

  # The editor (PadEditor hook, assets/js/pad_editor.js) syncs through
  # PanWeb.PadChannel. Visitors and non-followers get the same "not found" as
  # for a pad that doesn't exist, so they can't tell which pads there are.
  def mount(%{"id" => community_id, "slug" => slug}, _session, socket) do
    with %Community{} = community <- Community.find_by_id(community_id),
         %{read: true} = permissions <-
           Pad.permissions(socket.assigns.current_user_id, community.id),
         %Pad{} = pad <- Pad.get_by_slug(community.id, slug) do
      if connected?(socket) do
        Phoenix.PubSub.subscribe(:pan_pubsub, PadServer.snapshots_topic(pad.id))
      end

      {:ok,
       assign(socket,
         community: community,
         pad: pad,
         permissions: permissions,
         rename_form: to_form(Pad.changeset(pad), as: :pad),
         version_form: version_form(),
         snapshots: PadSnapshot.list_for(pad.id),
         shown_snapshot: nil,
         user_name: Repo.get!(User, socket.assigns.current_user_id).name,
         page_title: pad.title <> " (Pad, " <> community.title <> ")"
       )}
    else
      _ -> {:ok, assign(socket, error: "not_found", page_title: "Pad not found")}
    end
  end

  defp version_form, do: to_form(%{"note" => ""}, as: :version)

  # Versions are for every follower, managing only for moderators who follow.
  # The permission is checked again on every event, a follow or moderation
  # may have ended since the page was opened.
  @version_events ~w(save_version show_version restore_version)

  def handle_event(event, params, socket) when event in @version_events do
    %{community: community, pad: pad, current_user_id: user_id} = socket.assigns

    if Pad.permissions(user_id, community.id).read do
      version(event, params, Repo.get!(Pad, pad.id), socket)
    else
      {:noreply, put_flash(socket, :error, "Only followers of this community can do that.")}
    end
  end

  def handle_event(event, params, socket) do
    %{community: community, pad: pad, current_user_id: user_id} = socket.assigns

    if Pad.permissions(user_id, community.id).manage do
      manage(event, params, Repo.get!(Pad, pad.id), socket)
    else
      {:noreply, put_flash(socket, :error, "Only moderators of this community can do that.")}
    end
  end

  # the list itself is reloaded through PubSub, for everybody on the page
  defp version("save_version", %{"version" => %{"note" => note}}, pad, socket) do
    case PadServer.save_version(pad.id, socket.assigns.current_user_id, note) do
      {:ok, _snapshot} ->
        {:noreply,
         socket |> assign(version_form: version_form()) |> put_flash(:info, "Version saved.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, version_form: to_form(changeset, as: :version))}
    end
  end

  defp version("show_version", %{"id" => id}, pad, socket) do
    snapshot = Repo.get_by!(PadSnapshot, id: id, pad_id: pad.id)

    shown =
      if socket.assigns.shown_snapshot && socket.assigns.shown_snapshot.id == snapshot.id,
        do: nil,
        else: snapshot

    {:noreply, assign(socket, shown_snapshot: shown)}
  end

  defp version("restore_version", _params, %Pad{read_only: true}, socket) do
    {:noreply, put_flash(socket, :error, "This pad is read only.")}
  end

  defp version("restore_version", %{"id" => id}, pad, socket) do
    snapshot = Repo.get_by!(PadSnapshot, id: id, pad_id: pad.id)
    :ok = PadServer.restore(pad.id, snapshot.markdown)

    {:noreply,
     put_flash(socket, :info, "Version restored. Restoring an earlier version undoes it.")}
  end

  def handle_info(:snapshots_changed, socket) do
    {:noreply, assign(socket, snapshots: PadSnapshot.list_for(socket.assigns.pad.id))}
  end

  defp manage("toggle_read_only", _params, pad, socket) do
    pad = pad |> Pad.read_only_changeset(!pad.read_only) |> Repo.update!()
    PadChannel.broadcast_read_only(pad)
    {:noreply, assign(socket, pad: pad)}
  end

  defp manage("rename", %{"pad" => params}, pad, socket) do
    case pad |> Pad.changeset(params) |> Repo.update() do
      {:ok, pad} ->
        {:noreply,
         push_navigate(socket,
           to: pad_frontend_path(socket, :show, socket.assigns.community.id, pad.slug)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, rename_form: to_form(changeset, as: :pad))}
    end
  end

  defp manage("delete", _params, pad, socket) do
    Repo.delete!(pad)
    PadChannel.broadcast_deleted(pad)

    {:noreply,
     socket
     |> put_flash(:info, "Pad \"#{pad.title}\" deleted.")
     |> push_navigate(to: community_frontend_path(socket, :show, socket.assigns.community.id))}
  end

  defp snapshot_author(%{user_id: nil, note: nil}), do: "automatic"
  defp snapshot_author(%{user_name: nil}), do: "by a former user"
  defp snapshot_author(%{user_name: name}), do: "by " <> name

  # the same color for a user's cursor everywhere
  @cursor_colors ~w(#30bced #6eeb83 #ffbc42 #ee6352 #9ac2c9 #8acb88 #1be7ff #c45ab3)
  defp cursor_color(user_id), do: Enum.at(@cursor_colors, rem(user_id, length(@cursor_colors)))

  # below the md breakpoint only one pane is visible, switched by the tabs
  defp show_pane(pane) do
    other = if pane == "edit", do: "preview", else: "edit"

    JS.remove_class("max-md:hidden", to: "#pad-pane-#{pane}")
    |> JS.add_class("max-md:hidden", to: "#pad-pane-#{other}")
    |> JS.add_class("tab-active", to: "#pad-tab-#{pane}")
    |> JS.remove_class("tab-active", to: "#pad-tab-#{other}")
  end

  def render(%{error: "not_found"} = assigns) do
    ~H"""
    <div class="m-12">
      This pad could not be found. Pads can only be seen by followers of their community.
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <Panel.render purpose="episode" heading={@pad.title} class="m-4">
      <div aria-label="panel-body" class="p-4">
        <p class="text-sm">
          Pad of the community
          <.link
            navigate={community_frontend_path(@socket, :show, @community.id)}
            class="text-link hover:text-link-dark"
          >
            {@community.title}
          </.link>
          <span :if={@pad.read_only} class="badge badge-sm badge-ghost ml-2">read only</span>
        </p>

        <div role="tablist" class="tabs tabs-border mt-4 md:hidden">
          <button
            id="pad-tab-edit"
            role="tab"
            class="tab tab-active"
            phx-click={show_pane("edit")}
          >
            Edit
          </button>
          <button id="pad-tab-preview" role="tab" class="tab" phx-click={show_pane("preview")}>
            Preview
          </button>
        </div>

        <div
          id={"pad-editor-#{@pad.id}"}
          phx-hook="PadEditor"
          phx-update="ignore"
          data-pad-id={@pad.id}
          data-token={UserSocket.sign_token(@current_user_id)}
          data-text-name={PadServer.text_name()}
          data-read-only={to_string(@pad.read_only)}
          data-user-name={@user_name}
          data-user-color={cursor_color(@current_user_id)}
          data-community-url={community_frontend_path(@socket, :show, @community.id)}
          class="mt-4 grid gap-4 md:grid-cols-2"
        >
          <div
            id="pad-pane-edit"
            class="h-[70vh] flex flex-col border border-base-content/40 rounded bg-base-100"
          >
            <div
              data-toolbar
              class="flex flex-wrap items-center gap-0.5 border-b border-base-content/40 p-1"
            >
            </div>
            <div data-editor class="flex-1 min-h-0"></div>
          </div>
          <div
            id="pad-pane-preview"
            data-pane="preview"
            class="h-[70vh] overflow-y-auto border border-base-content/40 rounded bg-base-100 p-4 max-md:hidden"
          >
            <div data-preview class="prose max-w-none">
              {markdown(@pad.markdown, sourcepos: true)}
            </div>
          </div>
        </div>

        <div class="mt-8 border-t border-base-300 pt-4">
          <h3 class="text-lg font-semibold">Versions</h3>
          <p class="text-sm">
            A version is saved automatically 5 minutes after the last edit and when the
            last person leaves the pad, unless the text is unchanged.
          </p>

          <.form
            for={@version_form}
            id="save-version-form"
            phx-submit="save_version"
            class="flex items-start gap-2 mt-2"
          >
            <.input field={@version_form[:note]} placeholder="Note (optional)" />
            <.button class="btn btn-primary">Save version</.button>
          </.form>

          <p :if={@snapshots == []} class="text-sm mt-2">No versions yet.</p>

          <ul :if={@snapshots != []} id="pad-versions" class="mt-2 divide-y divide-base-300">
            <li :for={snapshot <- @snapshots} id={"pad-version-#{snapshot.id}"} class="py-2">
              <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-sm">
                <span class="font-mono">
                  {Calendar.strftime(snapshot.inserted_at, "%Y-%m-%d %H:%M")} UTC
                </span>
                <span>{snapshot_author(snapshot)}</span>
                <span :if={snapshot.note} class="italic">{snapshot.note}</span>
                <span class="ml-auto flex gap-2">
                  <button
                    phx-click="show_version"
                    phx-value-id={snapshot.id}
                    class="btn btn-ghost btn-xs"
                  >
                    {if @shown_snapshot && @shown_snapshot.id == snapshot.id,
                      do: "Hide",
                      else: "View"}
                  </button>
                  <button
                    :if={@shown_snapshot && @shown_snapshot.id == snapshot.id}
                    phx-click={JS.dispatch("pan:print", to: "#pad-version-content-#{snapshot.id}")}
                    class="btn btn-ghost btn-xs"
                  >
                    Print
                  </button>
                  <button
                    :if={!@pad.read_only}
                    phx-click="restore_version"
                    phx-value-id={snapshot.id}
                    data-confirm="Replace the current text with this version? Everybody editing sees it at once."
                    class="btn btn-primary btn-xs"
                  >
                    Restore
                  </button>
                </span>
              </div>
              <div
                :if={@shown_snapshot && @shown_snapshot.id == snapshot.id}
                id={"pad-version-content-#{snapshot.id}"}
                class="prose max-w-none mt-2 p-4 border border-base-content/40 rounded bg-base-100"
              >
                {markdown(@shown_snapshot.markdown)}
              </div>
            </li>
          </ul>
        </div>

        <div :if={@permissions.manage} class="mt-8 border-t border-base-300 pt-4">
          <h3 class="text-lg font-semibold">Manage this pad</h3>

          <div class="flex items-center gap-3 mt-2">
            <button id="toggle-read-only" phx-click="toggle_read_only" class="btn btn-primary btn-sm">
              {if @pad.read_only, do: "Make editable", else: "Make read only"}
            </button>
            <span class="text-sm">Read only freezes the pad for everybody, moderators included.</span>
          </div>

          <.form
            for={@rename_form}
            id="rename-pad-form"
            phx-submit="rename"
            class="flex items-start gap-2 mt-4"
          >
            <.input field={@rename_form[:title]} />
            <.button class="btn btn-primary">Rename</.button>
          </.form>
          <p class="text-sm">Renaming changes the pad's address, old links stop working.</p>

          <button
            id="delete-pad"
            phx-click="delete"
            data-confirm={"Delete the pad \"#{@pad.title}\" and all its saved versions?"}
            class="btn btn-error btn-sm mt-4"
          >
            Delete pad
          </button>
        </div>
      </div>
    </Panel.render>
    """
  end
end
