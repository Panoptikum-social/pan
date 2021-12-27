defmodule PanWeb.Live.Category.Tree do
  use Surface.LiveView
  alias PanWeb.Category
  alias PanWeb.Surface.CategoryButton

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.tree)}
  end

  def render(assigns) do
    ~F"""
    <div class="up-to-four-columns w-full">
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
