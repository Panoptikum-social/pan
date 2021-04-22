defmodule PanWeb.Surface.Admin.QueryBuilder do
  import Ecto.Query
  alias Pan.Repo

  def load(model, criteria, cols) when is_list(criteria) do
    from(r in model)
    |> apply_criteria(criteria)
    |> select_columns(cols)
    |> Repo.all()
  end

  defp apply_criteria(query, criteria) do
    Enum.reduce(
      criteria,
      query,
      &apply_criterium(&1, &2, criteria[:like_search], criteria[:hide_filtered])
    )
  end

  defp apply_criterium({:paginate, %{page: page, per_page: per_page}}, query, _, _) do
    from(q in query, offset: ^((page - 1) * per_page), limit: ^per_page)
  end

  defp apply_criterium({:sort, %{sort_by: sort_by, sort_order: sort_order}}, query, _, _) do
    from(q in query, order_by: [{^sort_order, ^sort_by}])
  end

  defp apply_criterium({:search_filter, {_, _}}, query, _, false = _hide_filtered), do: query

  defp apply_criterium({:search_filter, {column, values}}, query, _, true = _hide_filtered)
       when is_list(values) do
    from(q in query, where: field(q, ^column) in ^values)
  end

  defp apply_criterium({:search_filter, {column, value}}, query, _, true = _hide_filtered)
       when is_integer(value) do
    from(q in query, where: field(q, ^column) == ^value)
  end

  defp apply_criterium({:search, search_options}, query, like_search, hide_filtered) do
    Enum.reduce(search_options, query, &apply_search_option(&1, &2, like_search, hide_filtered))
  end

  defp apply_criterium({:search_filter, {}}, query, _, _), do: query

  # consumed by :search, no need to restrict anything here
  defp apply_criterium({:like_search, _}, query, _, _), do: query
  defp apply_criterium({:hide_filtered, _}, query, _, _), do: query

  defp apply_search_option({_column, ""}, query, _, _), do: query

  defp apply_search_option({column, value}, query, true = _, _) do
    from(q in query,
      where: ilike(fragment("cast (? as text)", field(q, ^column)), ^("%" <> value <> "%"))
    )
  end

  defp apply_search_option({column, value}, query, false = _, _) do
    from(q in query, where: ^[{column, value}])
  end

  defp select_columns(query, cols) do
    column_atoms = Enum.map(cols, & &1.field)
    from(q in query, select: ^column_atoms)
  end
end
