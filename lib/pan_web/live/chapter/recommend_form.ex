defmodule PanWeb.Live.Chapter.RecommendForm do
  use PanWeb, :live_component
  import PanWeb.CoreComponents
  alias PanWeb.Endpoint
  import PanWeb.Router.Helpers

  def mount(socket) do
    {:ok, assign(socket, remaining: 255)}
  end

  def handle_event("on-change", %{"value" => value}, socket) do
    {:noreply, assign(socket, remaining: 255 - String.length(value))}
  end

  def render(assigns) do
    ~H"""
    <div class="col-start-2 col-span-2" id={"chapter-#{@id}"}>
      <.form for={@changeset}
             :let={f}
             class="flex space-x-2 items-center"
             action={recommendation_frontend_path(Endpoint, :create)}>
        <.input phx-keyup="on-change"
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
