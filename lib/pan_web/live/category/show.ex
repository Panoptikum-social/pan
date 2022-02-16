defmodule PanWeb.Live.Category.Show do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin

  import PanWeb.Router.Helpers
  alias PanWeb.{Category, Podcast, Language}

  alias PanWeb.Surface.{
    Panel,
    PanelHeading,
    Icon,
    CategoryButton,
    PodcastButton,
    LinkButton,
    LikeButton,
    FollowButton
  }

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
         update_action: "append"
       )
       |> fetch()}
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  defp fetch(
         %{
           assigns: %{
             page: page,
             per_page: per_page,
             category: category,
             language: language
           }
         } = socket
       ) do
    podcasts = Podcast.get_by_category_id_and_language(category.id, language, page, per_page)
    assign(socket, podcasts: podcasts)
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1, update_action: "append") |> fetch()}
  end

  def handle_event("set-language-filter", %{"language_id" => language_id}, socket) do
    {:noreply,
     assign(socket, language: Language.get_by_id(language_id), page: 1, update_action: "replace")
     |> fetch()}
  end

  def handle_event("reset-language-filter", _params, socket) do
    {:noreply,
     assign(socket, language: nil, page: 1, update_action: "replace")
     |> fetch()}
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
    <Panel :if={@category.parent && @category.parent.title == "👩 👨 Community"}
           purpose="episode"
           heading="Welcome to the Test Laboratory!"
           class="m-4">

      <div aria-label="panel-body" class="p-4">
        <p>We are currently testing different and additional views for community categories!<br/>
          Wanna give it a try?</p>
        <p class="mt-4 leading-8">
          <LinkButton to={category_frontend_path @socket, :latest_episodes, @category}
                      title="Latest episodes"
                      class="bg-mint text-white hover:bg-mint-light" />&nbsp;
          gives you a timeline view starting with the most current episode within this category.<br/>
          <LinkButton to={category_frontend_path @socket, :categorized, @category}
                      title="Categorized"
                      class="bg-mint text-white hover:bg-mint-light" />&nbsp;
          sorts the podcasts within this categories by the other categories, they are listed in.<br/>
          Further more we display a info card with the most relevant information on this podcast.
        </p>
      </div>
    </Panel>

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

      <div :if={@current_user_id} class="m-4">
        <LikeButton id="like_button"
                    current_user_id={@current_user_id}
                    model={Category}
                    instance={@category}/> &nbsp;
        <FollowButton id="follow_button"
                      current_user_id={@current_user_id}
                      model={Category}
                      instance={@category}/> &nbsp;
      </div>
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
            <a href="#"
               :on-click="set-language-filter"
               phx-value-language_id={language.id}
               class="text-link hover: text-link-dark mx-2">
              {language.emoji || "🏳️"} &nbsp; {language.name || "Language unknown"}
            </a>
          {/for}
        </div>

        {#if @language}
          <div class="float-right">
            <a href="#"
              :on-click="reset-language-filter"
              class="text-link hover: text-link-dark mx-2">🗑️ Clear language filter</a>
          </div>
          <h2 class="text-2xl mt-4">
            Podcasts in {@language.name} {@language.emoji}
          </h2>
          {#else}
            <h2 class="text-2xl mt-4">Podcasts in any language</h2>
          {/if}

        <div id="podcast_grid"
             phx-update={@update_action}
             class="grid sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 py-4">
          {#for podcast <- @podcasts}
            <PodcastButton for={podcast} class="m-2" truncate/>
          {/for}
        </div>

      <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
      </div>
    </Panel>
    """
  end
end
