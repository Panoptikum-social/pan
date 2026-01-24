defmodule PanWeb.Live.Chapter.RecommendForm do
  use Surface.LiveComponent
  alias PanWeb.Endpoint
  use PanWeb, :html
  import PanWeb.Router.Helpers

  prop(current_user_id, :integer, required: true)
  prop(changeset, :map, required: true)
  prop(chapter, :map, required: true)
  prop(remaining, :integer, default: 255)

  def handle_event("on-change", %{"value" => value}, socket) do
    {:noreply, assign(socket, remaining: 255 - String.length(value))}
  end

  def render(assigns) do
    ~F"""
    <div class="col-start-2 col-span-2" id={"chapter-#{@id}"} >
      <.form for={@changeset}
        :let={f}
            class="flex space-x-2 items-center"
            action={recommendation_frontend_path(Endpoint, :create)}>
        <.input :on-keyup="on-change"
                field={f[:comment]} label="Your recommendation"
                id={"text-#{@id}"}
                size="100" maxlength="255"
                class="max-w-full input" />
        <span id={"remaining-chapter-#{@chapter.id}"}>{@remaining}</span>
        <.input type="hidden" field={f[:chapter_id]} value={@chapter.id} />
        <.button type="submit"
                 class="py-2 px-4 rounded-lg font-medium text-white bg-aqua hover:bg-aqua-light">Recommend</.button>
      </.form>
    </div>
    """
  end
end
