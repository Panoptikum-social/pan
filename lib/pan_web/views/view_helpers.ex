defmodule PanWeb.ViewHelpers do
  import Phoenix.HTML
  import Phoenix.HTML.Link
  alias PanWeb.Endpoint

  def btn_cycle(counter) do
    Enum.at(["btn-default", "btn-light-gray", "btn-medium-gray", "btn-dark-gray",
             "btn-success", "btn-info", "btn-primary", "btn-blue-jeans", "btn-lavender",
             "btn-pink-rose", "btn-danger", "btn-bittersweet", "btn-warning", ], rem(counter, 13))
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
    ["<nobr>",
     link("Show", to: path.(Endpoint, :show, record_id),
                  class: "btn btn-default btn-xs"), " ",
     link("Edit", to: path.(Endpoint, :edit, record_id),
                  class: "btn btn-warning btn-xs"), " ",
     link("Delete", to: path.(Endpoint, :delete, record_id),
                    method: :delete,
                    data: [confirm: "Are you sure?"],
                    class: "btn btn-danger btn-xs"),
     "</nobr>"]
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