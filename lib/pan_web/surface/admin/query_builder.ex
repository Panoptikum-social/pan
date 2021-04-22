defmodule PanWeb.Surface.Admin.QueryBuilder do
  import Ecto.Query
  alias Pan.Repo

  def delete(model, id) do
    record = Repo.get!(model, id)
    Repo.delete(record)

    if Map.has_key?(record, :elastic), do: model.delete_search_index(id)
  end

  def load(model, criteria, cols) when is_list(criteria) do
    from(r in model)
    |> apply_criteria(criteria)
    |> select_columns(cols)
    |> Repo.all()
  end

  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, &apply_criterium(&1, &2))
  end

  defp apply_criterium({:paginate, %{page: page, per_page: per_page}}, query) do
    from(q in query, offset: ^((page - 1) * per_page), limit: ^per_page)
  end

  defp apply_criterium({:sort, %{by: by, order: order}}, query) do
    from(q in query, order_by: [{^order, ^by}])
  end

  defp apply_criterium(
         {:search, %{options: options, filter: filter, hide: hide, like: like}},
         query
       ) do
    Enum.reduce(options, query, &apply_option(&1, &2, like))
    |> apply_filter(filter, hide)
  end

  # No or initial search term given
  defp apply_option({_column, ""}, query, _like), do: query

  # Search term given & like search
  defp apply_option({column, value}, query, true = _like) do
    from(q in query,
      where: ilike(fragment("cast (? as text)", field(q, ^column)), ^("%" <> value <> "%"))
    )
  end

  # Search term given & exact match
  defp apply_option({column, value}, query, false = _like) do
    from(q in query, where: ^[{column, value}])
  end

  # Filter ignored, selected elements will be indicated in view
  defp apply_filter(query, _filter, false = _hide), do: query

  # Filter for list
  defp apply_filter(query, {column, values}, true = _hide)
       when is_list(values) do
    from(q in query, where: field(q, ^column) in ^values)
  end

  # Filter for item
  defp apply_filter(query, {column, value}, true = _hide)
       when is_integer(value) do
    from(q in query, where: field(q, ^column) == ^value)
  end

  # No or initial filter to be applied
  defp apply_filter(query, {}=_filter, _hide), do: query

  defp select_columns(query, cols) do
    column_atoms = Enum.map(cols, & &1.field)
    from(q in query, select: ^column_atoms)
  end
end
