defmodule PanWeb.Live.Category.StatsShow do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin

  alias PanWeb.{Category, Podcast, Language}
  alias PanWeb.Component.Panel
  alias PanWeb.Component.LinkButton
  alias PanWeb.Component.Icon

  def mount(%{"id" => id}, session, socket) do
    socket = assign(socket, current_user_id: session["user_id"])
    language = nil
    page = 1
    per_page = 100

    id = PanWeb.PathId.to_integer!(id, Category)

    category =
      Category.get_with_children_and_parent(id) ||
        raise(Ecto.NoResultsError, queryable: Category)

    languages = Language.get_by_category_id(category.id)

    {:ok,
     assign(socket,
       category: category,
       page_title:
         dgettext("frontend", "%{title} (Category)",
           title: PanWeb.Translations.category_title(category)
         ),
       languages: languages,
       language: language,
       page: page,
       per_page: per_page,
       podcasts: Podcast.get_all_by_category_id_and_language(category.id),
       update_action: "append"
     )}
  end

  def amount(language_name, podcasts) do
    podcasts
    |> Enum.filter(fn p -> p.language_name == language_name end)
    |> length
  end

  def render(assigns) do
    ~H"""
    <Panel.render purpose="category" class="m-4">
      <:panel_heading>
        <.link href={category_frontend_path(@socket, :index)} class="hover:text-blue-400">
          <Icon.render name="folder" /> Panoptikum
        </.link>
        /
        <span :if={@category.parent}>
          <.link
            href={category_frontend_path(@socket, :show_stats, @category.parent)}
            class="hover:text-blue-400"
          >
            <Icon.render name="folder" /> {PanWeb.Translations.category_title(@category.parent)}
          </.link>
          /
        </span>
        <Icon.render name="folder-open" /> {PanWeb.Translations.category_title(@category)}
      </:panel_heading>

      <div aria-label="panel-body" class="p-4">
        <div :if={@category.children != []} class="flex flex-wrap">
          <LinkButton.render
            :for={subcategory <- @category.children}
            to={category_frontend_path(@socket, :show_stats, subcategory.id)}
            class="btn-outline mr-2 mb-2"
            icon="folder"
            title={PanWeb.Translations.category_title(subcategory)}
            truncate={true}
          />
        </div>

        <h3 class="pt-4 text-xl">{dgettext("frontend", "Click on a language to filter")}</h3>

        <div class="flex flex-wrap py-4">
          <div :for={language <- @languages} class="mr-8">
            {language.emoji || "🏳️"} &nbsp; {if language.name,
              do: PanWeb.Translations.language_name(language),
              else: dgettext("frontend", "Language unknown")}
            {amount(language.name, @podcasts)}
          </div>
        </div>

        <%= if @language do %>
          <h2 class="text-2xl mt-4">
            {dgettext("frontend", "%{count} Podcasts in %{language}",
              count: amount(@language.name, @podcasts),
              language: PanWeb.Translations.language_name(@language)
            )} {@language.emoji}
          </h2>
        <% else %>
          <h2 class="text-2xl mt-4">{dgettext("frontend", "Podcasts in any language")}</h2>
        <% end %>

        <div class="grid sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 py-4">
          {dgettext("frontend", "Podcast Buttons not shown in this view.")}
        </div>
      </div>
    </Panel.render>
    """
  end
end
