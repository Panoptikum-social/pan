defmodule PanWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use PanWeb, :controller
      use PanWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

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

  def channel do
    quote do
      use Phoenix.Channel
      import PanWeb.Gettext
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: PanWeb,
        formats: [html: "View", json: "View"],
        layouts: [html: {PanWeb.LayoutView, :app}, json: JaSerializer.PhoenixView]

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

  defp view_helpers do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.Component

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

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PanWeb.LayoutView, :live}

      unquote(view_helpers())
    end
  end

  def admin_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PanWeb.LayoutView, :live_admin},
        container: {:div, class: "flex-1 w-full"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: PanWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import PanWeb.CoreComponents

      # Common modules used in templates
      alias Phoenix.LiveView.JS
      alias PanWeb.Layouts

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PanWeb.Endpoint,
        router: PanWeb.Router,
        statics: PanWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
