defmodule PanWeb.Live.User.New do
  use Surface.LiveView
  alias PanWeb.User
  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, TextInput, Submit, Label, PasswordInput, ErrorTag,
                                 NumberInput, Checkbox, EmailInput}
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    {:ok, assign(socket, changeset:  %User{} |> User.changeset())}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-96">
      <h1 class="text-3xl">Sign Up</h1>

      <Form action= {{ user_frontend_path(@socket, :create) }}
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

        <Field name="name"
               class="my-4">
          <Label field={{ :name}}
                 class="block font-medium text-gray-700"/>
          <TextInput field={{ :name }}
                      class="w-full" />
          <ErrorTag field={{ :name }} />
        </Field>

        <Field name="username"
               class="my-4">
          <Label field={{ :username }}
                 class="block font-medium text-gray-700"/>
          <TextInput field={{ :username }}
                     class="w-full" />
          <ErrorTag field={{ :username }} />
        </Field>

        <Field name="email"
               class="my-4">
          <Label field={{ :email}}
                 class="block font-medium text-gray-700" />
          <EmailInput field={{ :email }}
                      class="w-full" />
          <ErrorTag field={{ :email }} />
        </Field>

        <Field name="password"
               class="my-4">
          <Label field={{ :password }}
                 class="block font-medium text-gray-700" />
          <PasswordInput field={{ :password }}
                         class="w-full" />
          <ErrorTag field={{ :password }} />
        </Field>

        <Field name="password_confirmation"
               class="my-4">
          <Label field={{ :password_confirmation}}
                 class="block font-medium text-gray-700"/>
          <PasswordInput field={{ :password_confirmation }}
                         class="w-full" />
          <ErrorTag field={{ :password_confirmation }} />
        </Field>

        <Field name="podcaster"
               class="my-4 flex items-center">
          <Checkbox field={{ :podcaster }} />
          <Label field={{ :podcaster}}
                 class="font-medium text-gray-700 pl-4">
                 I am a podcaster
          </Label>
          <ErrorTag field={{ :podcaster }} />
        </Field>

        <Field name="bot_check"
               class="my-4">
          <Label field={{ :bot_check}}
                 class="block font-medium text-gray-700">
                 If you subtract two from 44, you get...
          </Label>
          <NumberInput field={{ :bot_check }}
                       class="w-full"
                       opts={{ placeholder: "... sorry, we had too many bots sign up!" ,
                       length: 2 }} />
          <ErrorTag field={{ :bot_check }} />
        </Field>

        <Field name="cookie_warning">
          Submitting this form will transfer a session cookie to the server.<br/>
          Please, read our
          <a href="https://blog.panoptikum.io/privacy"
             class="text-teal-500 hover:text-teal-300">
            Privacy Policy
           </a> before signing up!
         </Field>

         <Submit label="Create Account"
                 class="my-4 py-2 px-4 font-medium text-white bg-lightBlue-500
                        hover:text-gray-700 hover:bg-lightBlue-300" />
       </Form>
    </div>
    """
  end
end
