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
    la_icon(name, class: "fill-current text-coolGray-200 h-6 w-6 inline")
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
    Enum.at([
        "bg-white text-gray-600 border-coolGray-300 hover:bg-coolGray-400 hover:text-white",
        "bg-coolGray-100 text-gray-600 border-coolGray-300 hover:bg-white hover:text-gray-800",
        "bg-coolGray-400 text-white hover:bg-coolGray-800 hover:text-gray-600",
        "bg-coolGray-600 text-white hover:bg-coolGray-200 hover:text-gray-600",
        "bg-lime-500 text-white hover:bg-lime-800 hover:text-gray-600",
        "bg-teal-500 text-white hover:bg-teal-800 hover:text-gray-600",
        "bg-lightBlue-400 text-white hover:bg-lightBlue-800 hover:text-gray-600",
        "bg-blue-500 text-white hover:bg-blue-800 hover:text-gray-600",
        "bg-violet-400 text-white hover:bg-violet-800 hover:text-gray-600",
        "bg-pink-400 text-white hover:bg-pink-800 hover:text-gray-600",
        "bg-rose-600 text-white hover:bg-rose-200 hover:text-gray-600",
        "bg-red-500 text-white hover:bg-red-800 hover:text-gray-600",
        "bg-amber-400 text-white hover:bg-amber-800 hover:text-gray-600",
        "bg-cyan-400 text-white hover:bg-cyan-800 hover:text-gray-600",
        "bg-green-500 text-white hover:bg-green-800 hover:text-gray-600",
        "bg-yellow-400 text-white  hover:bg-yellow-800 hover:text-gray-600",
    ], rem(counter, 15))
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
