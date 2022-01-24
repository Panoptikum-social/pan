defmodule PanWeb.Live.Persona.Edit do
  use Surface.LiveView, container: {:div, class: "m-4"}
  on_mount PanWeb.Live.Auth

  alias PanWeb.{Manifestation, Persona, Endpoint, User}
  alias PanWeb.Surface.{TextField, EmailField, Submit}
  alias Surface.Components.Form
  import PanWeb.Router.Helpers
  import NaiveDateTime, only: [compare: 2, utc_now: 0]

  def mount(%{"id" => id}, _session, %{assigns: assigns} = socket) do
    manifestation = Manifestation.get_with_persona(assigns.current_user_id, id)

    case manifestation do
      nil ->
        render(socket.assigns, :not_allowed)

      manifestation ->
        {:ok,
         assign(socket,
           persona: manifestation.persona,
           current_user: User.get_by_id(assigns.current_user_id),
           changeset: Persona.changeset(manifestation.persona)
         )}
    end
  end

  def render(assigns, :not_allowed) do
    ~F"""
    """
  end

  defp pro(user) do
    user.pro_until != nil && compare(user.pro_until, utc_now()) == :gt
  end

  def render(assigns) do
    ~F"""
    <h2 class="text-2xl">Edit persona</h2>

    <Form for={@changeset}
          class="p-4 mb-4 flex flex-col items-start space-y-4"
          action={persona_frontend_path(Endpoint, :update, @persona)}>


        <div if={@changeset.action}
              class="empty:hidden p-4 border border-danger-dark bg-danger-light/50 rounded-xl mb-4">
          Oops, something went wrong! Please check the errors below.
        </div>

        <div :unless={pro(@current_user)}
              class="empty:hidden p-4 border border-info-dark bg-info-light/50 rounded-xl mb-4">
          <strong>Info!</strong> Fields grayed out can be updated with pro accounts only.
        </div>

        <Form.Field name={:pid}>
          <Form.Label>Pid</Form.Label>
          <Form.TextInput field={:pid}
                          opts={disabled: not pro(@current_user)} />
        </Form.Field>

        <TextField name={:name} />
        <TextField name={:uri} />
        <EmailField name={:email} />

        <Form.Field name={:fediverse_address}>
          <Form.Label>Fediverse address</Form.Label>
          <Form.TextInput field={:fediverse_address}
                          opts={placeholder: "@username@domain.social"} />
        </Form.Field>

        <Form.Field name={:image_url}>
          <Form.Label>Image url</Form.Label>
          <Form.TextInput field={:image_url}
                          opts={disabled: not pro(@current_user)} />
        </Form.Field>

        <Form.Field name={:image_title}>
          <Form.Label>Image title</Form.Label>
          <Form.TextInput field={:image_title}
                          opts={disabled: not pro(@current_user)} />
        </Form.Field>

        <Form.Field name={:description_header}>
          <Form.Label>Description heading</Form.Label>
          <Form.TextInput field={:description_header}
                          opts={disabled: not pro(@current_user)} />
        </Form.Field>

        <Form.Field name={:long_description}>
          <Form.Label>Description </Form.Label>
          <Form.TextInput field={:long_description}
                          opts={disabled: not pro(@current_user)} />
        </Form.Field>

        {#if pro(@current_user)}
          <script>
            var simplemde = new SimpleMDE({ element: document.getElementById("simplemde"),
                                            spellChecker: false })
          </script>
        {/if}

        <Submit />
      </Form>

      <a href={user_frontend_path(Endpoint, :my_profile)},
         class="text-link hover:text-link-dark">Back</a>
    """
  end
end
