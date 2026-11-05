defmodule PanWeb.Live.User.New do
  use Phoenix.LiveView, container: {:div, class: "flex-1 flex justify-center"}
  use Gettext, backend: PanWeb.Gettext
  on_mount PanWeb.Locale
  alias PanWeb.{User, Endpoint}
  alias Phoenix.Component
  import PanWeb.CoreComponents
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    changeset =
      User.registration_changeset(%User{})
      |> Map.put(:action, :insert)

    {:ok,
     assign(socket,
       changeset: changeset,
       user: %User{},
       submitted: false,
       page_title: dgettext("frontend", "Sign Up")
     )}
  end

  def handle_event("validate", %{"user" => user_params}, %{assigns: assigns} = socket) do
    changeset =
      User.registration_changeset(assigns.user, user_params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("create", %{"user" => user_params}, %{assigns: assigns} = socket) do
    # the page language becomes the user's setting, for later emails (#583)
    changeset =
      assigns.user
      |> User.registration_changeset(user_params)
      |> Ecto.Changeset.put_change(:locale, assigns.locale)

    case Pan.Repo.insert(changeset) do
      {:ok, user} ->
        token = Phoenix.Token.sign(PanWeb.Endpoint, "user", user.id)

        Pan.Email.email_verification_link_html_email(token, user.email)
        |> Pan.Mailer.deliver()

        message =
          dgettext(
            "frontend",
            "Your account @%{username} has been created! Please verify your email address via the verification link in the email sent to you, you can't log in before.",
            username: user.username
          )

        {:noreply,
         put_flash(socket, :info, message)
         |> push_navigate(to: session_path(Endpoint, :new))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset, submitted: true)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-lg m-4">
      <h1 class="text-3xl">{dgettext("frontend", "Sign Up")}</h1>

      <.form
        :let={f}
        for={@changeset}
        id="sign-up-form"
        phx-change="validate"
        phx-submit="create"
      >
        <.error :if={@submitted and !@changeset.valid?}>
          {dgettext("frontend", "The form is not filled out fully.")}
        </.error>

        <.error
          :if={{"has already been taken", []} == @changeset.errors[:email]}
          name="welcome_back"
          class="alert alert-soft alert-warning mb-4"
        >
          <h2 class="text-lg">{dgettext("frontend", "Welcome back!")}</h2>

          <p>
            {dgettext("frontend", "There is already a user account with this email address.")}<br /> {dgettext(
              "frontend",
              "Please"
            )}
            <.link
              href={user_path(@socket, :forgot_password)}
              class="underline hover:text-primary"
            >
              {dgettext("frontend", "Request a login link")}
            </.link>
            {dgettext(
              "frontend",
              "via email to login to your existing account and reset your password."
            )}
          </p>
        </.error>

        <.input
          field={f[:name]}
          label={dgettext("frontend", "Name *")}
          class="w-full input validator"
          required
          show_errors={false}
        />

        <.input
          field={f[:username]}
          label={dgettext("frontend", "Username *")}
          class="w-full input"
          required
          show_errors={false}
        />

        <.input
          type="email"
          field={f[:email]}
          label={dgettext("frontend", "Email *")}
          class="w-full input"
          required
          show_errors={false}
        />

        <.input
          type="password"
          name="user[password]"
          required
          value={Ecto.Changeset.get_change(@changeset, :password)}
          errors={
            if Component.used_input?(f[:password]),
              do: Enum.map(f[:password].errors, &translate_error(&1)),
              else: []
          }
          label={dgettext("frontend", "Password *")}
          class="w-full input"
          show_errors={false}
        />

        <.input
          type="password"
          name="user[password_confirmation]"
          required
          value={Ecto.Changeset.get_change(@changeset, :password_confirmation)}
          errors={
            if Component.used_input?(f[:password_confirmation]),
              do: Enum.map(f[:password_confirmation].errors, &translate_error(&1)),
              else: []
          }
          label={dgettext("frontend", "Password Confirmation *")}
          class="w-full input"
          show_errors={false}
        />

        <.input
          type="checkbox"
          field={f[:podcaster]}
          label={dgettext("frontend", "I am a podcaster")}
        />

        <.input
          type="number"
          field={f[:bot_check]}
          required
          label={dgettext("frontend", "If you subtract two from 44, you get... *")}
          placeholder={dgettext("frontend", "Are you a human? ;-)")}
          class="w-full input"
          show_errors={false}
        />

        <input type="submit" value={dgettext("frontend", "Create Account")} class="btn btn-primary" />
      </.form>
    </div>
    """
  end
end
