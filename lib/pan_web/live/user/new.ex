defmodule PanWeb.Live.User.New do
  use Surface.LiveView
  alias PanWeb.User
  alias PanWeb.Surface.{Submit, TextField, PasswordField, EmailField, CheckBoxField}
  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, Label, ErrorTag, NumberInput}
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    {:ok, assign(socket, changeset:  %User{} |> User.changeset())}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-96">
      <h1 class="text-3xl">Sign Up</h1>

      <Form action={{ user_frontend_path(@socket, :create) }}
            for={{ @changeset }}
            opts={{ autocomplete: "off" }}>

        <Field :if={{ @changeset.action }}
               name="error"
               class="alert alert-danger">
          An error occured. Please check the errors below!
        </Field>

        <Field :if={{ {"has already been taken", []} == @changeset.errors[:email] }}
               name="welcome_back"
               class="alert alert-warning alert-dismissable">
          <h4>Welcome back!</h4>

          <p>There is already a user account with this email address.<br/>
            Please
            <a href={{ user_path(@socket, :forgot_password) }}
               class="alert-link">
              Request a login link
            </a> via email to login to your existing account and reset your password.
          </p>
        </Field>

        <TextField name="name" />
        <TextField name="username" />
        <EmailField name="email" />
        <PasswordField name="password" />
        <PasswordField name="password_confirmation" />
        <CheckBoxField name="podcaster" label="I am a podcaster" />

        <Field name="bot_check" class="my-4">
          <Label class="block font-medium text-dark-gray">
                 If you subtract two from 44, you get...
          </Label>
          <NumberInput class="w-full"
                       opts={{ placeholder: "Are you a human? ;-)" }} />
          <ErrorTag field={{ :bot_check }} />
        </Field>

        <Field name="cookie_warning" class="text-dark-gray">
          Submitting this form will transfer a session cookie to the server.<br/>
          Please, read our
          <a href="https://blog.panoptikum.io/privacy"
             class="text-link hover:link-dark">
            Privacy Policy
           </a> before signing up!
         </Field>

         <Submit label="Create Account" />
       </Form>
    </div>
    """
  end
end
