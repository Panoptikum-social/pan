defmodule PanWeb.Surface.TopList do
  use Surface.Component
  alias PanWeb.Surface.{PodcastButton, Icon}

  prop items, :list, required: true
  prop icon, :string, required: false, default: "heart"
  prop purpose, :string, required: false

  def prepare_for_toplist(items) do
    items
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
  defp add_rank(counts_and_items) when is_list(counts_and_items) do
    # start loop with an initial rank of 1 and an empty accumulator
    add_rank(counts_and_items, {1, []})
  end

  # recursive loop
  defp add_rank([{count, items} | tail], {rank, acc}) do
    next_rank = rank + length(items)
    next_acc = acc ++ [{rank, count, items}]

    # next round
    add_rank(tail, {next_rank, next_acc})
  end

  # end of list, end loop and return acc
  defp add_rank([], {_rank, acc}), do: acc

  def render(assigns) do
    ~H"""
    <table class="w-full table-fixed">
      <tr :for={{ {rank, count, items} <- prepare_for_toplist(@items) }}
          class="odd:bg-very-light-gray align-top" >
        <td class="text-right py-2 w-10">
          {{ rank }}.
        </td>
        <td class="px-4">
          <For each={{ {id, title} <- items }}>
            <p>
              <PodcastButton :if={{ @purpose == "podcast" }}
                              id={{ id }}
                              title={{ title}}
                              truncate={{ true }} />
            </p>
          </For>
        </td>
        <td class="text-right py-2 w-20">
          {{ count }} <Icon name={{ @icon }} />&nbsp;
        </td>
      </tr>
    </table>
    """
  end
end
