defmodule PanWeb.Live.Category.StatsTree do
  use Surface.LiveView
  alias PanWeb.Category
  alias PanWeb.Surface.CategoryButton

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.stats_tree())}
  end

  def render(assigns) do
    ~H"""
    <div class="up-to-four-columns">
      <div :for.with_index={{ {category, counter} <- @categories }}
           class="inline-block">
        <p class="my-4">
          <CategoryButton for={{ category }}
                          large=true
                          index_on_page={{ counter }} />
          <span class="align-top">{{ length category.podcasts }}</span>
        </p>
        <p class="my-4">
          <For each={{ subcategory <- category.children }}>
            <nobr>
              <CategoryButton for={{ subcategory }}
                              index_on_page=1
                              truncate={{ true }}/>
              <span class="align-top">{{ length subcategory.podcasts }}</span>
            </nobr>
            &nbsp;
          </For>
        </p>
        <hr class="myt-4 border-t-1 border-gray-lighter" style="break-before: avoid;" />
      </div>
    </div>
    """
  end
end
