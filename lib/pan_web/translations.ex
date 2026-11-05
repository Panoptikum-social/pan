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
  alias Pan.Repo
  alias PanWeb.{Category, Language}

  def category_title(%{id: id, title: title}), do: category_title(id, title)
  def category_title(id, fallback), do: lookup(:categories, id, fallback)

  def language_name(%{id: id, name: name}), do: language_name(id, name)
  def language_name(id, fallback), do: lookup(:languages, id, fallback)

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
