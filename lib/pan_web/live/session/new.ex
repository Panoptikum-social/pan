defmodule PanWeb.Live.Session.New do
  use PanWeb, :live_view
  import PanWeb.CoreComponents
  import PanWeb.Router.Helpers
  alias PanWeb.Endpoint

  def mount(params, _session, socket) do
    {:ok, assign(socket, page_title: dgettext("frontend", "Log In"), form: to_form(params))}
  end

  def render(assigns) do
    ~H"""
    <div class="m-4 flex justify-center">
      <div class="max-w-lg my-4">
        <h1 class="text-3xl">{dgettext("frontend", "Login")}</h1>

        <.form
          :let={f}
          action="/sessions"
          for={@form}
          as={:session}
          autocomplete="off"
        >
          <.input
            field={f[:username]}
            label={dgettext("frontend", "Username or email")}
            class="w-full input"
          />

          <.input
            field={f[:password]}
            label={dgettext("frontend", "Password")}
            type="password"
            class="w-full input"
            value=""
          />

          <.input
            field={f[:remember_me]}
            type="checkbox"
            label={dgettext("frontend", "Remember me for 30 days")}
          />

          <.button type="submit" class="btn btn-primary">{dgettext("frontend", "Log in")}</.button>
        </.form>

        <ul class="list-disc mt-4 ml-8">
          <li>
            {dgettext("frontend", "Forgot your password?")} -
            <.link
              href={user_path(Endpoint, :forgot_password)}
              class="underline hover:text-primary"
            >
              {dgettext("frontend", "Get an email with a login link")}
            </.link>
          </li>
          <li>
            {dgettext("frontend", "No account yet?")} -
            <.link
              href={user_frontend_path(Endpoint, :new)}
              class="underline hover:text-primary"
            >
              {dgettext("frontend", "Sign up")}
            </.link>
          </li>
        </ul>
      </div>
    </div>
    """
  end
end
