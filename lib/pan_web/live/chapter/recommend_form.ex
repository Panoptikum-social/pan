defmodule PanWeb.Live.Chapter.RecommendForm do
  use Surface.Component
  alias Surface.Components.Form
  alias Surface.Components.Form.{TextInput, HiddenInput}
  alias PanWeb.Endpoint
  alias PanWeb.Surface.Submit
  import PanWeb.Router.Helpers

  prop(current_user_id, :integer, required: true)
  prop(changeset, :map, required: true)
  prop(chapter, :map, required: true)

  def render(assigns) do
    ~F"""
    {#if @current_user_id}
      <Form for={@changeset}
            class="col-start-2 col-span-2 flex space-x-2 items-center"
            action={recommendation_frontend_path(Endpoint, :create)}>
        <TextInput id={"chapter-comment-#{@chapter.id}"}
                   field={:comment}
                   opts={size: 100, maxlength: 255, placeholder: "Your recommendation"} />
        <span id="remaining-chapter-#{@chapter.id}"">255</span>
        <HiddenInput field={:chapter_id} value={@chapter.id} />
        <Submit label={"Recommend"}
                class="py-2 px-4 rounded-lg font-medium text-white bg-aqua hover:bg-aqua-light"/>
      </Form>

      <script>
        document.getElementById("chapter-comment-#{@chapter.id}").onkeyup = function(){
            document.getElementById("remaining-chapter-#{@chapter.id}").innerHTML = 255 - this.value.length;
        }
      </script>
    {/if}
    """
  end
end
