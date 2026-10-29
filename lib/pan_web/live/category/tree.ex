defmodule PanWeb.Live.Category.Tree do
  use PanWeb, :live_view
  alias PanWeb.Category
  alias PanWeb.Component.CategoryLink

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.public_tree(), page_title: "Category Tree")}
  end

  def render(assigns) do
    ~H"""
    <p class="px-4 pt-4 text-sm">
      <.link
        navigate={category_frontend_path(@socket, :stats)}
        class="underline hover:text-primary"
      >
        Category tree with podcast numbers
      </.link>
    </p>
    <div class="lg:columns-2 xl:columns-3 2xl:columns-4 w-full p-4">
      <div :for={category <- @categories} class="avoid-column-break">
        <CategoryLink.render for={category} color={category.color} large />
        <p class="mt-3 flex flex-wrap gap-x-4 gap-y-1.5">
          <CategoryLink.render
            :for={subcategory <- category.children}
            for={subcategory}
            color={category.color}
          />
        </p>
        <hr class="w-full my-4 border-t border-base-300 break-before-avoid" />
      </div>
    </div>
    """
  end
end
