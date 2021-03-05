defmodule PanWeb.Live.Category.StatsTree do
  use Surface.LiveView
  alias PanWeb.Category
  alias PanWeb.Surface.CategoryButton

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.stats_tree())}
  end

  def render(assigns) do
    ~H"""
    <div class="up-to-four-columns m-4">
      <div :for.with_index={{ {category, counter} <- @categories }}
           class="block">
        <div class="my-4 block">
          <CategoryButton for={{ category }}
                          large=true
                          index_on_page={{ counter }} />
          <div class="align-top inline">{{ length category.podcasts }}</div>
        </div>
        <div class="my-2 block">
          <For each={{ subcategory <- category.children }}>
            <CategoryButton for={{ subcategory }}
                            index_on_page=1
                            truncate= {{ true }}/>
            <div class="align-top inline">{{ length subcategory.podcasts }}</div>
            &nbsp;
          </For>
        </div>
        <hr class="myt-4 border-t-1 border-coolGray-200" style="break-before: avoid;" />
      </div>
    </div>
    """
  end
end
