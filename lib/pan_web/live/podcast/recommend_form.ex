defmodule PanWeb.Live.Podcast.RecommendForm do
  use Surface.Component
  alias Surface.Components.Form
  alias Surface.Components.Form.{TextInput, HiddenInput}
  alias PanWeb.Endpoint
  alias PanWeb.Surface.Submit
  import PanWeb.Router.Helpers

  prop(current_user_id, :integer, required: true)
  prop(changeset, :map, required: true)
  prop(podcast, :map, required: true)

  def render(assigns) do
    ~F"""
      {#if @current_user_id}
        <Form for={@changeset}
              class="m-4"
              action={recommendation_frontend_path(Endpoint, :create)}>
          <TextInput field={:comment}
                     opts={size: 100, maxlength: 255, placeholder: "Your recommendation"} class="max-w-full" />
            <p class="help-block text-muted"><span id='remaining'>255</span> characters left</p>
          <HiddenInput field={:podcast_id } value={@podcast.id} />
          <Submit label={"Recommend"} />
        </Form>

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
