defmodule PanWeb.Surface.Admin.Pagination do
  use Surface.Component
  alias PanWeb.Surface.Admin.PaginationLink

  prop(page, :integer, required: true)
  prop(per_page, :integer, required: true)
  prop(nr_of_pages, :integer, required: true)
  prop(nr_of_unfiltered, :integer, required: true)
  prop(nr_of_filtered, :integer, required: true)
  prop(class, :css_class, required: false)
  prop(click, :event, required: true)

  def format(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.codepoints()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end

  def render(assigns) do
    ~F"""
    <div class={"flex flex-col sm:flex-row items-center justify-between", @class}>
      <div class="flex items-center space-x-2">
        <PaginationLink :if={@page > 1}
                        click={@click}
                        page={@page - 1}
                        class="rounded-l">
          Previous
        </PaginationLink>
        {#for i <- 1..@page}
          <PaginationLink :if={i != @page}
                          click={@click}
                          page={i}
                          class={"rounded-l-lg": i==1}>
            {i}
          </PaginationLink>
          <span :if={i == @page}>
            Page {i} of {if @nr_of_pages > 0, do: @nr_of_pages, else: "?? "}
          </span>
        {/for}
        <PaginationLink :if={@page < @nr_of_pages}
                        click={@click}
                        page={@page + 1}
                        class="rounded-r">
          Next
        </PaginationLink>
      </div>

      <div class="sm:border-l border-gray px-4 py-1 text-center">
        Records {(@page - 1) * @per_page + 1} to {min((@page * @per_page), @nr_of_filtered)} of
        {if @nr_of_filtered > 0, do: format(@nr_of_filtered), else: "??"}
        ({if @nr_of_unfiltered, do: format(@nr_of_unfiltered), else: "??"}&nbsp;unfiltered)
      </div>
    </div>
    """
  end
end
