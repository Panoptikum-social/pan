defmodule Pan.PageFrontendView do
  use Pan.Web, :view

  def list_group_item_cycle(counter) do
    Enum.at(["list-group-item-info", "list-group-item-danger",
             "list-group-item-warning", "list-group-item-primary", "list-group-item-success"], rem(counter, 5))
  end
end