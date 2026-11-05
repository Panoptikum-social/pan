defmodule PanWeb.Translations do
  @moduledoc """
  Translated category titles and language names (Project #4, #566, #567).

  Titles reach the pages as structs, raw select lists and Manticore hits, so
  they are translated by id: all translations of a table are kept in one
  `:persistent_term` map (`id => %{"de" => "..."}`), loaded on first use and
  reloaded by `refresh/0` when the admin page saves. Missing translations
  and English fall back to the stored title or name.
  """
  import Ecto.Query
  use Gettext, backend: PanWeb.Gettext
  alias Pan.Repo
  alias PanWeb.{Category, Language}

  # Gig and engagement roles (#571), stored in lowercase: the podcast:person
  # roles of the Podcasting 2.0 taxonomy plus the parser's own. Others are
  # shown as stored.
  @roles [
    dgettext_noop("frontend", "host"),
    dgettext_noop("frontend", "co-host"),
    dgettext_noop("frontend", "guest host"),
    dgettext_noop("frontend", "guest"),
    dgettext_noop("frontend", "author"),
    dgettext_noop("frontend", "owner"),
    dgettext_noop("frontend", "contributor"),
    dgettext_noop("frontend", "director"),
    dgettext_noop("frontend", "assistant director"),
    dgettext_noop("frontend", "executive producer"),
    dgettext_noop("frontend", "senior producer"),
    dgettext_noop("frontend", "producer"),
    dgettext_noop("frontend", "associate producer"),
    dgettext_noop("frontend", "development producer"),
    dgettext_noop("frontend", "creative director"),
    dgettext_noop("frontend", "writer"),
    dgettext_noop("frontend", "story editor"),
    dgettext_noop("frontend", "managing editor"),
    dgettext_noop("frontend", "script editor"),
    dgettext_noop("frontend", "script coordinator"),
    dgettext_noop("frontend", "researcher"),
    dgettext_noop("frontend", "editor"),
    dgettext_noop("frontend", "fact checker"),
    dgettext_noop("frontend", "translator"),
    dgettext_noop("frontend", "transcriber"),
    dgettext_noop("frontend", "logger"),
    dgettext_noop("frontend", "studio coordinator"),
    dgettext_noop("frontend", "technical director"),
    dgettext_noop("frontend", "technical manager"),
    dgettext_noop("frontend", "audio engineer"),
    dgettext_noop("frontend", "remote recording engineer"),
    dgettext_noop("frontend", "post production engineer"),
    dgettext_noop("frontend", "audio editor"),
    dgettext_noop("frontend", "sound designer"),
    dgettext_noop("frontend", "foley artist"),
    dgettext_noop("frontend", "composer"),
    dgettext_noop("frontend", "theme music"),
    dgettext_noop("frontend", "music production"),
    dgettext_noop("frontend", "music contributor"),
    dgettext_noop("frontend", "production coordinator"),
    dgettext_noop("frontend", "booking coordinator"),
    dgettext_noop("frontend", "production assistant"),
    dgettext_noop("frontend", "content manager"),
    dgettext_noop("frontend", "marketing manager"),
    dgettext_noop("frontend", "sales representative"),
    dgettext_noop("frontend", "sales manager"),
    dgettext_noop("frontend", "graphic designer"),
    dgettext_noop("frontend", "cover art designer"),
    dgettext_noop("frontend", "social media manager"),
    dgettext_noop("frontend", "consultant"),
    dgettext_noop("frontend", "intern"),
    dgettext_noop("frontend", "camera operator"),
    dgettext_noop("frontend", "lighting designer"),
    dgettext_noop("frontend", "camera grip"),
    dgettext_noop("frontend", "assistant camera"),
    dgettext_noop("frontend", "assistant editor"),
    dgettext_noop("frontend", "voice actor"),
    dgettext_noop("frontend", "actor"),
    dgettext_noop("frontend", "narrator"),
    dgettext_noop("frontend", "announcer")
  ]

  def category_title(%{id: id, title: title}), do: category_title(id, title)
  def category_title(id, fallback), do: lookup(:categories, id, fallback)

  def language_name(%{id: id, name: name}), do: language_name(id, name)
  def language_name(id, fallback), do: lookup(:languages, id, fallback)

  def role(role) when role in @roles, do: Gettext.dgettext(PanWeb.Gettext, "frontend", role)
  def role(role), do: role

  @doc "Drops the cached maps; the next lookup loads them again."
  def refresh do
    :persistent_term.erase({__MODULE__, :categories})
    :persistent_term.erase({__MODULE__, :languages})
    :ok
  end

  defp lookup(table, id, fallback) do
    case Gettext.get_locale(PanWeb.Gettext) do
      "en" -> fallback
      locale -> get_in(translations(table), [to_id(id), locale]) || fallback
    end
  end

  defp to_id(id) when is_integer(id), do: id
  defp to_id(id) when is_binary(id), do: String.to_integer(id)
  defp to_id(_id), do: nil

  defp translations(table) do
    case :persistent_term.get({__MODULE__, table}, nil) do
      nil ->
        map = load(table)
        :persistent_term.put({__MODULE__, table}, map)
        map

      map ->
        map
    end
  end

  defp load(:categories),
    do: from(c in Category, select: {c.id, c.title_translations}) |> Repo.all() |> Map.new()

  defp load(:languages),
    do: from(l in Language, select: {l.id, l.name_translations}) |> Repo.all() |> Map.new()
end
