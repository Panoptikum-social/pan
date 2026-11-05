defmodule PanWeb.Live.Admin.Translations do
  use PanWeb, :admin_live_view
  alias PanWeb.{Category, Endpoint, Language}

  # German category titles and language names (Project #4, #585, #593).
  # One field per row; an empty field removes the translation, the page then
  # falls back to the English title or name.
  @tabs [{"categories", "Categories"}, {"languages", "Languages"}]
  @locale "de"

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(tabs: @tabs, locale: @locale, only_missing: false) |> load()}
  end

  def handle_params(%{"tab" => "languages"}, _uri, socket),
    do: {:noreply, assign(socket, tab: "languages")}

  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, tab: "categories")}

  defp load(socket),
    do: assign(socket, categories: Category.translation_list(), languages: Language.grouped())

  def handle_event("only_missing", params, socket),
    do: {:noreply, assign(socket, only_missing: params["only_missing"] == "true")}

  def handle_event("save_category", %{"category_id" => id, "text" => text}, socket) do
    Category.put_translation(String.to_integer(id), @locale, text)
    {:noreply, socket |> load() |> put_flash(:info, "Category #{id} saved.")}
  end

  def handle_event("save_language", %{"ids" => ids, "text" => text}, socket) do
    ids = ids |> String.split(",") |> Enum.map(&String.to_integer/1)
    Language.put_translation(ids, @locale, text)
    {:noreply, socket |> load() |> put_flash(:info, "Language saved.")}
  end

  defp missing?(translations, locale), do: translations[locale] in [nil, ""]

  defp visible(rows, true, locale), do: Enum.filter(rows, &missing?(&1.translations, locale))
  defp visible(rows, false, _locale), do: rows

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl m-4">Translations (German)</h1>

    <p class="mx-4 max-w-3xl text-sm">
      Category titles and language names shown to German users. An empty field removes the
      translation; the English title or name is shown then.
    </p>

    <div role="tablist" class="tabs tabs-border mx-4 mt-4">
      <.link
        :for={{key, label} <- @tabs}
        patch={translations_path(Endpoint, :translations, tab: key)}
        role="tab"
        class={["tab", key == @tab && "tab-active"]}
      >
        {label}
        <span class="badge badge-sm badge-outline badge-neutral ml-2">
          {key |> rows(@categories, @languages) |> Enum.count(&missing?(&1.translations, @locale))} missing
        </span>
      </.link>
    </div>

    <form phx-change="only_missing" class="m-4">
      <label class="flex items-center gap-2 cursor-pointer">
        <input type="hidden" name="only_missing" value="false" />
        <input
          type="checkbox"
          name="only_missing"
          value="true"
          checked={@only_missing}
          class="checkbox checkbox-sm"
        /> Only rows without German
      </label>
    </form>

    <table :if={@tab == "categories"} class="table table-sm m-4 w-auto">
      <thead>
        <tr>
          <th>Category</th>
          <th>German</th>
        </tr>
      </thead>
      <tbody>
        <tr
          :for={category <- visible(@categories, @only_missing, @locale)}
          id={"category-#{category.id}"}
        >
          <td>
            <span :if={category.parent_title} class="text-base-content/70">
              {category.parent_title} ›
            </span>
            <span class={!category.parent_title && "font-semibold"}>{category.title}</span>
          </td>
          <td>
            <form phx-submit="save_category" class="flex gap-2">
              <input type="hidden" name="category_id" value={category.id} />
              <input
                type="text"
                name="text"
                value={category.translations[@locale]}
                class={[
                  "input input-sm w-72",
                  missing?(category.translations, @locale) && "input-warning"
                ]}
              />
              <button type="submit" class="btn btn-sm btn-primary">Save</button>
            </form>
          </td>
        </tr>
      </tbody>
    </table>

    <table :if={@tab == "languages"} class="table table-sm m-4 w-auto">
      <thead>
        <tr>
          <th>Language</th>
          <th>Shortcodes</th>
          <th>German</th>
        </tr>
      </thead>
      <tbody>
        <tr
          :for={language <- visible(@languages, @only_missing, @locale)}
          id={"language-#{language.representative_id}"}
        >
          <td>{language.emoji} {language.name}</td>
          <td class="text-xs max-w-xs">{Enum.join(language.shortcodes, ", ")}</td>
          <td>
            <form phx-submit="save_language" class="flex gap-2">
              <input type="hidden" name="ids" value={Enum.join(language.ids, ",")} />
              <input
                type="text"
                name="text"
                value={language.translations[@locale]}
                class={[
                  "input input-sm w-72",
                  missing?(language.translations, @locale) && "input-warning"
                ]}
              />
              <button type="submit" class="btn btn-sm btn-primary">Save</button>
            </form>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  defp rows("categories", categories, _languages), do: categories
  defp rows("languages", _categories, languages), do: languages
end
