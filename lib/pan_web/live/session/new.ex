defmodule PanWeb.Live.Session.New do
  use Surface.LiveView, container: {:div, class: "flex-1 justify-self-center"}
  alias Surface.Components.Form
  alias PanWeb.Surface.{Submit, PasswordField}
  alias Surface.Components.Form.{Field, TextInput, Label}
  alias Surface.Components.Link
  import PanWeb.Router.Helpers

  def render(assigns) do
    ~F"""
    <div class="mx-auto max-w-lg mt-12">
      <h1 class="text-3xl">Login</h1>

      <Form action="/sessions"
            for={:session}
            opts={autocomplete: "off"}>

        <Field name="username"
               class="my-6">
          <Label field={:username_or_email}
                  class="block font-medium text-gray-darker"/>
          <TextInput class="w-full border-gray-light rounded-lg shadow-sm" />
        </Field>

        <PasswordField name="password" />

        <Field name="hint" class="mt-4 text-gray-darker">
          Submitting this form will transfer a session cookie to the server. See
          <Link to="https://blog.panoptikum.io/privacy"
                class="text-link hover:text-link-dark"
                label="Privacy" /> for details.
        </Field>

        <Submit label="Log in" />
      </Form>

      <ul class="list-disc mt-4 ml-8">
        <li>Forgot your password? -
          <Link to={user_path(@socket, :forgot_password)}
                class="text-link hover:text-link-dark"
                label="Get an email with a login link" />
        </li>
        <li>
          No account yet? -
          <Link to={user_frontend_path(@socket, :new)}
                class="text-link hover:text-link-dark"
                label="Sign up" />
        </li>
      </ul>
    </div>
    """
  end
end
