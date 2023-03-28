defmodule PanWeb do
  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2, where: 2, select: 2]
      import Ecto.Convenience, only: [total_estimated: 1]
      import PanWeb.Router.Helpers
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: PanWeb

      alias Pan.Repo
      alias PanWeb.Router.Helpers, as: Routes

      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]
      import PanWeb.Router.Helpers
      import PanWeb.Gettext

      import PanWeb.Auth,
        only: [
          authenticate_user: 2,
          authenticate_admin: 2,
          authenticate_pro: 2,
          authenticate_moderator: 2
        ]

      import PanWeb.Api.Auth,
        only: [
          authenticate_api_user: 2,
          authenticate_api_pro_user: 2,
          authenticate_api_moderator: 2
        ]

      import Ecto.Convenience, only: [total_estimated: 1]
      import Plug.Conn
      import PanWeb.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/pan_web/templates",
        namespace: PanWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PanWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router

      import PanWeb.Auth,
        only: [
          authenticate_user: 2,
          authenticate_admin: 2,
          authenticate_pro: 2,
          authenticate_moderator: 2
        ]

      import PanWeb.Api.Auth,
        only: [
          authenticate_api_user: 2,
          authenticate_api_pro_user: 2,
          authenticate_api_moderator: 2
        ]
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import PanWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      # These are our panoptkum-specific view helpers
      import PanWeb.ViewHelpers

      import PanWeb.ErrorHelpers
      import PanWeb.Gettext
      import PanWeb.Router.Helpers
      alias PanWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
