defmodule Pan.Search do
  alias Pan.Search
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  require Logger
  alias HTTPoison.Response

  def push_missing do
    #    Search.Category.batch_index()
    #    Search.Persona.batch_index()
    #    Search.Podcast.batch_index()
    Search.Episode.batch_index()
  end

  def reset_all do
    #    Search.Category.batch_reset()
    #    Search.Persona.batch_reset()
    #    Search.Podcast.batch_reset()
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
      |> Repo.all()

    manticore_data =
      from(r in model, where: r.id in ^record_ids, preload: ^preloads, select: ^selects)
      |> Repo.all()
      |> Enum.map(&struct_function.(&1))
      |> Enum.map(&Jason.encode!(&1))
      |> Enum.join("\n")

    {:ok, %Response{status_code: response_code, body: response_body}} =
      HTTPoison.post("http://localhost:9308/bulk", manticore_data, [
        {"Content-Type", "application/x-ndjson"}
      ])

    if response_code >= 200 && response_code <= 299 do
      from(r in model, where: r.id in ^record_ids)
      |> Repo.update_all(set: [full_text: true])

      Logger.info("=== Indexed #{length(record_ids)} records of type #{model} ===")
    else
      IO.inspect(response_body)
    end

    if response_code >= 200 && response_code <= 299 && length(record_ids) > 0 do
      batch_index(
        model: model,
        preloads: preloads,
        selects: selects,
        struct_function: struct_function
      )
    end
  end
end
