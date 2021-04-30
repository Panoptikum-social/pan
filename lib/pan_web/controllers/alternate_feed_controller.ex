defmodule PanWeb.AlternateFeedController do
  use PanWeb, :controller
  alias PanWeb.AlternateFeed

  def create_from_backlog(conn, %{"feed_id" => feed_id, "url" => url, "backlog_id" => backlog_id}) do
    changeset =
      AlternateFeed.changeset(%AlternateFeed{
        title: url,
        url: url,
        feed_id: String.to_integer(feed_id)
      })

    case Repo.insert(changeset) do
      {:ok, _alternate_feed} ->
        conn
        |> put_flash(:info, "Alternate feed created successfully.")
        |> redirect(to: feed_backlog_path(conn, :index))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not create alternate feed.")
        |> redirect(to: feed_backlog_path(conn, :show, String.to_integer(backlog_id)))
    end
  end
end
