defmodule Pan.ActivityPub.Net do
  @options ["User-Agent": "Mozilla/5.0 (compatible; Panoptikum; +https://panoptikum.io/)"]
  @headers ["Accept": "application/activity+json"]


  def get_by_address(address) do
    [_, username, domain] = Regex.split(~r{@}, address)
    get("https://" <> domain <> "/users/" <> username)
  end


  def get(url) do
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url, @headers, @options)
    Poison.decode(body)
  end
end