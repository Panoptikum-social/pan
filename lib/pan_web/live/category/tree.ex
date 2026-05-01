defmodule PanWeb.Live.Category.Tree do
  use PanWeb, :live_view
  alias PanWeb.Category
  alias PanWeb.Component.CategoryButton

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.tree(), page_title: "Category Tree")}
  end

  def render(assigns) do
    ~H"""
    <div class="lg:columns-2 xl:columns-3 2xl:columns-4 w-full p-4">
      <div :for={{category, counter} <- Enum.with_index(@categories)} class="avoid-column-break">
        <p>
          <CategoryButton.render for={category} index_on_page={counter} large={true} />
        </p>
        <p class="mt-6 -mx-0.5">
          <CategoryButton.render :for={subcategory <- category.children}
                                 for={subcategory}
                                 class="px-1.5 py-0.5 mx-0.5 my-0.5"
                                 truncate={true} />
        </p>
        <hr class="w-full mt-4 border-t border-gray-lightest break-before-avoid" />
      </div>
    </div>
    """
  end
end
