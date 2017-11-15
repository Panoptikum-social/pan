defmodule PanWeb.PageFrontendView do
  use Pan.Web, :view

  def list_group_item_cycle(counter) do
    Enum.at(["list-group-item-info", "list-group-item-danger",
             "list-group-item-warning", "list-group-item-primary", "list-group-item-success"], rem(counter, 5))
  end

  def content_for(url, selector) do
    unsafe_content_for(url, selector)
    |> Phoenix.HTML.raw()
  end

  def unsafe_content_for(url, selector) do
    HTTPoison.get!("https://blog.panoptikum.io/" <> url <> "/").body
    |> Floki.find(selector)
    |> Floki.raw_html()
  end

  def prepare_for_toplist(podcasts) do
    podcasts
    |> Enum.group_by(&select_count/1, &id_title_tuple/1)
    |> Map.to_list()
    |> Enum.sort_by(fn {count, _list_of_id_title_tuples} -> count end, &>=/2)
    |> add_rank()
  end
  
  defp select_count([count, _id, _title]), do: count
  defp id_title_tuple([_count, id, title]), do: {id, title}
  
  # takes a list of {count, list_of_id_title_tuples}
  # and adds a rank according to the subscribers count
  defp add_rank(counts_and_podcasts) when is_list(counts_and_podcasts) do
    # start loop with an initial rank of 1 and an empty accumulator
    add_rank(counts_and_podcasts, {1, []})
  end
  # recursive loop
  defp add_rank([{count, podcasts} | tail], {rank, acc}) do
    next_rank = rank + length(podcasts)
    next_acc = acc ++ [{rank, count, podcasts}]
    
    # next round
    add_rank(tail, {next_rank, next_acc})
  end
  # end of list, end loop and return acc
  defp add_rank([], {_rank, acc}), do: acc
end
