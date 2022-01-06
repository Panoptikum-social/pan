defmodule PanWeb.RecommendationFrontendController do
  use PanWeb, :controller

  alias PanWeb.{Podcast, Recommendation, Subscription}

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def my_recommendations(conn, _params, user) do
    podcast_recommendations =
      Repo.all(
        from(r in Recommendation,
          where:
            r.user_id == ^user.id and
              not is_nil(r.podcast_id) and
              is_nil(r.episode_id) and
              is_nil(r.chapter_id),
          order_by: [desc: :inserted_at],
          preload: :podcast
        )
      )

    subscribed_podcast_ids =
      Repo.all(
        from(s in Subscription,
          where: s.user_id == ^user.id,
          select: s.podcast_id
        )
      )

    recommended_podcast_ids =
      Enum.map(podcast_recommendations, fn recommendation -> recommendation.podcast_id end)

    unrecommonded_podcast_ids =
      Enum.filter(subscribed_podcast_ids, fn id ->
        not Enum.member?(recommended_podcast_ids, id)
      end)

    unrecommended_podcasts =
      Repo.all(from(p in Podcast, where: p.id in ^unrecommonded_podcast_ids))

    changeset = Recommendation.changeset(%Recommendation{})

    render(conn, "my_recommendations.html",
      podcast_recommendations: podcast_recommendations,
      unrecommended_podcasts: unrecommended_podcasts,
      changeset: changeset
    )
  end

  def create(conn, %{"recommendation" => recommendation_params}, user) do
    recommendation_params = Map.put(recommendation_params, "user_id", user.id)
    changeset = Recommendation.changeset(%Recommendation{}, recommendation_params)

    Repo.insert(changeset)

    conn
    |> put_flash(:info, "Your recommendation has been added.")
    |> redirect_to_back
  end

  def delete(conn, %{"id" => id}, user) do
    Repo.one(from(r in Recommendation, where: r.id == ^id and r.user_id == ^user.id))
    |> Repo.delete!()

    conn
    |> put_flash(:info, "Recommendation deleted successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end

  def delete_all(conn, _, user) do
    from(r in Recommendation, where: r.user_id == ^user.id)
    |> Repo.delete_all()

    conn
    |> put_flash(:info, "All recommendations deleted successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end

  defp redirect_to_back(conn) do
    path =
      conn
      |> Plug.Conn.get_req_header("referer")
      |> List.first()
      |> URI.parse()
      |> Map.get(:path)

    conn
    |> assign(:refer_path, path)
    |> redirect(to: path)
  end
end
