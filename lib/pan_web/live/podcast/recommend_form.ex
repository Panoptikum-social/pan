defmodule PanWeb.Live.Podcast.RecommendForm do
  use Surface.Component
  alias Surface.Components.Form
  alias Surface.Components.Form.TextInput
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
            action={recommendation_frontend_path(Endpoint, :create)}>
        <TextInput field={:comment}
                  opts={maxlength: 255, placeholder: "Your recommendation"} />
          <p class="help-block text-muted"><span id='remaining'>255</span> characters left</p>
        <TextInput field={:podcast_id } value={@podcast.id} />
        <Submit label={"Recommend"} />
      </Form>
    {/if}

    <script>
      $('#recommendation_comment').keyup(function(){
          $("#remaining").html((255 - this.value.length));
      })
    </script>

    <br/>
  """
  end
end
