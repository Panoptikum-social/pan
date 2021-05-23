defmodule Pan.Search.Manticore do
  alias HTTPoison.Response

  def post(data, endpoint) do
    {:ok, %Response{status_code: response_code, body: response_body}} =
      HTTPoison.post("http://localhost:9308/" <> endpoint, data, [
        {"Content-Type", "application/x-ndjson"}
      ])

    {:ok, %Response{status_code: response_code, body: response_body}}
  end
end
