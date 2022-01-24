defmodule PanWeb.Live.Persona.Edit do
  use Surface.LiveView, container: {:div, class: "m-4"}
  on_mount PanWeb.Live.Auth

  alias PanWeb.{Manifestation, Persona, Endpoint, User}
  alias PanWeb.Surface.{TextField, EmailField, Submit, MarkdownField}
  alias Surface.Components.Form
  alias Surface.Components.Form.{TextInput, Label, Field}
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
    <div class="m-4">
      You are not allowed to change this persona.
    </div>
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

       <Field :if={@changeset.action}
              name="error"
              class="empty:hidden p-4 border border-danger-dark bg-danger-light/50 rounded-xl mb-4">
        An error occured. Please check the errors below!
      </Field>

      <div :if={!pro(@current_user)}
            class="empty:hidden p-4 border border-info-dark bg-info-light/50 rounded-xl mb-4">
        <strong>Info!</strong> Fields grayed out can be updated with pro accounts only.
      </div>

      <Field name={:pid}
             class="my-4">
        <Label class="block font-medium text-gray-darker">Pid</Label>
        <TextInput field={:pid}
                   class="w-full"
                   opts={disabled: not pro(@current_user)} />
      </Field>

      <TextField name={:name} />
      <TextField name={:uri} />
      <EmailField name={:email} />

      <Field name={:fediverse_address}
             class="my-4">
        <Label class="block font-medium text-gray-darker">Fediverse address</Label>
        <TextInput field={:fediverse_address}
                   class="w-full"
                   opts={placeholder: "@username@domain.social"} />
      </Field>

      <Field name={:image_url}
             class="my-4">
        <Label class="block font-medium text-gray-darker">Image url</Label>
        <TextInput field={:image_url}
                   class="w-full"
                   opts={disabled: not pro(@current_user)} />
      </Field>

      <Field name={:image_title}
             class="my-4">
        <Label class="block font-medium text-gray-darker">Image title</Label>
        <TextInput field={:image_title}
                   class="w-full"
                   opts={disabled: not pro(@current_user)} />
      </Field>

      <Field name={:description_header}
             class="my-4">
        <Label class="block font-medium text-gray-darker">Description heading</Label>
        <TextInput field={:description_header}
                   class="w-full"
                   opts={disabled: not pro(@current_user)} />
      </Field>

      <MarkdownField name={:long_description}
                     disabled={not pro(@current_user)}/>
      <Submit />
    </Form>

    <a href={user_frontend_path(Endpoint, :my_profile)},
        class="text-link hover:text-link-dark">Back</a>
    """
  end
end
