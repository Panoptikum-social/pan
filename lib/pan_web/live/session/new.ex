defmodule PanWeb.Live.Session.New do
  use Surface.LiveView, container: {:div, class: "m-4 flex justify-center"}
  alias Surface.Components.Form
  alias PanWeb.Surface.{Submit, PasswordField}
  alias Surface.Components.Form.{Field, TextInput, Label}
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Log In")}
  end

  def render(assigns) do
    ~F"""
    <div class="max-w-lg my-4">
      <h1 class="text-3xl">Login</h1>

      <Form action="/sessions"
            for={%{}}
            as={:session}
            opts={autocomplete: "off"}>

        <Field name="username"
               class="my-6">
          <Label field={:username_or_email}
                 class="block font-medium text-gray-darker"/>
          <TextInput class="w-full border-gray-light rounded-lg shadow-sm" />
        </Field>

        <PasswordField name={:password}
                       value="" />

        <Submit label="Log in" />
      </Form>

      <ul class="list-disc mt-4 ml-8">
        <li>Forgot your password? -
          <.link href={user_path(@socket, :forgot_password)}
                 class="text-link hover:text-link-dark">
            Get an email with a login link
          </.link>
        </li>
        <li>
          No account yet? -
          <.link href={user_frontend_path(@socket, :new)}
                class="text-link hover:text-link-dark">
            Sign up
          </.link>
        </li>
      </ul>
    </div>
    """
  end
end
