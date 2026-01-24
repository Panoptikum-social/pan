defmodule PanWeb.Live.Podcast.RecommendForm do
  use Surface.Component
  alias PanWeb.Endpoint
  use PanWeb, :html
  import PanWeb.Router.Helpers

  prop(current_user_id, :integer, required: true)
  prop(changeset, :map, required: true)
  prop(podcast, :map, required: true)

  def render(assigns) do
    ~F"""
      {#if @current_user_id}
        <.form for={@changeset}
               :let={f}
               class="m-4"
               action={recommendation_frontend_path(Endpoint, :create)}>
          <.input field={f[:comment]} size="100" maxlength="255" label="Your recommendation"
                  class="max-w-full input" />
            <p class="help-block text-muted"><span id='remaining'>255</span> characters left</p>
          <.input type="hidden" field={f[:podcast_id] } value={@podcast.id} />
          <.button type="submit" class="btn btn-primary">Recommend</.button>
        </.form>

        <script>
          document.getElementById('recommendation_comment').onkeyup = function(){
              document.getElementById("remaining").innerHTML = 255 - this.value.length;
          }
        </script>
        {/if}
      <br/>
    """
  end
end
