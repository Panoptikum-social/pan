defmodule PanWeb.Live.Moderation.Moderate do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.Moderation

  def mount(%{"id" => id}, session, socket) do
    moderation = Moderation.get_by_catagory_id_and_user_id(id, session["user_id"])

    if moderation do
      {:ok, assign(socket, category: moderation.category) }
    else
      {:ok, assign(socket, error: "This is not one of your moderations")}
    end
  end

  def render(assigns) do
    ~F"""
    <div class="m-4">
      <h1 class="text-2xl">
        Moderating {@category.title}
      </h1>
    </div>
    """
  end
end
