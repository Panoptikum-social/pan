defmodule PanWeb.Live.Pad.Show do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin

  alias Pan.Repo
  alias PanWeb.{Community, Pad}
  alias PanWeb.Component.Panel

  # For now the stored markdown, read only; the live editor follows. Visitors
  # and non-followers get the same "not found" as for a pad that doesn't
  # exist, so they can't tell which pads there are.
  def mount(%{"id" => community_id, "slug" => slug}, _session, socket) do
    with %Community{} = community <- Community.find_by_id(community_id),
         %{read: true} = permissions <-
           Pad.permissions(socket.assigns.current_user_id, community.id),
         %Pad{} = pad <- Pad.get_by_slug(community.id, slug) do
      {:ok,
       assign(socket,
         community: community,
         pad: pad,
         permissions: permissions,
         rename_form: to_form(Pad.changeset(pad), as: :pad),
         page_title: pad.title <> " (Pad, " <> community.title <> ")"
       )}
    else
      _ -> {:ok, assign(socket, error: "not_found", page_title: "Pad not found")}
    end
  end

  def handle_event(event, params, socket) do
    # the permission is checked again on every event, a follow or moderation
    # may have ended since the page was opened
    %{community: community, pad: pad, current_user_id: user_id} = socket.assigns

    if Pad.permissions(user_id, community.id).manage do
      manage(event, params, Repo.get!(Pad, pad.id), socket)
    else
      {:noreply, put_flash(socket, :error, "Only moderators of this community can do that.")}
    end
  end

  defp manage("toggle_read_only", _params, pad, socket) do
    pad = pad |> Pad.read_only_changeset(!pad.read_only) |> Repo.update!()
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

    {:noreply,
     socket
     |> put_flash(:info, "Pad \"#{pad.title}\" deleted.")
     |> push_navigate(to: community_frontend_path(socket, :show, socket.assigns.community.id))}
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

        <div :if={@pad.markdown != ""} class="prose max-w-none mt-4">
          {markdown(@pad.markdown)}
        </div>
        <p :if={@pad.markdown == ""} class="mt-4 text-gray-dark">This pad is still empty.</p>

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
