defmodule PanWeb.SearchApiController do
  use Pan.Web, :controller

  def search(conn, params) do
     case params["filter"] do
       %{"category" => category} ->
        redirect conn, to: category_api_path(conn, :search, [filter: category])

       %{"podcast" => podcast} ->
        redirect conn, to: podcast_api_path(conn, :search, [filter: podcast])

       %{"episode" => episode} ->
         redirect conn, to: episode_api_path(conn, :search, [filter: episode])

       %{"persona" => persona} ->
         redirect conn, to: persona_api_path(conn, :search, [filter: persona])
     end
  end
end
