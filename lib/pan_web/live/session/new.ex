defmodule PanWeb.Live.Session.New do
  use Surface.LiveView
  alias Surface.Components.Form
  alias PanWeb.Surface.{Submit, PasswordField}
  alias Surface.Components.Form.{Field, TextInput, Label}
  import PanWeb.Router.Helpers

  def render(assigns) do
    ~H"""
    <div class="max-w-lg">
      <h1 class="text-3xl">Login</h1>

      <Form action="/sessions"
            for={{ :session }}
            opts={{ autocomplete: "off" }}>

        <Field name="email"
               class="my-6">
          <Label field={{ :username_or_email}}
                  class="block font-medium text-dark-gray"/>
          <TextInput class="w-full border-light-medium-gray rounded-lg shadow-sm" />
        </Field>

        <PasswordField name="password" />

        <Field name="hint" class="mt-4 text-dark-gray">
          Submitting this form will transfer a session cookie to the server. See
          <a href="https://blog.panoptikum.io/privacy"
              class="text-link hover:text-link-dark">
            Privacy
          </a> for details.
        </Field>

        <Submit label="Log in" />
      </Form>

      <ul class="list-disc mt-4 ml-8">
        <li>Forgot your password? -
          <a href={{ user_path(@socket, :forgot_password) }}
            class="text-link hover:text-link-dark">
            Get an email with a login link
          </a>
        </li>
        <li>
          No account yet? -
          <a href={{ user_frontend_path(@socket, :new) }}
            class="text-link hover:text-link-dark">
            Sign up
          </a>
        </li>
      </ul>
    </div>
    """
  end
end
