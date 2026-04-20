defmodule PanWeb.Surface.Admin.Pagination do
  use PanWeb, :html
  alias PanWeb.Surface.Admin.PaginationLink

  attr :page, :integer, required: true
  attr :per_page, :integer, required: true
  attr :nr_of_pages, :integer, required: true
  attr :nr_of_unfiltered, :integer, required: true
  attr :nr_of_filtered, :integer, required: true
  attr :class, :string, default: nil
  attr :click, :string, required: true
  attr :target, :any, default: nil

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
    ~H"""
    <div class={["flex flex-col sm:flex-row items-center justify-between", @class]}>
      <div class="flex items-center space-x-2">
        <PaginationLink.render :if={@page > 1}
                               click={@click}
                               target={@target}
                               page={@page - 1}
                               class="rounded-l">
          Previous
        </PaginationLink.render>
        <%= for i <- 1..@page do %>
          <PaginationLink.render :if={i != @page}
                                 click={@click}
                               target={@target}
                                 page={i}
                                 class={i == 1 && "rounded-l-lg"}>
            {i}
          </PaginationLink.render>
          <span :if={i == @page}>
            Page {i} of {if @nr_of_pages > 0, do: @nr_of_pages, else: "?? "}
          </span>
        <% end %>
        <PaginationLink.render :if={@page < @nr_of_pages}
                               click={@click}
                               target={@target}
                               page={@page + 1}
                               class="rounded-r">
          Next
        </PaginationLink.render>
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
