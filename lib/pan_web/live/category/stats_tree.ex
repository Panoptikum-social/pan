defmodule PanWeb.Live.Category.StatsTree do
  use Surface.LiveView
  alias PanWeb.Category
  alias PanWeb.Surface.CategoryButton

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.stats_tree)}
  end

  def render(assigns) do
    ~F"""
    <div class="up-to-four-columns">
      {#for {category, counter} <- @categories |> Enum.with_index}
        <div class="inline-block">
          <p class="my-4">
            <CategoryButton for={category} index_on_page={counter} large />
            <span class="align-top">{length category.podcasts}</span>
          </p>
          <p class="my-4">
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
