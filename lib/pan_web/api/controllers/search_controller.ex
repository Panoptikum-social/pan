defmodule PanWeb.Api.SearchController do
  use Pan.Web, :controller

  def search(conn, params) do
     case params["filter"] do
       %{"category" => category} ->
        redirect conn, to: api_category_path(conn, :search, [filter: category])

       %{"podcast" => podcast} ->
        redirect conn, to: api_podcast_path(conn, :search, [filter: podcast])

       %{"episode" => episode} ->
         redirect conn, to: api_episode_path(conn, :search, [filter: episode])

       %{"persona" => persona} ->
         redirect conn, to: api_persona_path(conn, :search, [filter: persona])
     end
  end
end
