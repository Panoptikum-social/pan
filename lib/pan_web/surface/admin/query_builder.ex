defmodule PanWeb.Surface.Admin.QueryBuilder do
  import Ecto.Query
  alias Pan.Repo

  def delete(model, record) do
    Repo.delete(record)
    if Map.has_key?(record, :elastic), do: model.delete_search_index(record.id)
  end

  def load(model, criteria, cols) do
    from(r in model)
    |> apply_criteria(criteria)
    |> select_columns(cols)
    |> Repo.all()
  end

  def count_filtered(model, criteria) do
    from(r in model)
    |> apply_criteria(criteria)
    |> Repo.aggregate(:count)
  end

  def count_unfiltered(model) do
    from(r in model)
    |> Repo.aggregate(:count)
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
        {:search, %{options: options, filter: filter, second_filter: second_filter, hide: hide, mode: mode}},
        query
      ) do
    Enum.reduce(options, query, &apply_option(&1, &2, mode))
    |> apply_filter(filter, hide)
    |> apply_filter(second_filter, hide)
  end

  defp apply_criterium(
         {:search, %{options: options, filter: filter, hide: hide, mode: mode}},
         query
       ) do
    Enum.reduce(options, query, &apply_option(&1, &2, mode))
    |> apply_filter(filter, hide)
  end

  # No or initial search term given
  defp apply_option({_column, ""}, query, _mode), do: query

  # Search term given & contains search mode
  defp apply_option({column, value}, query, :contains = _mode) do
    from(q in query,
      where: ilike(fragment("cast (? as text)", field(q, ^column)), ^("%" <> value <> "%"))
    )
  end

  # Search term given & starts_with search mode
  defp apply_option({column, value}, query, :starts_with = _mode) do
    from(q in query,
      where: ilike(fragment("cast (? as text)", field(q, ^column)), ^(value <> "%"))
    )
  end

  # Search term given & ends with search mode
  defp apply_option({column, value}, query, :ends_with = _mode) do
    from(q in query,
      where: ilike(fragment("cast (? as text)", field(q, ^column)), ^("%" <> value))
    )
  end

  # Search term given & exact match search mode
  defp apply_option({column, value}, query, :exact = _mode) do
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
  defp apply_filter(query, {} = _filter, _hide), do: query

  defp select_columns(query, cols) do
    column_atoms = Enum.map(cols, & &1.field)
    from(q in query, select: ^column_atoms)
  end

  def read_by_params(model, resource_params) do
    primary_key = model.__schema__(:primary_key)

    from(r in model,
      where:
        ^Enum.map(
          primary_key,
          &{&1, resource_params[&1 |> Atom.to_string()] |> String.to_integer()}
        )
    )
    |> Repo.one!()
  end

  def read_by_values(model, values) do
    primary_key = model.__schema__(:primary_key)

    from(r in model, where: ^Enum.map(primary_key, &{&1, values[&1]}))
    |> Repo.one!()
  end

  def set_belongs_to(assigns, ids) do
    {column, value} = assigns.search_filter

    from(r in assigns.model, where: r.id in ^ids)
    |> Repo.update_all(set: [{column, value}])
  end

  def clear_belongs_to(assigns, ids) do
    {column, _} = assigns.search_filter

    from(r in assigns.model, where: r.id in ^ids)
    |> Repo.update_all(set: [{column, nil}])
  end
end
