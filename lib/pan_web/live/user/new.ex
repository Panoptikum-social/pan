defmodule PanWeb.Live.User.New do
  use Surface.LiveView, container: {:div, class: "flex-1 flex justify-center"}
  alias PanWeb.{User, Endpoint}
  alias PanWeb.Surface.{Submit, TextField, PasswordField, EmailField, CheckBoxField, ErrorTag}
  alias Surface.Components.{Form, Link}
  alias Surface.Components.Form.{Field, Label, NumberInput}
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    changeset =
      User.registration_changeset(%User{})
      |> Map.put(:action, :insert)

    {:ok, assign(socket, changeset: changeset, user: %User{}, page_title: "Sign Up")}
  end

  def handle_event("validate", %{"user" => user_params}, %{assigns: assigns} = socket) do
    changeset =
      User.registration_changeset(assigns.user, user_params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("create", %{"user" => user_params}, %{assigns: assigns} = socket) do
    changeset = User.registration_changeset(assigns.user, user_params)

    case Pan.Repo.insert(changeset) do
      {:ok, user} ->
        token = Phoenix.Token.sign(PanWeb.Endpoint, "user", user.id)

        Pan.Email.email_confirmation_link_html_email(token, user.email)
        |> Pan.Mailer.deliver_now!()

        message = """
        Your account @#{user.username} has been created! Please confirm your email address
        via the confirmation link in the email sent to you. Otherwise you won't be able to
        claim personas.
        """

        {:noreply,
         put_flash(socket, :info, message)
         |> push_redirect(to: session_path(Endpoint, :login_from_signup, token: token))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~F"""
    <div class="max-w-lg m-4">
      <h1 class="text-3xl">Sign Up</h1>

      <Form for={@changeset}
            opts={autocomplete: "off"}
            change="validate"
            submit="create">

        <Field :if={!@changeset.valid?}
               name="error"
               class="empty:hidden p-2 my-4 text-grapefruit bg-grapefruit/20 border border-dotted border-grapefruit rounded-xl" >
          Account data is not valid yet. Please check the hints below.
        </Field>

        <Field :if={{"has already been taken", []} == @changeset.errors[:email]}
               name="welcome_back"
               class="empty:hidden p-4 border border-warning-dark bg-warning-light/50 rounded-xl mb-4">
          <h2 class="text-lg">Welcome back!</h2>

          <p>There is already a user account with this email address.<br/>
            Please
            <Link to={user_path(@socket, :forgot_password)}
                  class="text-link hover:text-link-dark"
                  label="Request a login link" /> via email to login to your existing account and
            reset your password.
          </p>
        </Field>

        <TextField name={:name} />
        <TextField name={:username} />
        <EmailField name={:email} />
        <PasswordField name={:password}
                       value={Ecto.Changeset.get_change(@changeset, :password)} />
        <PasswordField name={:password_confirmation}
                       value={Ecto.Changeset.get_change(@changeset, :password_confirmation)} />
        <CheckBoxField name={:podcaster} label="I am a podcaster" />

        <Field name={:bot_check} class="my-4">
          <Label class="block font-medium text-gray-darker">
                 If you subtract two from 44, you get...
          </Label>
          <NumberInput class="w-full"
                       opts={placeholder: "Are you a human? ;-)"}   />
          <ErrorTag />
        </Field>

        <Submit label="Create Account" />
      </Form>
    </div>
    """
  end
end
