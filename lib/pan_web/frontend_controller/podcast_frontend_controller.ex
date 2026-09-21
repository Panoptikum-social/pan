defmodule PanWeb.PodcastFrontendController do
  use PanWeb, :controller
  alias PanWeb.Podcast

  def claim(%{assigns: %{current_user: user}} = conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    emails = Podcast.feed_owner_emails(podcast.id)

    {level, message} =
      cond do
        not user.email_verified ->
          {:error, "Please verify your email address first."}

        podcast.user_id ->
          {:error,
           "This podcast is managed by someone already. Please contact us if that is wrong."}

        emails == [] ->
          {:error, "The feed lists no owner email address, so we cannot send a confirmation."}

        true ->
          token = Podcast.claim_token(podcast.id, user.id)

          for email <- emails do
            token
            |> Pan.Email.confirm_podcast_claim_link_html_email(user, podcast, email)
            |> Pan.Mailer.deliver()
          end

          {:info, "We sent a confirmation link to the owner address listed in the feed."}
      end

    conn
    |> put_flash(level, message)
    |> redirect(to: podcast_frontend_path(conn, :show, podcast))
  end

  def confirm_ownership(conn, %{"id" => id, "token" => token}) do
    podcast = Repo.get!(Podcast, id)

    case Podcast.verify_claim_token(token, podcast.id) do
      {:ok, user_id} ->
        render(conn, "grant_ownership.html",
          podcast: podcast,
          claimant: Repo.get!(PanWeb.User, user_id),
          token: token
        )

      {:error, reason} ->
        conn
        |> put_flash(:error, claim_error(reason))
        |> render("grant_ownership.html", podcast: podcast, claimant: nil, token: nil)
    end
  end

  def grant_ownership(conn, %{"id" => id, "token" => token}) do
    podcast = Repo.get!(Podcast, id)

    with {:ok, user_id} <- Podcast.verify_claim_token(token, podcast.id),
         :ok <- Podcast.claim_by_confirmation(podcast.id, user_id) do
      conn
      |> put_flash(:info, "Ownership confirmed. The user manages this podcast now.")
      |> render("grant_ownership.html", podcast: podcast, claimant: nil, token: nil)
    else
      {:error, reason} ->
        conn
        |> put_flash(:error, claim_error(reason))
        |> render("grant_ownership.html", podcast: podcast, claimant: nil, token: nil)
    end
  end

  defp claim_error(:expired), do: "The link has expired."
  defp claim_error(:already_assigned), do: "This podcast is managed by someone already."
  defp claim_error(_reason), do: "The link is invalid."

  def feeds(conn, %{"id" => id}) do
    podcast =
      Repo.get!(Podcast, id)
      |> Repo.preload(feeds: :alternate_feeds)

    render(conn, "feeds.html", podcast: podcast)
  end

  def liked(conn, _params) do
    liked_podcasts =
      from(p in Podcast,
        select: [p.likes_count, p.id, p.title],
        order_by: [fragment("? DESC NULLS LAST", p.likes_count)],
        limit: 100
      )
      |> Repo.all()

    render(conn, "liked.html", liked_podcasts: liked_podcasts)
  end

  def popular(conn, _params) do
    popular_podcasts =
      from(p in Podcast,
        select: [p.subscriptions_count, p.id, p.title],
        order_by: [fragment("? DESC NULLS LAST", p.subscriptions_count)],
        limit: 100
      )
      |> Repo.all()

    render(conn, "popular.html", popular_podcasts: popular_podcasts)
  end
end
