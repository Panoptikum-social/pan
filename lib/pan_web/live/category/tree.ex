defmodule PanWeb.Live.Category.Tree do
  use Surface.LiveView
  alias PanWeb.Category
  alias PanWeb.Surface.CategoryButton

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.tree())}
  end

  def render(assigns) do
    ~H"""
    <div class="up-to-four-columns m-4">
      <div :for.with_index={{ {category, counter} <- @categories }}
           class="inline-block">
        <p class="my-4">
          <CategoryButton for={{ category }}
                          large=true
                          index_on_page={{ counter }} />
        </p>
        <p class="my-2">
          <For each={{ subcategory <- category.children }}>
            <CategoryButton for={{ subcategory }}
                            index_on_page=1
                            truncate= {{ true }}/> &nbsp;
          </For>
        </p>
        <hr class="mt-4 border-t-1 border-coolGray-200" style="break-before: avoid;" />
      </div>
    </div>
    """
  end
end
