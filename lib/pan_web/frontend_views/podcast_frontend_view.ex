defmodule PanWeb.PodcastFrontendView do
  use PanWeb, :view

  def prepare_for_toplist(podcasts) do
    podcasts
    |> Enum.group_by(&select_count/1, &id_title_tuple/1)
    |> Map.to_list()
    # sort by count, descending
    |> Enum.sort_by(fn {count, _} -> count end, &>=/2)
    |> add_rank()
  end

  defp select_count([count, _id, _title]), do: count
  defp id_title_tuple([_count, id, title]), do: {id, title}

  # takes a list of {count, [{id, title}, ...]}
  # and adds a rank, according to the subscribers count
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
