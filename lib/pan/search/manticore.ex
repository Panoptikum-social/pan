defmodule Pan.Search.Manticore do
  alias HTTPoison.Response

  def post(endpoint: endpoint, data: data) do
    {:ok, %Response{status_code: response_code, body: response_body}} =
      HTTPoison.post("http://localhost:9308/" <> endpoint, data, [
        {"Content-Type", "application/x-ndjson"}
      ])

    IO.inspect(response_code)
    IO.inspect(response_body)
    {:ok, %Response{status_code: response_code, body: response_body}}
  end
end
