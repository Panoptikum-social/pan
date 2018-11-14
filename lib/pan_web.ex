defmodule Pan.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2, where: 2, select: 2]
      import Ecto.Convenience, only: [is_false: 1]
      import PanWeb.Router.Helpers
      import Tirexs.HTTP
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: PanWeb

      alias Pan.Repo
      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]

      import PanWeb.Router.Helpers

      import PanWeb.Gettext
      import PanWeb.Auth, only: [authenticate_user: 2,
                                 authenticate_admin: 2,
                                 authenticate_pro: 2]

      import PanWeb.Api.Auth, only: [authenticate_api_user: 2,
                                     authenticate_api_pro_user: 2]

      import Ecto.Convenience, only: [is_false: 1]
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/pan_web/templates",
                        namespace: PanWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import PanWeb.Router.Helpers
      import PanWeb.ErrorHelpers
      import PanWeb.Gettext
      import PanWeb.ViewHelpers
      import HtmlSanitizeEx2, only: [basic_html_reduced: 1]
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import PanWeb.Auth, only: [authenticate_user: 2,
                                 authenticate_admin: 2,
                                 authenticate_pro: 2,
                                 unset_cookie: 2]

      import PanWeb.Api.Auth, only: [authenticate_api_user: 2,
                                     authenticate_api_pro_user: 2]
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias Pan.Repo
      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]
      import PanWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
