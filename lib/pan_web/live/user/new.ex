defmodule PanWeb.Live.User.New do
  use Surface.LiveView, container: {:div, class: "flex-1 justify-self-center"}
  alias PanWeb.User
  alias PanWeb.Surface.{Submit, TextField, PasswordField, EmailField, CheckBoxField}
  alias Surface.Components.{Form, Link}
  alias Surface.Components.Form.{Field, Label, ErrorTag, NumberInput}
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    {:ok, assign(socket, changeset: %User{} |> User.changeset)}
  end

  def render(assigns) do
    ~F"""
    <div class="max-w-lg mx-auto">
      <h1 class="text-3xl">Sign Up</h1>

      <Form action={user_frontend_path(@socket, :create)}
            for={@changeset}
            opts={autocomplete: "off"}>

        <Field :if={@changeset.action}
               name="error"
               class="alert alert-danger">
          An error occured. Please check the errors below!
        </Field>

        <Field :if={{"has already been taken", []} == @changeset.errors[:email]}
               name="welcome_back"
               class="alert alert-warning alert-dismissable">
          <h4>Welcome back!</h4>

          <p>There is already a user account with this email address.<br/>
            Please
            <Link to={user_path(@socket, :forgot_password)}
                  class="alert-link"
                  label="Request a login link" /> via email to login to your existing account and
            reset your password.
          </p>
        </Field>

        <TextField name="name" />
        <TextField name="username" />
        <EmailField name="email" />
        <PasswordField name={:password} />
        <PasswordField name={:password_confirmation} />
        <CheckBoxField name="podcaster" label="I am a podcaster" />

        <Field name="bot_check" class="my-4">
          <Label class="block font-medium text-gray-darker">
                 If you subtract two from 44, you get...
          </Label>
          <NumberInput class="w-full"
                       opts={placeholder: "Are you a human? ;-)"} />
          <ErrorTag field={:bot_check} />
        </Field>

         <Submit label="Create Account" />
       </Form>
    </div>
    """
  end
end
