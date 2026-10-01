defmodule PanWeb.Component.CuratorAssignment do
  use PanWeb, :html

  # Shared by the admin and the moderator curator pages; the LiveViews handle
  # the "assign" and "unassign" events and decide which communities are listed.
  attr :entries, :list, required: true

  def render(assigns) do
    ~H"""
    <table class="table table-sm">
      <thead>
        <tr>
          <th>Community</th>
          <th>Curators</th>
          <th>Assign curator</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={%{community: community, candidates: candidates} <- @entries}>
          <td>{community.title}</td>
          <td>
            <div :for={curator <- community.curators} class="flex items-center gap-2 py-1">
              {curator.username} ({curator.name})
              <button
                phx-click="unassign"
                phx-value-community_id={community.id}
                phx-value-user_id={curator.id}
                data-confirm={"Remove #{curator.username} as curator of #{community.title}?"}
                class="btn btn-warning btn-xs"
              >
                Remove
              </button>
            </div>
            <span :if={community.curators == []} class="text-sm">none</span>
          </td>
          <td>
            <form :if={candidates != []} phx-submit="assign" class="flex gap-2">
              <input type="hidden" name="community_id" value={community.id} />
              <select name="user_id" class="select select-bordered select-xs">
                <option :for={candidate <- candidates} value={candidate.id}>
                  {candidate.username} ({candidate.name})
                </option>
              </select>
              <button class="btn btn-primary btn-xs">Assign</button>
            </form>
            <span :if={candidates == []} class="text-sm">no further curators available</span>
          </td>
        </tr>
      </tbody>
    </table>

    <p :if={@entries == []} class="my-4">No communities.</p>
    """
  end
end
