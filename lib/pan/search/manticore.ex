defmodule Pan.Search.Manticore do
  @moduledoc """
  Thin HTTP client for the Manticore Search server.

  The base URL defaults to `http://localhost:9308`, matching the
  bare-metal setup where Manticore runs on the same host. Override it
  with `config :pan, :manticore_url, "http://..."` (e.g. for the
  Docker Compose QA stack, where Manticore is a separate container).
  """

  def base_url do
    Application.get_env(:pan, :manticore_url, "http://localhost:9308")
  end

  def sql(query) do
    ("query=" <> URI.encode_www_form(query))
    |> post("sql?mode=raw", "application/x-www-form-urlencoded")
  end

  def post(data, endpoint, content_type) do
    {:ok, %HTTPoison.Response{status_code: response_code, body: response_body}} =
      HTTPoison.post(base_url() <> "/" <> endpoint, data, [
        {"Content-Type", content_type}
      ])

    {:ok, %HTTPoison.Response{status_code: response_code, body: response_body}}
  end
end
