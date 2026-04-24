defmodule PanWeb.Live.Category.Show do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin

  alias PanWeb.{Category, Podcast, Language}

  alias PanWeb.Component.Panel
  alias PanWeb.Component.FollowButton
  alias PanWeb.Component.LikeButton
  alias PanWeb.Component.CategoryButton
  alias PanWeb.Component.PodcastButton
  alias PanWeb.Component.LinkButton
  alias PanWeb.Component.Icon

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
    ~H"""
    <div class="m-12">
      A category with this id could not be found
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <Panel.render :if={@category.parent && @category.parent.title == "👩 👨 Community"}
           purpose="episode"
           heading="Welcome to the Test Laboratory!"
           class="m-4">
      <div aria-label="panel-body" class="p-4">
        <p>We are currently testing different and additional views for community categories!<br/>
          Wanna give it a try?</p>
        <p class="mt-4 leading-8">
          <LinkButton.render to={category_frontend_path(@socket, :latest_episodes, @category)}
                      title="Latest episodes"
                      class="btn-primary" />&nbsp;
          gives you a timeline view starting with the most current episode within this category.<br/>
          <LinkButton.render to={category_frontend_path(@socket, :categorized, @category)}
                      title="Categorized"
                      class="btn-primary" />&nbsp;
          sorts the podcasts within this categories by the other categories, they are listed in.<br/>
          Further more we display a info card with the most relevant information on this podcast.
        </p>
      </div>
    </Panel.render>

    <Panel.render purpose="category" class="m-4">
      <:panel_heading>
        <.link href={category_frontend_path(@socket, :index)} class="hover:text-blue-400">
          <Icon.render name="folder-heroicons-outline" /> Panoptikum
        </.link> /
        <span :if={@category.parent}>
          <.link href={category_frontend_path(@socket, :show, @category.parent)}
                class="hover:text-blue-400">
            <Icon.render name="folder-heroicons-outline" /> {@category.parent.title}
          </.link> /
        </span>
        <Icon.render name="folder-open-heroicons-outline" /> {@category.title}
      </:panel_heading>

      <div :if={@current_user_id} class="m-4">
        <.live_component module={LikeButton} id="like_button"
                    current_user_id={@current_user_id}
                    model={Category}
                    instance={@category}/> &nbsp;
        <.live_component module={FollowButton} id="follow_button"
                      current_user_id={@current_user_id}
                      model={Category}
                      instance={@category}/> &nbsp;
      </div>
      <div aria-label="panel-body" class="p-4">
        <div :if={@category.children != []} class="flex flex-wrap">
          <CategoryButton.render :for={subcategory <- @category.children}
                          for={subcategory}
                          class="mr-2 mb-2" />
        </div>

        <h3 class="pt-4 text-xl">Click on a language to filter</h3>

        <div class="flex flex-wrap py-4">
          <a :for={language <- @languages}
             href="#"
             phx-click="set-language-filter"
             phx-value-language_id={language.id}
             class="text-link hover:text-link-dark mx-2">
            {language.emoji || "🏳️"} &nbsp; {language.name || "Language unknown"}
          </a>
        </div>

        <%= if @language do %>
          <div class="float-right">
            <a href="#"
              phx-click="reset-language-filter"
              class="text-link hover:text-link-dark mx-2">🗑️ Clear language filter</a>
          </div>
          <h2 class="text-2xl mt-4">
            Podcasts in {@language.name} {@language.emoji}
          </h2>
        <% else %>
          <h2 class="text-2xl mt-4">Podcasts in any language</h2>
        <% end %>

        <div id="podcast_grid"
             phx-update={@update_action}
             class="grid sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 py-4">
          <PodcastButton.render :for={podcast <- @podcasts} for={podcast} class="m-2" truncate/>
        </div>

        <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
      </div>
    </Panel.render>
    """
  end
end
