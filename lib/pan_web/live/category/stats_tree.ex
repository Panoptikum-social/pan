defmodule PanWeb.Live.Category.StatsTree do
  use Surface.LiveView
  alias PanWeb.Category
  alias PanWeb.Surface.CategoryButton

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.stats_tree, page_title: "Category Tree with Statistics")}
  end

  def render(assigns) do
    ~F"""
    <div class="lg:columns-2 xl:columns-3 2xl:columns-4 p-4">
      {#for {category, counter} <- @categories |> Enum.with_index}
      <div class="avoid-column-break">
          <p>
            <CategoryButton for={category} index_on_page={counter} large />
            <span class="align-top">{length category.podcasts}</span>
          </p>
          <p class="mt-6 -mx-0.5">
            {#for subcategory <- category.children}
              <nobr>
                <CategoryButton for={subcategory} index_on_page={1} truncate/>
                <span class="align-top">{length subcategory.podcasts}</span>
              </nobr>
              &nbsp;
            {/for}
          </p>
          <hr class="myt-4 border-t-1 border-gray-lighter" style="break-before: avoid;" />
        </div>
      {/for}
    </div>
    """
  end
end
