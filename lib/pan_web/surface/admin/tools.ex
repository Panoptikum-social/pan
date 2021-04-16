defmodule PanWeb.Surface.Admin.Tools do

  def ensure_ids_and_selected(items) do
    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} -> Map.put_new(item, :id, index) end)
    |> Enum.map(&Map.put_new(&1, :selected, false))
  end

  def toggle_select_multi(item, id) do
    if item.id == id  do
      Map.put(item, :selected, !item[:selected])
    else
      item
    end
  end

  def toggle_select_single(item, id) do
    if item.id == id  do
      Map.put(item, :selected, !item[:selected])
    else
      Map.put(item, :selected, false)
    end
  end
end
