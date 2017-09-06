defmodule PanWeb.OpmlView do
  use Pan.Web, :view
  alias PanWeb.Endpoint

  def render("datatable.json", %{opmls: opmls}) do
    %{opmls: Enum.map(opmls, &opml_json/1)}
  end


  def opml_json(opml) do
    %{id:            opml.id,
      user_name:     opml.user.name,
      content_type:  opml.content_type,
      filename:      opml.filename,
      inserted_at:   opml.inserted_at,
      path:          opml.path,
      actions:       opml_actions(opml, &opml_path/3)}
  end


  def opml_actions(record, path) do
    ["<nobr>",
     link("Parse", to: path.(Endpoint, :import, record.id),
                   class: "btn btn-info btn-xs"), " ",
     link("Show", to: path.(Endpoint, :show, record.id),
                  class: "btn btn-default btn-xs"), " ",
     link("Edit", to: path.(Endpoint, :edit, record.id),
                  class: "btn btn-warning btn-xs"), " ",
     link("Delete", to: path.(Endpoint, :delete, record.id),
                    method: :delete,
                    data: [confirm: "Are you sure?"],
                    class: "btn btn-danger btn-xs"),
     "</nobr>"]
    |> Enum.map(&my_safe_to_string/1)
    |> Enum.join()
  end
end
