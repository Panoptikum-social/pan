defmodule PanWeb.Live.Category.Show do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin

  import PanWeb.Router.Helpers
  alias PanWeb.Category
  alias PanWeb.Live.Category.FollowButton
  alias PanWeb.Surface.{Panel, PanelHeading, Icon, CategoryButton, PodcastButton, LinkButton, LikeButton}
  alias Surface.Components.Link

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
        <p>We are currently testing different  and additional views for community categories!<br/>
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

      <div aria-label="panel-body" class="p-4 divide-y-2 divide-gray-lighter">
        <div :if={@category.children != []} class="flex flex-wrap">
          {#for subcategory <- @category.children}
            <CategoryButton for={subcategory}
                            class="mx-2" />
          {/for}
        </div>

        <div class="flex flex-wrap py-4">
          {#for prototype <- @podcasts |> Enum.uniq_by(fn p -> p.language_name end)
                                       |> Enum.sort_by(fn p -> p.language_name end)}
            <div class="mx-2">
              {prototype.language_emoji || "🏳️"} &nbsp;
              <Link opts={id: "lang#" <> language(prototype)}
                    to={"#" <> language(prototype)}
                    label= {language(prototype)} />
            </div>
          {/for}
        </div>

        {#for prototype <- @podcasts |> Enum.uniq_by(fn p -> p.language_name end)
                                     |> Enum.sort_by(fn p -> p.language_name end)}
          <div>
            <h2 id={language(prototype)}
                class="text-2xl mt-4">
              {language(prototype)}
            </h2>
            <div class="grid sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 py-4">
              {#for podcast <- Enum.filter(@podcasts, fn p -> p.language_name == prototype.language_name end)}
                <PodcastButton for={podcast} class="m-2" truncate/>
              {/for}
            </div>
          </div>
        {/for}
      </div>

      <div :if={@current_user_id} class="m-4">
        <LikeButton id="like_button"
                    current_user_id={@current_user_id}
                    model={Category}
                    instance={@category}/> &nbsp;
        <FollowButton id="follow_button"
                      current_user_id={@current_user_id}
                      category={@category}/> &nbsp;
      </div>

    </Panel>
    """
  end
end
