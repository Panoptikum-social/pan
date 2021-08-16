defmodule Pan.Search do
  alias Pan.Search
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  require Logger
  alias HTTPoison.Response

  def migrate do
#    Search.Category.migrate()
#    Search.Persona.migrate()
#    Search.Podcast.migrate()
#    Search.Episode.migrate()
  end

  def push_missing do
    Search.Category.batch_index()
    Search.Persona.batch_index()
    Search.Podcast.batch_index()
    Search.Episode.batch_index()
  end

  def reset_all do
#    Search.Category.batch_reset()
#    Search.Persona.batch_reset()
#    Search.Podcast.batch_reset()
#    Search.Episode.batch_reset()
  end

  def batch_index(
        model: model,
        preloads: preloads,
        selects: selects,
        struct_function: struct_function
      ) do
    record_ids =
      from(r in model, where: not r.full_text, limit: 1_000, select: r.id)
      |> Repo.all()

    if record_ids != [] do
      data =
        from(r in model, where: r.id in ^record_ids, preload: ^preloads, select: ^selects)
        |> Repo.all()
        |> Enum.map(&struct_function.(&1))
        |> Enum.map(&Jason.encode!(&1))
        |> Enum.join("\n")

      {:ok, %Response{status_code: response_code, body: response_body}} =
        Search.Manticore.post(data, "bulk")

      if response_code in [200, 201] do
        from(r in model, where: r.id in ^record_ids)
        |> Repo.update_all(set: [full_text: true])

        Logger.info("=== Indexed #{length(record_ids)} records of type #{model} ===")
      else
        {:ok, query_result} = Jason.decode(response_body)

        Logger.info("=== Query Result ===")
        Logger.info(query_result)

        error = hd(query_result["items"] |> Enum.reverse())["insert"]["error"]["type"]

        error_id =
          error
          |> String.split()
          |> tl()
          |> tl()
          |> hd()
          |> String.replace("'", "")
          |> String.to_integer()

        Logger.error("=== Error: #{error_id} ===")
        Repo.get!(model, error_id) |> Ecto.Changeset.change(full_text: true) |> Repo.update()
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
        query: %{match: %{*: term}},
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

    {:ok, %Response{body: response_body}} = response
    {:ok, search_result} = Jason.decode(response_body)

    search_result["hits"]
  end
end
