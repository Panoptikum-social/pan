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
    <p class="px-4 pt-4 text-sm">
      Podcasts per category.
      <.link
        navigate={category_frontend_path(@socket, :index)}
        class="text-link hover:text-link-dark underline"
      >
        Category tree without numbers
      </.link>
    </p>
    <div class="lg:columns-2 xl:columns-3 2xl:columns-4 w-full p-4">
      <div :for={{category, counter} <- Enum.with_index(@categories)} class="avoid-column-break">
        <p>
          <CategoryButton.render
            for={category}
            index_on_page={counter}
            large
            count={length(category.podcasts)}
          />
        </p>
        <p class="mt-6 -mx-0.5">
          <CategoryButton.render
            :for={subcategory <- category.children}
            for={subcategory}
            index_on_page={counter}
            tint
            count={length(subcategory.podcasts)}
            class="px-1.5 py-0.5 mx-0.5 my-0.5"
            truncate
          />
        </p>
        <hr class="w-full mt-4 border-t border-gray-lightest break-before-avoid" />
      </div>
    </div>
    """
  end
end
