defmodule PanWeb.Live.Category.StatsTree do
  use PanWeb, :live_view
  alias PanWeb.Category
  alias PanWeb.Component.CategoryButton

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       categories: Category.stats_tree(),
       page_title: "Category Tree with Statistics"
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="lg:columns-2 xl:columns-3 2xl:columns-4 p-4">
      <div :for={{category, counter} <- @categories |> Enum.with_index} class="avoid-column-break">
        <p>
          <CategoryButton.render for={category} index_on_page={counter} large />
          <span class="align-top">{length category.podcasts}</span>
        </p>
        <p class="mt-6 -mx-0.5">
          <%= for subcategory <- category.children do %>
            <nobr>
              <CategoryButton.render for={subcategory} index_on_page={1} truncate/>
              <span class="align-top">{length subcategory.podcasts}</span>
            </nobr>
            &nbsp;
          <% end %>
        </p>
        <hr class="myt-4 border-t border-gray-lighter break-before-avoid" />
      </div>
    </div>
    """
  end
end
