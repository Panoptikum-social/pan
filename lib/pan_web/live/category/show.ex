defmodule PanWeb.Live.Category.Show do
  use Surface.LiveView
  import PanWeb.Router.Helpers
  alias PanWeb.Category
  alias PanWeb.Surface.{Panel, PanelHeading, Icon, CategoryButton, PodcastButton, LinkButton}

  def mount(%{"id" => id}, session, socket) do
    socket = assign(socket, current_user_id: session["user_id"])

    case Category.by_id_exists?(id) do
      true -> {:ok, assign(socket, Category.get_with_children_parent_and_podcasts(id))}
      false -> {:ok, assign(socket, error: "not_found")}
    end
  end

  def language(podcast) do
    podcast.language_name || "Language unknown"
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
    <Panel :if={{ @category.parent && @category.parent.title == "👩 👨 Community" }}
           purpose="episode"
           heading="Welcome to the Test Laboratory!"
           class="mb-4">

      <div aria-label="panel-body" class="p-4">
        <p>We are currently testing different  and additional views for community categories!<br/>
          Wanna give it a try?</p>
        <p class="mt-4 leading-8">
          <LinkButton href={{ category_frontend_path @socket, :latest_episodes, @category }}
                      title="Latest episodes"
                      class="bg-mint text-white hover:bg-mint-light" />&nbsp;
          gives you a timeline view starting with the most current episode within this category.<br/>
          <LinkButton href={{ category_frontend_path @socket, :categorized, @category }}
                      title="Categorized"
                      class="bg-mint text-white hover:bg-mint-light" />&nbsp;
          sorts the podcasts within this categories by the other categories, they are listed in.<br/>
          Further more we display a info card with the most relevant information on this podcast.
        </p>
      </div>
    </Panel>

    <Panel purpose="category">
      <PanelHeading>
        <a href={{ category_frontend_path(@socket, :index) }}
          class="hover:text-blue-400">
          <Icon name="folder" /> Panoptikum
        </a> /
        <If condition={{ @category.parent }}>
          <a href={{ category_frontend_path(@socket, :show, @category.parent) }}
            class="hover:text-blue-400">
            <Icon name="folder" /> {{ @category.parent.title }}
          </a> /
        </If>
        <Icon name="folder-open" /> {{ @category. title }}
      </PanelHeading>

      <div aria-label="panel-body" class="p-4 divide-y-2 divide-light-gray">
        <div :if={{ @category.children != [] }} class="flex flex-wrap">
          <CategoryButton :for={{ subcategory <- @category.children }}
                          for={{ subcategory }}
                          class="mx-2" />
        </div>

        <div class="flex flex-wrap py-4">
          <div :for={{ prototype <- @podcasts
                                    |> Enum.uniq_by(fn p -> p.language_name end)
                                    |> Enum.sort_by(fn p -> p.language_name end) }}
                class="mx-2">
            {{ prototype.language_emoji || "🏳️" }} &nbsp;
            <a id={{ "lang#" <> language(prototype) }}
                href={{ "#" <> language(prototype) }}>
              {{ language(prototype) }}
            </a>
          </div>
        </div>

        <div :for={{ prototype <- @podcasts
                                  |> Enum.uniq_by(fn p -> p.language_name end)
                                  |> Enum.sort_by(fn p -> p.language_name end) }}>
          <h2 id={{ language(prototype) }}
              class="text-2xl mt-4">
            {{ language(prototype) }}
          </h2>
          <div class="grid sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 py-4">
            <PodcastButton :for={{ podcast <- Enum.filter(@podcasts, fn p -> p.language_name == prototype.language_name end) }}
                            for={{ podcast }}
                            truncate={{ true }}
                            class="m-2"/>
          </div>
        </div>
      </div>

      <If condition={{ @current_user_id }}>
        logged in with user_id {{ @current_user_id }}
      <!-- #FIXME! like_or_unlike(@current_user.id, @category.id) --> &nbsp;
      <!-- #FIXME! follow_or_unfollow(@current_user.id, @category.id) -->
      </If>

    </Panel>
    """
  end
end
