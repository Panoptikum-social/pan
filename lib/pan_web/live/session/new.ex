defmodule PanWeb.Live.Session.New do
  use Surface.LiveView
  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, TextInput, Submit, Label, PasswordInput}
  import PanWeb.Router.Helpers

  def render(assigns) do
    ~H"""
    <div class="max-w-96">
      <h1 class="text-3xl">Login</h1>

      <Form action="/sessions"
            for={{ :session }}
            opts={{ autocomplete: "off" }}>

        <Field name="email"
               class="my-6">
          <Label field={{ :username_or_email}}
                  class="block font-medium text-gray-700"/>
          <TextInput field={{ :username }}
                     class="w-full border-light-medium-gray rounded-lg shadow-sm" />
        </Field>

        <Field name="password" class="my-6">
          <Label field={{ :password}}
                class="block font-medium text-gray-700"/>
          <PasswordInput field={{ :password }}
                         class="w-full border-light-medium-gray rounded-lg shadow-sm" />
        </Field>

        <Field name="hint" class="mt-4">
          Submitting this form will transfer a session cookie to the server. See
          <a href="https://blog.panoptikum.io/privacy"
              class="text-teal-500 hover:text-teal-300">
            Privacy
          </a> for details.
        </Field>

        <Submit label="Log in"
                class="my-4 py-2 px-4 rounded-lg font-medium text-white
                        bg-lightBlue-500 hover:text-gray-700 hover:bg-lightBlue-700" />
      </Form>

      <ul class="list-disc mt-4 ml-8">
        <li>Forgot your password? -
          <a href={{ user_path(@socket, :forgot_password) }}
            class="text-teal-500 hover:text-teal-300">
            Get an email with a login link
          </a>
        </li>
        <li>
          No account yet? -
          <a href={{ user_frontend_path(@socket, :new) }}
            class="text-teal-500 hover:text-teal-300">
            Sign up
          </a>
        </li>
      </ul>
    </div>
    """
  end
end
