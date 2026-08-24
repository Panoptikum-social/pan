defmodule PanWeb.Journal do
  @moduledoc """
  A minimal, append-only audit trail: one entry per notable change made by
  application code (as opposed to a user through the normal UI), so there's
  something to look at if a maintenance action goes wrong. Entries are
  never updated, only created, read and deleted — see `log/1`.
  """

  use PanWeb, :model
  require Logger
  alias Pan.Repo
  alias PanWeb.Journal

  schema "journals" do
    field(:module, :string)
    field(:method, :string)
    field(:text, Ecto.EctoText)
    field(:before, Ecto.EctoText)
    field(:after, Ecto.EctoText)

    timestamps(updated_at: false)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:module, :method, :text, :before, :after])
    |> validate_required([:module, :method, :text])
  end

  @doc """
  Records one journal entry. `before`/`after` are optional and get
  `inspect/1`-ed if they aren't already strings, so callers can pass
  whatever they have on hand (a struct, a count, a list of ids, ...).

      Journal.log(%{
        module: __MODULE__,
        method: "fix_double_escaped_html_entities",
        text: "backfilled 35033 episode titles",
        before: "&amp;quot;It&amp;#039;s a match&amp;quot;",
        after: "\\"It's a match\\""
      })
  """
  def log(fields) do
    changeset =
      fields
      |> Map.new()
      |> Map.update(:module, nil, &stringify/1)
      |> Map.update(:before, nil, &stringify/1)
      |> Map.update(:after, nil, &stringify/1)
      |> then(&changeset(%Journal{}, &1))

    case Repo.insert(changeset) do
      {:ok, entry} ->
        {:ok, entry}

      {:error, changeset} ->
        # a broken journal call shouldn't take down whatever it's
        # documenting, but it shouldn't disappear silently either
        Logger.error("=== Journal.log failed: #{inspect(changeset.errors)} ===")
        {:error, changeset}
    end
  end

  defp stringify(nil), do: nil
  defp stringify(value) when is_binary(value), do: value
  defp stringify(value), do: inspect(value)
end
