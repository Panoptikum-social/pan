defmodule PanWeb.ViewHelpers do
  import Phoenix.HTML
  import Phoenix.HTML.Link
  alias PanWeb.Endpoint

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


  def btn_cycle(counter) do
    Enum.at(
      [
        "btn-default",
        "btn-light-gray",
        "btn-medium-gray",
        "btn-dark-gray",
        "btn-success",
        "btn-info",
        "btn-primary",
        "btn-blue-jeans",
        "btn-lavender",
        "btn-pink-rose",
        "btn-danger",
        "btn-bittersweet",
        "btn-warning"
      ],
      rem(counter, 13)
    )
  end

  def color_class_cycle(counter) do
    text_color = "text-gray-800"
    text_hover_color = "text-white"
    Enum.at(
      [
        "bg-white #{text_color} border-coolGray-2400 hover:bg-coolGray-800 hover:#{text_hover_color}",
        "bg-amber-200 #{text_color} border-amber-400 hover:bg-amber-800 hover:#{text_hover_color}",
        "bg-coolGray-100 #{text_color} border-coolGray-400 hover:bg-coolGray-800 hover:#{text_hover_color}",
        "bg-blue-200 #{text_color} border-blue-400 hover:bg-blue-800 hover:#{text_hover_color}",
        "bg-blueGray-200 #{text_color} border-blueGray-400 hover:bg-blueGray-800 hover:#{text_hover_color}",
        "bg-cyan-200 #{text_color} border-cyan-400 hover:bg-cyan-800 hover:#{text_hover_color}",
        "bg-green-200 #{text_color} border-green-400 hover:bg-green-800 hover:#{text_hover_color}",
        "bg-lime-200 #{text_color} border-lime-400 hover:bg-lime-800 hover:#{text_hover_color}",
        "bg-pink-200 #{text_color} border-pink-400 hover:bg-pink-800 hover:#{text_hover_color}",
        "bg-red-200 #{text_color} border-red-400 hover:bg-red-800 hover:#{text_hover_color}",
        "bg-lightBlue-200 #{text_color} border-lightBlue-400 hover:bg-lightBlue-800 hover:#{text_hover_color}",
        "bg-rose-200 #{text_color} border-rose-400 hover:bg-rose-800 hover:#{text_hover_color}",
        "bg-teal-200 #{text_color} border-teal-400 hover:bg-teal-800 hover:#{text_hover_color}",
        "bg-violet-200 #{text_color} border-violet-400 hover:bg-violet-800 hover:#{text_hover_color}",
        "bg-yellow-200 #{text_color} border-yellow-400 hover:bg-yellow-800 hover:#{text_hover_color}",
      ],
      rem(counter, 15)
    )
  end

  def truncate_string(string, len) do
    length = len - 3

    if string do
      if String.length(string) > length do
        String.slice(string, 0, length) <> "..."
      else
        string
      end
    else
      ""
    end
  end

  def ej(nil), do: ""
  def ej(string), do: javascript_escape(string)

  def my_safe_to_string({:safe, string}), do: safe_to_string({:safe, string})
  def my_safe_to_string(string), do: string

  def datatable_actions(record_id, path) do
    [
      "<nobr>",
      link("Show",
        to: path.(Endpoint, :show, record_id),
        class: "btn btn-default btn-xs"
      ),
      " ",
      link("Edit",
        to: path.(Endpoint, :edit, record_id),
        class: "btn btn-warning btn-xs"
      ),
      " ",
      link("Delete",
        to: path.(Endpoint, :delete, record_id),
        method: :delete,
        data: [confirm: "Are you sure?"],
        class: "btn btn-danger btn-xs"
      ),
      "</nobr>"
    ]
    |> Enum.map(&my_safe_to_string/1)
    |> Enum.join()
  end

  def fa_icon(name) do
    ~s(<i class="fa fa-#{name}"></i>) |> raw()
  end

  def fa_icon(name, class: class) do
    ~s(<i class="fa fa-#{name} #{class}"></i>) |> raw()
  end
end
