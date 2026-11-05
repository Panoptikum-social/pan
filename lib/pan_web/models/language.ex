defmodule PanWeb.Language do
  use PanWeb, :model

  alias Pan.Repo
  alias PanWeb.Language

  schema "languages" do
    field(:shortcode, :string)
    field(:name, :string)
    field(:emoji, :string)
    field(:name_translations, :map, default: %{})
    timestamps()

    many_to_many(:podcasts, PanWeb.Podcast, join_through: "languages_podcasts")
    many_to_many(:users, PanWeb.User, join_through: "users_languages")
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:shortcode, :name, :emoji])
    |> validate_required([:shortcode, :name])
    |> unique_constraint(:shortcode)
  end

  def get_by_category_id(category_id) do
    from(l in Language,
      join: p in assoc(l, :podcasts),
      join: c in assoc(p, :categories),
      where: c.id == ^category_id,
      distinct: [asc: l.name],
      select: [:id, :name, :emoji]
    )
    |> Repo.all()
  end

  def get_by_id(id) do
    Repo.get!(Language, id)
  end

  @doc """
  Many rows share an identical `{name, emoji}` (275 shortcode variants like
  "en", "en-us", "en-GB", ... collapse to ~67 real languages), so anything
  presenting languages to a human (a picker, a filter) should group by this
  key instead of listing every row.
  """
  def group_key(%Language{name: name, emoji: emoji}), do: {name, emoji}

  @doc """
  All languages grouped by `{name, emoji}`, one entry per real language, each
  carrying every underlying row id (`ids`) plus a stable `representative_id`
  (the lowest id in the group) to key a picker option on. Sorted by name.
  """
  def grouped do
    Repo.all(Language)
    |> Enum.group_by(&group_key/1)
    |> Enum.map(fn {{name, emoji}, languages} ->
      ids = languages |> Enum.map(& &1.id) |> Enum.sort()

      %{
        name: name,
        emoji: emoji,
        ids: ids,
        representative_id: hd(ids),
        shortcodes: languages |> Enum.map(& &1.shortcode) |> Enum.sort(),
        translations: hd(Enum.sort_by(languages, & &1.id)).name_translations
      }
    end)
    |> Enum.sort_by(& &1.name)
  end

  @doc """
  Sets (or with an empty text removes) the name in `locale` for every row of
  a language group, so all shortcode variants show the same name (#593), and
  reloads the cached translations.
  """
  def put_translation(ids, locale, text) do
    for language <- Repo.all(from(l in Language, where: l.id in ^ids)) do
      translations =
        case String.trim(text || "") do
          "" -> Map.delete(language.name_translations, locale)
          trimmed -> Map.put(language.name_translations, locale, trimmed)
        end

      language
      |> Ecto.Changeset.change(name_translations: translations)
      |> Repo.update!()
    end

    PanWeb.Translations.refresh()
  end

  @doc """
  Expands a list of representative ids (as picked from `grouped/0`, e.g. what
  a settings form submits) into every underlying language id in each of
  those groups, so a podcast tagged with any shortcode variant of a chosen
  language still matches.
  """
  def expand_group_ids(representative_ids) do
    representative_ids = Enum.map(representative_ids, &to_id/1)

    grouped()
    |> Enum.filter(&(&1.representative_id in representative_ids))
    |> Enum.flat_map(& &1.ids)
  end

  defp to_id(id) when is_binary(id), do: String.to_integer(id)
  defp to_id(id) when is_integer(id), do: id
end
