defmodule Pan.Search.Manticore do
  def sql(query) do
    ("query=" <> URI.encode_www_form(query))
    |> post("sql?mode=raw", "application/x-www-form-urlencoded")
  end

  def post(data, endpoint, content_type) do
    {:ok, %HTTPoison.Response{status_code: response_code, body: response_body}} =
      HTTPoison.post("http://localhost:9308/" <> endpoint, data, [
        {"Content-Type", content_type}
      ])

    {:ok, %HTTPoison.Response{status_code: response_code, body: response_body}}
  end
end
