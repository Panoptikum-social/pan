defmodule PanWeb.Live.Category.Tree do
  use Surface.LiveView
  alias PanWeb.Category
  alias PanWeb.Surface.CategoryButton

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.tree, page_title: "Category Tree")}
  end

  def render(assigns) do
    ~F"""
    <div class="lg:columns-2 xl:columns-3 2xl:columns-4 w-full p-4">
      {#for {category, counter} <- @categories |> Enum.with_index}
        <div class="mx-2 my-4">
          <p>
            <CategoryButton for={category} index_on_page={counter} large/>
          </p>
          <p class="mt-6 -mx-0.5">
            {#for subcategory <- category.children}
              <CategoryButton for={subcategory}
                              class="px-1.5 py-0.5 mx-0.5" truncate />
            {/for}
          </p>
          <hr class="w-full mt-4 border-t-1 border-gray-lightest" style="break-before: avoid;" />
        </div>
      {/for}
    </div>
    """
  end
end
