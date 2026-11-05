defmodule Pan.Email do
  import Swoosh.Email
  use Gettext, backend: PanWeb.Gettext

  # Languages (#583): login link and verification go out in the current page
  # language (sent during the request), the retention notice in the
  # recipient's setting. Claim requests go to feed addresses: they use the
  # persona's user setting or the language of the podcasts (#591, #592).
  # Error mails stay English.

  def login_link_html_email(token, email_address) do
    url = PanWeb.Router.Helpers.session_url(PanWeb.Endpoint, :login_via_token, token: token)

    new(
      to: email_address,
      from: "noreply@panoptikum.social",
      subject: "Panoptikum - " <> dgettext("frontend", "Login link"),
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>#{dgettext("frontend", "Hello!")}</p>
            <p>#{dgettext("frontend", "You can now login using this %{link}.", link: link(url, dgettext("frontend", "Login link")))}</p>
            <p>#{dgettext("frontend", "- The Panoptikum Team.")}</p>
          </body>
        </html>
      """
    )
  end

  # `reasons` is a list of :inactive (no login for two years) and :unverified
  # (email address never verified), `delete_after` the date the grace period ends.
  def retention_notice_html_email(user, token, reasons, delete_after) do
    Gettext.with_locale(PanWeb.Gettext, user.locale || "en", fn ->
      retention_notice(user, token, reasons, delete_after)
    end)
  end

  defp retention_notice(user, token, reasons, delete_after) do
    url = PanWeb.Router.Helpers.session_url(PanWeb.Endpoint, :login_via_notice, token: token)

    reason_items =
      Enum.map_join(reasons, fn
        :inactive ->
          "<li>" <>
            dgettext("frontend", "You have not logged in for more than two years.") <> "</li>"

        :unverified ->
          "<li>" <>
            dgettext("frontend", "You have not verified your email address yet.") <> "</li>"
      end)

    new(
      to: user.email,
      from: "noreply@panoptikum.social",
      subject: "Panoptikum - " <> dgettext("frontend", "Your account will be deleted soon"),
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>#{dgettext("frontend", "Hello %{username}!", username: escape(user.username))}</p>
            <p>#{dgettext("frontend", "Your Panoptikum account is marked for deletion:")}</p>
            <ul>#{reason_items}</ul>
            <p>#{dgettext("frontend", "Unless you log in before %{date}, your account and its data will be deleted. To keep it, just use this %{link}. It logs you in and verifies your email address. It is valid for 30 days.", date: Calendar.strftime(delete_after, dgettext("frontend", "%Y-%m-%d")), link: link(url, dgettext("frontend", "Login link")))}</p>
            <p>#{dgettext("frontend", "If you don't want to keep your account, you don't have to do anything.")}</p>
            <p>#{dgettext("frontend", "- The Panoptikum Team.")}</p>
          </body>
        </html>
      """
    )
  end

  def email_verification_link_html_email(token, email_address) do
    url = PanWeb.Router.Helpers.session_url(PanWeb.Endpoint, :verify_email, token: token)

    new(
      to: email_address,
      from: "noreply@panoptikum.social",
      subject: "Panoptikum - " <> dgettext("frontend", "Email Verification"),
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>#{dgettext("frontend", "Hello!")}</p>
            <p>#{dgettext("frontend", "Please verify your email address by clicking on this link: %{link}", link: link(url, dgettext("frontend", "Verify Email")))}</p>
            <p>#{dgettext("frontend", "If you don't verify your email address, you won't be able to claim personas.")}</p>
            <p>#{dgettext("frontend", "- The Panoptikum Team.")}</p>
          </body>
        </html>
      """
    )
  end

  def confirm_persona_claim_link_html_email(token, user, persona) do
    Gettext.with_locale(PanWeb.Gettext, persona_locale(persona), fn ->
      persona_claim(token, user, persona.email)
    end)
  end

  defp persona_locale(%{user_id: user_id} = persona) when is_integer(user_id) do
    case Pan.Repo.get(PanWeb.User, user_id) do
      %{locale: locale} when is_binary(locale) -> locale
      _no_setting -> persona_locale(%{persona | user_id: nil})
    end
  end

  defp persona_locale(persona),
    do: persona.id |> PanWeb.Persona.language_codes() |> PanWeb.Locale.from_language_codes()

  defp persona_claim(token, user, email_address) do
    profile_url = PanWeb.Router.Helpers.user_frontend_url(PanWeb.Endpoint, :show, user)

    grant_url =
      PanWeb.Router.Helpers.persona_frontend_url(PanWeb.Endpoint, :grant_access, user,
        token: token
      )

    new(
      to: email_address,
      from: "noreply@panoptikum.social",
      subject:
        "Panoptikum - " <> dgettext("frontend", "Persona manifestation confirmation request"),
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>#{dgettext("frontend", "Hello!")}</p>
            <p>#{dgettext("frontend", "The user with the full name %{name} in %{panoptikum} would like to be added as a manifestation of the persona with your email address.", name: "<b>" <> escape(user.name) <> "</b>", panoptikum: link("https://panoptikum.social", "Panoptikum.social"))}</p>
            <p>#{dgettext("frontend", "The user's user name is %{username} with the email address %{email}.", username: "<b>" <> escape(user.username) <> "</b>", email: link("mailto:" <> escape(user.email), user.email))}</p>
            <p>#{dgettext("frontend", "You could ...")}
              <ul>
                <li>#{dgettext("frontend", "ignore this mail, if you don't want to provide access.")}</li>
                <li>#{dgettext("frontend", "reply to this email, if you have questions to that user, before you want to provide access.")}</li>
                <li>#{dgettext("frontend", "check out the user's %{profile} in Panoptikum before.", profile: link(profile_url, dgettext("frontend", "public profile")))}</li>
                <li>#{dgettext("frontend", "grant access to your persona within the next 48 hours by clicking on this link: %{link}", link: link(grant_url, dgettext("frontend", "Grant Access")))}</li>
              </ul>
            </p>
            <p>#{dgettext("frontend", "- The Panoptikum Team.")}</p>
          </body>
        </html>
      """
    )
  end

  def confirm_podcast_claim_link_html_email(token, user, podcast, email_address) do
    locale = podcast.id |> PanWeb.Podcast.language_codes() |> PanWeb.Locale.from_language_codes()

    Gettext.with_locale(PanWeb.Gettext, locale, fn ->
      podcast_claim(token, user, podcast, email_address)
    end)
  end

  defp podcast_claim(token, user, podcast, email_address) do
    grant_url =
      PanWeb.Router.Helpers.podcast_frontend_url(PanWeb.Endpoint, :confirm_ownership, podcast,
        token: token
      )

    new(
      to: email_address,
      from: "noreply@panoptikum.social",
      subject: "Panoptikum - " <> dgettext("frontend", "Podcast ownership confirmation request"),
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>#{dgettext("frontend", "Hello!")}</p>
            <p>#{dgettext("frontend", "The user %{name} (user name %{username}, email address %{email}) in %{panoptikum} would like to manage the podcast %{podcast}. Your address is listed as the owner in that podcast's feed.", name: "<b>" <> escape(user.name) <> "</b>", username: "<b>" <> escape(user.username) <> "</b>", email: escape(user.email), panoptikum: link("https://panoptikum.social", "Panoptikum.social"), podcast: "<b>" <> escape(podcast.title) <> "</b>")}</p>
            <p>#{dgettext("frontend", "You could ...")}
              <ul>
                <li>#{dgettext("frontend", "ignore this mail, if you don't want to provide access.")}</li>
                <li>#{dgettext("frontend", "reply to this email, if you have questions before you want to provide access.")}</li>
                <li>#{dgettext("frontend", "confirm within the next 48 hours by opening this link and approving there: %{link}", link: link(grant_url, dgettext("frontend", "Confirm ownership")))}</li>
              </ul>
            </p>
            <p>#{dgettext("frontend", "- The Panoptikum Team.")}</p>
          </body>
        </html>
      """
    )
  end

  def error_notification(mail_body, from, to) do
    {:ok, hostname} = :inet.gethostname()

    new(
      to: to,
      from: from,
      subject: "Panoptikum - #{hostname} - Error Notification",
      text_body: mail_body
    )
  end

  defp link(url, label), do: ~s(<a href="#{url}">#{escape(label)}</a>)

  # User and feed data go into HTML mail bodies, some of them sent to third
  # parties (persona and podcast claims), so they must not carry markup.
  defp escape(value), do: value |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
end
