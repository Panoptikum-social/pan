defmodule PanWeb.Live.Category.StatsShow do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin

  import PanWeb.Router.Helpers
  alias PanWeb.{Category, Podcast, Language}
  alias PanWeb.Surface.{Panel, PanelHeading, Icon, CategoryButton}
  alias Surface.Components.Link

  def mount(%{"id" => id}, session, socket) do
    socket = assign(socket, current_user_id: session["user_id"])
    language = nil
    page = 1
    per_page = 100

    if Category.by_id_exists?(id) do
      category = Category.get_with_children_and_parent(id)
      languages = Language.get_by_category_id(category.id)

      {:ok,
       assign(socket,
         category: category,
         page_title: category.title <> " (Category)",
         languages: languages,
         language: language,
         page: page,
         per_page: per_page,
         podcasts: Podcast.get_all_by_category_id_and_language(category.id),
         update_action: "append"
       )}
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  def amount(language_name, podcasts) do
    podcasts
    |> Enum.filter(fn p -> p.language_name == language_name end)
    |> length
  end

  def render(%{error: "not_found"} = assigns) do
    ~F"""
    <div class="m-12">
      A category with this id could not be found
    </div>
    """
  end

  def render(assigns) do
    ~F"""
    <Panel purpose="category"
           class="m-4">
      <PanelHeading>
        <Link to={category_frontend_path(@socket, :index)}
              class="hover:text-blue-400">
          <Icon name="folder-heroicons-outline" /> Panoptikum
        </Link> /
        {#if @category.parent}
          <Link to={category_frontend_path(@socket, :show, @category.parent)}
                class="hover:text-blue-400">
            <Icon name="folder-heroicons-outline" /> {@category.parent.title}
          </Link> /
        {/if}
        <Icon name="folder-open-heroicons-outline" /> {@category. title}
      </PanelHeading>

      <div aria-label="panel-body" class="p-4">
        <div :if={@category.children != []} class="flex flex-wrap">
          {#for subcategory <- @category.children}
            <CategoryButton for={subcategory}
                            class="mr-2 mb-2" />
          {/for}
        </div>

        <h3 class="pt-4 text-xl">Click on a language to filter</h3>

        <div class="flex flex-wrap py-4">
          {#for language <- @languages}
            <div class="mr-8">
              {language.emoji || "🏳️"} &nbsp; {language.name || "Language unknown"}
              {amount(language.name, @podcasts)}
            </div>
          {/for}
        </div>

        {#if @language}
          <h2 class="text-2xl mt-4">
            {amount(@language.name, @podcasts)} Podcasts in {@language.name} {@language.emoji}
          </h2>
          {#else}
            <h2 class="text-2xl mt-4">Podcasts in any language</h2>
          {/if}

        <div class="grid sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 py-4">
          Podcast Buttons not shown in this view.
        </div>
      </div>
    </Panel>
    """
  end
end
