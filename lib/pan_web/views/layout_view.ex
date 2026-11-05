defmodule PanWeb.LayoutView do
  use PanWeb, :view

  @doc """
  Renders a layout partial (sidebar, footer) in the user's language, also on
  admin pages whose content is forced to English (#596). Rendered to iodata
  inside `with_locale/3`, as HEEx would otherwise evaluate it later.
  """
  def in_nav_locale(conn, template, assigns) do
    Gettext.with_locale(PanWeb.Gettext, nav_locale(conn), fn ->
      __MODULE__ |> Phoenix.View.render_to_iodata(template, assigns) |> Phoenix.HTML.raw()
    end)
  end

  def nav_locale(conn), do: conn.assigns[:nav_locale] || conn.assigns[:locale] || "en"

  @doc """
  `{label, DaisyUI badge class}` for the current environment, shown in the
  sidebar just below the logo so it's obvious at a glance which environment
  you're looking at. `nil` in prod (or any environment that doesn't
  explicitly opt in) — see `config :pan, :environment` in
  config/dev.exs/qa.exs/prod.exs.
  """
  def environment_badge do
    case Application.get_env(:pan, :environment) do
      "dev" -> {"DEV", "badge-success"}
      "qa" -> {"Q/A", "badge-info"}
      _ -> nil
    end
  end

  @doc """
  Generates name for the JavaScript view we want to use
  in this combination of view/template.
  """
  def js_view_name(conn, view_template) do
    [view_name(conn), template_name(view_template)]
    |> Enum.reverse()
    |> List.insert_at(0, "view")
    |> Enum.map(&String.capitalize/1)
    |> Enum.reverse()
    |> Enum.join("")
  end

  # Takes the resource name of the view module and removes the
  # the ending *_view* string.
  defp view_name(conn) do
    conn
    |> view_module
    |> Phoenix.Naming.resource_name()
    |> String.replace("_view", "")
  end

  # Removes the extenion from the template and returns
  # just the name.
  defp template_name(template) when is_binary(template) do
    template
    |> String.split(".")
    |> Enum.at(0)
  end
end
