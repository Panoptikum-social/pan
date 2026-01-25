defmodule PanWeb.Live.User.New do
  use Phoenix.LiveView, container: {:div, class: "flex-1 flex justify-center"}
  alias PanWeb.{User, Endpoint}
  alias Phoenix.Component
  use PanWeb, :html
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
        |> Pan.Mailer.deliver()

        message = """
        Your account @#{user.username} has been created! Please confirm your email address
        via the confirmation link in the email sent to you. Otherwise you won't be able to
        claim personas.
        """

        {:noreply,
         put_flash(socket, :info, message)
         |> push_navigate(to: session_path(Endpoint, :login_from_signup, token: token))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-lg m-4">
      <h1 class="text-3xl">Sign Up</h1>

      <.form for={@changeset}
             :let={f}
             phx-change="validate"
             phx-submit="create">
        <.error :if={!@changeset.valid?}>
          The form is not filled out fully.
        </.error>

        <.error :if={{"has already been taken", []} == @changeset.errors[:email]}
               name="welcome_back"
               class="p-4 border border-warning-dark bg-warning-light/50 rounded-xl mb-4">
          <h2 class="text-lg">Welcome back!</h2>

          <p>There is already a user account with this email address.<br/>
            Please
            <.link href={user_path(@socket, :forgot_password)}
                  class="text-link hover:text-link-dark">
              Request a login link
            </.link>
            via email to login to your existing account and
            reset your password.
          </p>
        </.error>

        <.input field={f[:name]}
                label="Name *"
                class="w-full input validator"
                required
                show_errors={false} />

        <.input field={f[:username]}
                label="Username *"
                class="w-full input"
                required
                show_errors={false} />

        <.input type="email"
                field={f[:email]}
                label="Email *"
                class="w-full input"
                required
                show_errors={false} />

        <.input type="password"
                name="user[password]"
                required
                value={Ecto.Changeset.get_change(@changeset, :password)}
                errors={if Component.used_input?(f[:password]), do: Enum.map(f[:password].errors, &translate_error(&1)), else: []}
                label="Password *"
                class="w-full input"
                show_errors={false} />

        <.input type="password"
                name="user[password_confirmation]"
                required
                value={Ecto.Changeset.get_change(@changeset, :password_confirmation)}
                errors={if Component.used_input?(f[:password_confirmation]), do: Enum.map(f[:password_confirmation].errors, &translate_error(&1)), else: []}
                label="Password Confirmation *"
                class="w-full input"
                show_errors={false} />

        <.input type="checkbox"
                field={f[:podcaster]}
                label="I am a podcaster" />

        <.input type="number"
                field={f[:bot_check]}
                required
                label="If you subtract two from 44, you get... *"
                placeholder="Are you a human? ;-)"
                class="w-full input"
                show_errors={false} />

        <input type="submit" value="Create Account"
                 class="btn btn-primary" />
      </.form>
    </div>
    """
  end
end
