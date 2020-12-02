defmodule Ecto.Convenience do
  def total_estimated(model_name) do
    {:ok, %Postgrex.Result{rows: [[rows]]}} =
      Ecto.Adapters.SQL.query(
        Pan.Repo,
        "SELECT reltuples::BIGINT AS estimate FROM pg_class WHERE relname=$1",
        [model_name.__struct__.__meta__.source]
      )

    rows
  end
end
