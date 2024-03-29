defmodule Pan.Search do
  alias Pan.Search
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  require Logger

  def migrate do
    # Search.Category.migrate()
    # Search.Persona.migrate()
    # Search.Podcast.migrate()
    # Search.Episode.migrate()
  end

  def push_missing do
    Search.Category.batch_index()
    Search.Persona.batch_index()
    Search.Podcast.batch_index()
    Search.Episode.batch_index()
  end

  def reset_all do
    # Search.Category.batch_reset()
    # Search.Persona.batch_reset()
    # Search.Podcast.batch_reset()
    # Search.Episode.batch_reset()
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

      {:ok, %HTTPoison.Response{status_code: response_code, body: response_body}} =
        Search.Manticore.post(data, "bulk")

      if response_code in [200, 201] do
        from(r in model, where: r.id in ^record_ids)
        |> Repo.update_all(set: [full_text: true])

        Logger.info("=== Indexed #{length(record_ids)} records of type #{model} ===")
      else
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
          _ -> Logger.error("=== Error: #{hd(query_result["items"])["insert"]["error"]} ===")
        end
      end

      if response_code in [200, 201, 500] && length(record_ids) > 0 do
        batch_index(
          model: model,
          preloads: preloads,
          selects: selects,
          struct_function: struct_function
        )
      end
    else
      Logger.info("=== Done with type #{model} ===")
    end
  end

  def query(index: index, term: term, limit: limit, offset: offset) do
    manticore_data =
      %{
        index: index,
        query: %{match_phrase: %{_all: term}},
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

    response =
      HTTPoison.post("http://localhost:9308/search", manticore_data, [
        {"Content-Type", "application/x-ndjson"}
      ])

    {:ok, %HTTPoison.Response{body: response_body}} = response
    {:ok, search_result} = Jason.decode(response_body)

    search_result["hits"]
  end
end
