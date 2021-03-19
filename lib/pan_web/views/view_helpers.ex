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
        "btn-gray-lighter",
        "btn-gray",
        "btn-gray-darker",
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
        "bg-white hover:bg-gray-lighter text-gray-darker border-gray",
        "bg-gray-lighter hover:bg-gray-lightest text-gray-darker border-gray",
        "bg-gray hover:bg-gray-light text-white",
        "bg-gray-darker hover:bg-gray-darker text-white",
        "bg-success hover:bg-success-light text-white",
        "bg-info hover:bg-info-light text-white",
        "bg-primary hover:bg-primary-light text-white",
        "bg-blue-jeans hover:bg-blue-jeans-light text-white",
        "bg-lavender hover:bg-lavender-light text-white",
        "bg-pink-rose hover:bg-pink-rose-light text-white",
        "bg-danger hover:bg-danger-light text-white",
        "bg-bittersweet hover:bg-bittersweet-light text-white",
        "bg-warning hover:bg-warning-light text-white"
    ], rem(counter, 13))
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
