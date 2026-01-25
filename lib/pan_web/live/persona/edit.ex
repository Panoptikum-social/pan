defmodule PanWeb.Live.Persona.Edit do
  use Surface.LiveView, container: {:div, class: "m-4"}
  on_mount PanWeb.Live.Auth

  alias PanWeb.{Manifestation, Persona, Endpoint, User, Image}
  alias PanWeb.Surface.MarkdownField
  use PanWeb, :html
  import PanWeb.Router.Helpers
  import Pan.Parser.MyDateTime, only: [in_the_future?: 1]

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
           changeset: Persona.changeset(manifestation.persona) |> Map.put(:action, :insert),
           page_title: "Edit Persona #{manifestation.persona.name}"
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

  defp pro(user), do: in_the_future?(user.pro_until)

  def handle_event("validate", %{"persona" => persona_params}, %{assigns: assigns} = socket) do
    changeset =
      if in_the_future?(assigns.current_user.pro_until) do
        Persona.pro_user_changeset(assigns.persona, persona_params) |> Map.put(:action, :insert)
      else
        Persona.user_changeset(assigns.persona, persona_params) |> Map.put(:action, :insert)
      end

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"persona" => persona_params}, %{assigns: assigns} = socket) do
    changeset =
      if in_the_future?(assigns.current_user.pro_until) do
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
         |> push_navigate(to: user_frontend_path(Endpoint, :my_profile))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~F"""
    <h1 class="text-3xl">Edit persona</h1>

    <.form for={@changeset}
           :let={f}
           class="p-4 mb-4 flex flex-col items-start space-y-4"
           change="validate"
           submit="save">

      <.error :if={!@changeset.valid?}>
        This persona is not valid. Please check the errors below!
      </.error>

      <.error :if={!pro(@current_user)}>
        <strong>Info!</strong> Fields grayed out can be updated with pro accounts only.
      </.error>

      <.input field={f[:pid]}
             class="input"
             label="PanoptikumID"
             disabled={not pro(@current_user)} />

      <.input field={f[:name]}
              label="Name"
              class="w-full input" />

      <.input field={f[:uri]}
              label="Uri"
              class="w-full input" />

      <.input type="email"
              field={f[:email]}
              label="Email"
              class="w-full input" />

      <.input field={f[:fediverse_address]}
              label="Fediverse Address"
              placeholder="@username@domain.social"
              class="w-full input" />
        <p class="text-gray">(support is experimental and data might not be imported currently)</p>

      <.input field={f[:image_url]}
              label="Image URL"
              class="input w-full"
              disabled={not pro(@current_user)} />

      <.input field={f[:image_title]}
              class="input w-full"
              label="Image title"
              disabled={not pro(@current_user)} />

      <.input field={f[:description_header]}
              class="input w-full"
              label="Description heading"
              disabled={not pro(@current_user)} />

      <MarkdownField myfield={f[:long_description]}
                     disabled={not pro(@current_user)}/>

      <.button type="submit" class="btn btn-info">Submit</.button>
    </.form>

    <a href={user_frontend_path(Endpoint, :my_profile)},
        class="text-link hover:text-link-dark">Back</a>
    """
  end
end
