defmodule PanWeb.ViewHelpers do
  import Phoenix.HTML

  def la_icon(name), do: la_icon(name, class: "")
  def la_icon(name, class: class) do
    class = if class == "", do: "h-6 w-6", else: class

    :code.priv_dir(:pan)
    |> Path.join("/static/svg/line_awesome_icons/#{name}.svg")
    |> File.read()
    |> elem(1)
    |> String.replace("<svg", "<svg class=\"#{class} line-awesome\"")
    |> raw()
  end

  def la_nav_icon(name) do
    la_icon name, class: "fill-current text-coolGray-200 h-6 w-6 inline"
  end
end
