defmodule Pan.Search do
  alias Pan.Search
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  require Logger

  def migrate do
    Search.Category.migrate()
    Search.Persona.migrate()
    Search.Podcast.migrate()
    Search.Episode.migrate()
  end

  @doc """
  Detects a fresh Manticore instance (e.g. an empty QA/Docker volume) and, if
  needed, brings it up to the same state as `/admin/search/migrate` +
  `/admin/search/reset_all` used to require doing by hand:

    1. `migrate/0` creates the (missing) Manticore tables.
    2. `reset_all/0` clears Postgres' `full_text` flags, since existing rows
       (e.g. from a seeded baseline dump) are already marked indexed even
       though the just-created Manticore tables are empty.

  Step 3, actually populating Manticore, is left to the regular
  `push_missing/0` polling in `Pan.Job.PushMissingSearchIndex`. A no-op once
  the tables exist, so this is safe to call on every boot.
  """
  def ensure_tables do
    unless tables_present?() do
      Logger.info(
        "=== Manticore search tables missing (fresh deploy?) — running migrate/0 + reset_all/0 ==="
      )

      migrate()
      reset_all()
    end
  end

  @required_tables ~w(categories personas podcasts episodes)

  @doc """
  Whether Manticore already has all four of our search tables.

  Errs on the side of "present" (skips `ensure_tables/0`'s migrate) for
  anything unexpected (bad status, undecodable body, unreachable Manticore)
  — `migrate/0` drops and recreates tables, so a false "missing" reading
  would destroy a live index.
  """
  def tables_present? do
    case Search.Manticore.sql("SHOW TABLES") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, [%{"data" => rows} | _]} when is_list(rows) ->
            existing = rows |> Enum.map(& &1["Table"]) |> MapSet.new()
            MapSet.subset?(MapSet.new(@required_tables), existing)

          _ ->
            true
        end

      _ ->
        true
    end
  end

  def push_missing do
    Search.Category.batch_index()
    Search.Persona.batch_index()
    Search.Podcast.batch_index()
    Search.Episode.batch_index()
  end

  def reset_all do
    Search.Category.batch_reset()
    Search.Persona.batch_reset()
    Search.Podcast.batch_reset()
    Search.Episode.batch_reset()
  end

  def batch_index(
        model: model,
        preloads: preloads,
        selects: selects,
        struct_function: struct_function
      ) do
    record_ids =
      from(r in model, where: not r.full_text, limit: 1_000, select: r.id)
      |> Repo.all(timeout: 999_999)

    if record_ids != [] do
      data =
        from(r in model, where: r.id in ^record_ids, preload: ^preloads, select: ^selects)
        |> Repo.all()
        |> Enum.map(&struct_function.(&1))
        |> Enum.map_join("\n", &Jason.encode!(&1))

      case Search.Manticore.post(data, "bulk", "application/x-ndjson") do
        {:ok, %HTTPoison.Response{status_code: response_code, body: response_body}} ->
          if response_code in [200, 201] do
            from(r in model, where: r.id in ^record_ids)
            |> Repo.update_all(set: [full_text: true])

            Logger.info("=== Indexed #{length(record_ids)} records of type #{model} ===")
          else
            handle_bulk_insert_error(response_body, model)
          end

          if response_code in [200, 201, 500] do
            batch_index(
              model: model,
              preloads: preloads,
              selects: selects,
              struct_function: struct_function
            )
          end

        {:error, error} ->
          # a transport-level failure (e.g. connection closed mid-request),
          # not an HTTP error response — log and stop for this cycle rather
          # than crash the caller or tight-loop retrying a dead connection;
          # the next scheduled push_missing/0 run will pick these back up
          Logger.error(
            "=== Manticore bulk insert request failed for #{model}: #{inspect(error)} ==="
          )
      end
    else
      Logger.info("=== Done with type #{model} ===")
    end
  end

  defp handle_bulk_insert_error(response_body, model) do
    {:ok, query_result} = Jason.decode(response_body)

    Logger.info("=== Query Result ===")
    Logger.info(query_result)

    with last_item_result <- query_result["items"] |> Enum.reverse() |> hd,
         error_type <- last_item_result["insert"]["error"]["type"],
         ["duplicate", "id", duplicate_id_string] <- error_type |> String.split() do
      duplicate_id = duplicate_id_string |> String.replace("'", "") |> String.to_integer()
      Logger.info("=== Updating full text status for #{model} with id #{duplicate_id} ===")

      from(r in model, where: r.id == ^duplicate_id)
      |> Repo.update_all(set: [full_text: true])
    else
      # error may be a map (e.g. a missing-table error), not just a string —
      # inspect/1 never blows up on interpolation the way `#{}` did here
      _ -> Logger.error("=== Error indexing #{model}: #{inspect(query_result)} ===")
    end
  end

  @doc """
  `language_ids`, when given a non-empty list, restricts results to
  podcasts/episodes tagged with any of those `PanWeb.Language` ids (already
  fully expanded to every shortcode variant of the languages meant - see
  `PanWeb.Language.expand_group_ids/1`). Only the `podcasts` and `episodes`
  indices carry `language_ids`; passing this for `categories`/`personas`
  would just filter out every hit, so callers shouldn't.
  """
  def query(opts) do
    index = Keyword.fetch!(opts, :index)
    term = Keyword.fetch!(opts, :term)
    limit = Keyword.fetch!(opts, :limit)
    offset = Keyword.fetch!(opts, :offset)
    language_ids = Keyword.get(opts, :language_ids, [])

    manticore_data =
      %{
        index: index,
        query: search_query(term, language_ids),
        limit: limit,
        offset: offset,
        highlight: %{
          no_match_size: 0,
          around: 8,
          before_match: "<strong style=\"color: #DA4453;\">",
          after_match: "</strong>"
        }
      }
      |> Jason.encode!()

    case HTTPoison.post(Search.Manticore.base_url() <> "/search", manticore_data, [
           {"Content-Type", "application/x-ndjson"}
         ]) do
      {:ok, %HTTPoison.Response{body: response_body}} ->
        {:ok, search_result} = Jason.decode(response_body)
        outer = search_result["hits"] || %{}
        %{"total" => outer["total"] || 0, "hits" => outer["hits"] || []}

      {:error, error} ->
        # a Manticore hiccup shouldn't 500 a user's search request
        Logger.error("=== Manticore search request failed: #{inspect(error)} ===")
        %{"total" => 0, "hits" => []}
    end
  end

  defp search_query(term, []), do: %{match_phrase: %{_all: term}}

  defp search_query(term, language_ids) do
    %{
      bool: %{
        must: [%{match_phrase: %{_all: term}}],
        filter: [%{in: %{language_ids: language_ids}}]
      }
    }
  end
end
