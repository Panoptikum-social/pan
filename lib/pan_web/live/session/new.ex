defmodule PanWeb.Live.Session.New do
  use PanWeb, :live_view
  import PanWeb.CoreComponents
  import PanWeb.Router.Helpers
  alias PanWeb.Endpoint

  def mount(params, _session, socket) do
    {:ok, assign(socket, page_title: "Log In", form: to_form(params))}
  end

  def render(assigns) do
    ~H"""
    <div class="m-4 flex justify-center">
    <div class="max-w-lg my-4">
      <h1 class="text-3xl">Login</h1>

      <.form action="/sessions"
            :let={f}
            for={@form}
            as={:session}
            autocomplete="off">

        <.input field={f[:username]} label="Username or email"
               class="w-full input" />

        <.input field={f[:password]} label="Password" type="password"
                class="w-full input" value="" />

        <.button type="submit" label="Log in" class="btn btn-primary">Submit</.button>
      </.form>

      <ul class="list-disc mt-4 ml-8">
        <li>Forgot your password? -
          <.link href={user_path(Endpoint, :forgot_password)}
                 class="text-link hover:text-link-dark">
            Get an email with a login link
          </.link>
        </li>
        <li>
          No account yet? -
          <.link href={user_frontend_path(Endpoint, :new)}
                class="text-link hover:text-link-dark">
            Sign up
          </.link>
        </li>
      </ul>
    </div>
    </div>
    """
  end
end
