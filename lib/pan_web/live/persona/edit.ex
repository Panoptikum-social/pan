defmodule PanWeb.Live.Persona.Edit do
  use Surface.LiveView, container: {:div, class: "m-4"}
  on_mount PanWeb.Live.Auth

  alias PanWeb.{Manifestation, Persona, Endpoint, User, Image}
  alias PanWeb.Surface.{TextField, EmailField, Submit, MarkdownField, ErrorTag}
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
           changeset: Persona.changeset(manifestation.persona) |> Map.put(:action, :insert)
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

  def handle_event("validate", %{"persona" => persona_params}, %{assigns: assigns} = socket) do
    changeset =
      if assigns.current_user.pro_until &&
           NaiveDateTime.compare(assigns.current_user.pro_until, NaiveDateTime.utc_now()) == :gt do
        Persona.pro_user_changeset(assigns.persona, persona_params)
      else
        Persona.user_changeset(assigns.persona, persona_params)
      end

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"persona" => persona_params}, %{assigns: assigns} = socket) do
    changeset =
      if assigns.current_user.pro_until &&
           NaiveDateTime.compare(assigns.current_user.pro_until, NaiveDateTime.utc_now()) == :gt do
        thumbnail = Image.get_by_persona_id(assigns.persona.id)
        if thumbnail, do: Image.delete_asset(thumbnail)
        Image.download_thumbnail("persona", assigns.persona.id, persona_params["image_url"])

        Persona.pro_user_changeset(assigns.persona, persona_params)
      else
        Persona.user_changeset(assigns.persona, persona_params)
      end

    case Pan.Repo.update(changeset) do
      {:ok, _persona} ->
        Pan.Search.Persona.update_index(assigns.persona.id)
        {:noreply,
         socket
         |> put_flash(:info, "Persona updated successfully.")
         |> push_redirect(to: user_frontend_path(Endpoint, :my_profile))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~F"""
    <h2 class="text-2xl">Edit persona</h2>

    <Form for={@changeset}
          class="p-4 mb-4 flex flex-col items-start space-y-4"
          change="validate"
          submit="save">

      <Field :if={!@changeset.valid?}
              name="error"
              class="p-4 border border-danger-dark bg-danger-light/50 rounded-xl mb-4">
        This persona is not valid. Please check the errors below!
      </Field>

      <div :if={!pro(@current_user)}
            class="empty:hidden p-4 border border-info-dark bg-info-light/50 rounded-xl mb-4">
        <strong>Info!</strong> Fields grayed out can be updated with pro accounts only.
      </div>

      <Field name={:pid}
             class="my-4">
        <Label class="block font-medium text-gray-darker">Pid</Label>
        <TextInput class="w-full"
                   opts={disabled: not pro(@current_user)} />
        <ErrorTag />
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
