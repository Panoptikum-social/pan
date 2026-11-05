defmodule PanWeb.Admin.Pagination do
  use PanWeb, :html
  alias PanWeb.Admin.PaginationLink

  def format(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.codepoints()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end

  attr :page, :integer, required: true
  attr :per_page, :integer, required: true
  attr :nr_of_pages, :integer, required: true
  attr :nr_of_unfiltered, :integer, required: true
  attr :nr_of_filtered, :integer, required: true
  attr :class, :string, default: nil
  attr :click, :string, required: true
  attr :target, :any, default: nil

  def render(assigns) do
    ~H"""
    <div class={["flex flex-col sm:flex-row items-center justify-between", @class]}>
      <div class="flex items-center space-x-2">
        <PaginationLink.render
          :if={@page > 1}
          click={@click}
          target={@target}
          page={@page - 1}
          class="rounded-l"
        >
          {dgettext("moderation", "Previous")}
        </PaginationLink.render>
        <%= for i <- 1..@page do %>
          <PaginationLink.render
            :if={i != @page}
            click={@click}
            target={@target}
            page={i}
            class={i == 1 && "rounded-l-lg"}
          >
            {i}
          </PaginationLink.render>
          <span :if={i == @page}>
            {dgettext("moderation", "Page %{page} of %{pages}",
              page: i,
              pages: if(@nr_of_pages > 0, do: @nr_of_pages, else: "??")
            )}
          </span>
        <% end %>
        <PaginationLink.render
          :if={@page < @nr_of_pages}
          click={@click}
          target={@target}
          page={@page + 1}
          class="rounded-r"
        >
          {dgettext("moderation", "Next")}
        </PaginationLink.render>
      </div>

      <div class="sm:border-l border-base-300 px-4 py-1 text-center">
        {dgettext(
          "moderation",
          "Records %{from} to %{to} of %{filtered} (%{unfiltered} unfiltered)",
          from: (@page - 1) * @per_page + 1,
          to: min(@page * @per_page, @nr_of_filtered),
          filtered: if(@nr_of_filtered > 0, do: format(@nr_of_filtered), else: "??"),
          unfiltered: if(@nr_of_unfiltered, do: format(@nr_of_unfiltered), else: "??")
        )}
      </div>
    </div>
    """
  end
end
