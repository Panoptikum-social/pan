defmodule PanWeb.Live.Chapter.RecommendForm do
  use Surface.LiveComponent
  alias Surface.Components.Form
  alias Surface.Components.Form.HiddenInput
  alias PanWeb.Endpoint
  alias PanWeb.Surface.Submit
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
    <div class="col-start-2 col-span-2">
      <Form for={@changeset}
            class="flex space-x-2 items-center"
            action={recommendation_frontend_path(Endpoint, :create)}>
        <input :on-keyup="on-change"
                maxlength="255"
                name="recommendation[comment]"
                placeholder="Your recommendation"
                size="100"
                type="text"
                class="max-w-full" />
        <span id={"remaining-chapter-#{@chapter.id}"}>{@remaining}</span>
        <HiddenInput field={:chapter_id} value={@chapter.id} />
        <Submit label={"Recommend"}
                class="py-2 px-4 rounded-lg font-medium text-white bg-aqua hover:bg-aqua-light"/>
      </Form>
    </div>
    """
  end
end
