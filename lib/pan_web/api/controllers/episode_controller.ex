defmodule PanWeb.Api.EpisodeController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.Episode
  alias PanWeb.Api.Helpers

  def index(conn, params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
           |> min(1000)
    offset = (page - 1) * size

    total = from(e in Episode, join: p in assoc(e, :podcast),
                               where: (is_nil(p.blocked) or p.blocked == false) and
                                      e.publishing_date < ^NaiveDateTime.utc_now())
            |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = conn
    |> api_episode_url(:index)
    |> Helpers.pagination_links({page, size, total_pages}, conn)

    episodes = from(e in Episode, join: p in assoc(e, :podcast),
                                  where: (is_nil(p.blocked) or p.blocked == false) and
                                   e.publishing_date < ^NaiveDateTime.utc_now(),
                                  order_by: [desc: :publishing_date],
                                  preload: [:podcast, :gigs, :contributors],
                                  limit: ^size,
                                  offset: ^offset)
               |> Repo.all()

    render conn, "index.json-api", data: episodes,
                                   opts: [page: links,
                                          include: "podcast,gigs,contributors"]
  end



  def show(conn, %{"id" => id}) do

    episode = Repo.get(Episode, id)
              |> Repo.preload([:podcast, :chapters, [recommendations: :user], :enclosures, :gigs,
                               :contributors])

    if episode do
      render conn, "show.json-api", data: episode,
                                  opts: [include: "podcast,chapters,recommendations,enclosures,gigs,contributors"]
    else
      Helpers.send_404(conn)
    end
  end


  def search(conn, params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
           |> min(1000)
    offset = (page - 1) * size

    query = [index: "/panoptikum_" <> Application.get_env(:pan, :environment) <> "/episodes",
             search: [size: size, from: offset, query: [match: [_all: params["filter"]]]]]


    case Tirexs.Query.create_resource(query) do
      {:ok, 200, %{hits: hits}} ->
        if hits.total > 0 do
          total = Enum.min([hits.total, 10_000])
          total_pages = div(total - 1, size) + 1

          links = conn
          |> api_episode_url(:search)
          |> Helpers.pagination_links({page, size, total_pages}, conn)

          episode_ids = Enum.map(hits[:hits], fn(hit) -> String.to_integer(hit[:_id]) end)

          episodes = from(e in Episode, where: e.id in ^episode_ids,
                                        preload: [:podcast, :gigs, :contributors])
                     |> Repo.all()

          render conn, "index.json-api", data: episodes, opts: [page: links,
                                                                include: "podcast,gigs,contributors"]
        else
          Helpers.send_error(conn, 404, "Nothing found", "No matching episodes found in the data base.")
        end
      {:error, 500, %{error: %{caused_by: %{reason: reason}}}} ->
        Helpers.send_401(conn, reason)
      :error ->
        Helpers.send_error(conn, 500, "Server error", "The search engine seams to be broken right now.")
    end
  end
end
