defmodule PanWeb.LayoutView do
  use Pan.Web, :view

  @doc """
  Generates name for the JavaScript view we want to use
  in this combination of view/template.
  """
  def js_view_name(conn, view_template) do
    [view_name(conn), template_name(view_template)]
    |> Enum.reverse
    |> List.insert_at(0, "view")
    |> Enum.map(&String.capitalize/1)
    |> Enum.reverse
    |> Enum.join("")
  end

  # Takes the resource name of the view module and removes the
  # the ending *_view* string.
  defp view_name(conn) do
    conn
    |> view_module
    |> Phoenix.Naming.resource_name
    |> String.replace("_view", "")
  end

  # Removes the extion from the template and reutrns
  # just the name.
  defp template_name(template) when is_binary(template) do
    template
    |> String.split(".")
    |> Enum.at(0)
  end
end
