defmodule Pan.Search.Manticore do
  def post(data, endpoint) do
    {:ok, %HTTPoison.Response{status_code: response_code, body: response_body}} =
      HTTPoison.post("http://localhost:9308/" <> endpoint, data, [
        {"Content-Type", "application/x-ndjson"}
      ])

    {:ok, %HTTPoison.Response{status_code: response_code, body: response_body}}
  end
end
