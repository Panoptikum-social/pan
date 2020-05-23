defmodule Pan.ActivityPub.Net do
  # download and pretty print actor feed
  # curl -H "Accept: application/activity+json" https://pleroma.panoptikum.io/users/informatom | python -m json.tool

  @options ["User-Agent": "Mozilla/5.0 (compatible; Panoptikum; +https://panoptikum.io/)",
            ssl: [{:versions, [:'tlsv1.2', :'tlsv1.1', :tlsv1]}]]
  @headers ["Accept": "application/activity+json"]


  def get_by_address(address) do
    [_, username, domain] = Regex.split(~r{@}, address)
    get("https://" <> domain <> "/users/" <> username)
  end


  def get(url) do
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url, @headers, @options)
    Jason.decode(body)
  end
end
