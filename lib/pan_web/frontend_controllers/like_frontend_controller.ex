defmodule PanWeb.LikeFrontendController do
  use Pan.Web, :controller
  alias PanWeb.Like

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def unlike_all_categories(conn, _, user) do
    from(l in Like, where: l.enjoyer_id == ^user.id and not is_nil(l.category_id))
    |> Repo.delete_all()

    conn
    |> put_flash(:info, "Unliked all categories successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end

  def unlike_all_chapters(conn, _, user) do
    from(l in Like, where: l.enjoyer_id == ^user.id and not is_nil(l.chapter_id))
    |> Repo.delete_all()

    conn
    |> put_flash(:info, "Unliked all chapters successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end

  def unlike_all_episodes(conn, _, user) do
    from(l in Like, where: l.enjoyer_id == ^user.id and not is_nil(l.episode_id))
    |> Repo.delete_all()

    conn
    |> put_flash(:info, "Unliked all episodes successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end

  def unlike_all_personas(conn, _, user) do
    from(l in Like, where: l.enjoyer_id == ^user.id and not is_nil(l.persona_id))
    |> Repo.delete_all()

    conn
    |> put_flash(:info, "Unliked all personas successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end

  def unlike_all_podcasts(conn, _, user) do
    from(l in Like, where: l.enjoyer_id == ^user.id and not is_nil(l.podcast_id))
    |> Repo.delete_all()

    conn
    |> put_flash(:info, "Unliked all podcasts successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end

  def unlike_all_users(conn, _, user) do
    from(l in Like, where: l.enjoyer_id == ^user.id and not is_nil(l.user_id))
    |> Repo.delete_all()

    conn
    |> put_flash(:info, "Unliked all users successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end
end
