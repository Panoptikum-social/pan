defmodule PanWeb.PathId do
  @moduledoc """
  Integer ids from URL paths. Without this check a path like `/users/abc`
  reaches `Repo.get!/2`, raises `Ecto.Query.CastError` and answers 400 Bad
  Request instead of 404 Not Found (#537).
  """

  @doc "Parses `id` as an integer; raises `Ecto.NoResultsError` (404) if it isn't one."
  def to_integer!(id, queryable) do
    case Integer.parse(id) do
      {integer, ""} -> integer
      _ -> raise Ecto.NoResultsError, queryable: queryable
    end
  end
end
