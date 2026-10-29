defmodule PanWeb.Live.Podcast.RecommendForm do
  use PanWeb, :html
  alias PanWeb.Endpoint
  import PanWeb.Router.Helpers

  attr :current_user_id, :integer, required: true
  attr :changeset, :map, required: true
  attr :podcast, :map, required: true

  def render(assigns) do
    ~H"""
    <div :if={@current_user_id}>
      <.form
        :let={f}
        for={@changeset}
        class="m-4"
        action={recommendation_frontend_path(Endpoint, :create)}
      >
        <.input
          field={f[:comment]}
          size="100"
          maxlength="255"
          data-remaining-counter="remaining"
          label="Your recommendation"
          class="input w-full max-w-4xl"
        />
        <p class="text-sm text-base-content/70"><span id="remaining">255</span> characters left</p>
        <.input type="hidden" field={f[:podcast_id]} value={@podcast.id} />
        <.button type="submit" class="btn btn-primary">Recommend</.button>
      </.form>
    </div>
    <br />
    """
  end
end
