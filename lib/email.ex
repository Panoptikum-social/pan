defmodule Pan.Email do
  import Swoosh.Email

  def login_link_html_email(token, email_address) do
    url = PanWeb.Router.Helpers.session_url(PanWeb.Endpoint, :login_via_token, token: token)

    new(
      to: email_address,
      from: "noreply@panoptikum.social",
      subject: "Panoptikum - Login link",
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>Hello!</p>
            <p>You can now login using this
              <a href="#{url}">Login link</a>
            </p>
            <p>- The Panoptikum Team.</p>
          </body>
        </html>
      """
    )
  end

  # `reasons` is a list of :inactive (no login for two years) and :unverified
  # (email address never verified), `delete_after` the date the grace period ends.
  def retention_notice_html_email(user, token, reasons, delete_after) do
    url = PanWeb.Router.Helpers.session_url(PanWeb.Endpoint, :login_via_notice, token: token)

    reason_items =
      Enum.map_join(reasons, fn
        :inactive -> "<li>You have not logged in for more than two years.</li>"
        :unverified -> "<li>You have not verified your email address yet.</li>"
      end)

    new(
      to: user.email,
      from: "noreply@panoptikum.social",
      subject: "Panoptikum - Your account will be deleted soon",
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>Hello #{user.username}!</p>
            <p>Your Panoptikum account is marked for deletion:</p>
            <ul>#{reason_items}</ul>
            <p>Unless you log in before #{delete_after}, your account and its data will be deleted.
              To keep it, just use this
              <a href="#{url}">Login link</a>.
              It logs you in and verifies your email address. It is valid for 30 days.
            </p>
            <p>If you don't want to keep your account, you don't have to do anything.</p>
            <p>- The Panoptikum Team.</p>
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
      subject: "Panoptikum - Email Verification",
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>Hello!</p>
            <p>Please verify your email address clicking on this link:
              <a href="#{url}">Verify Email</a>
            </p>

            <p>If you don't verify your email address, you won't be able to claim personas.</p>
            <p>- The Panoptikum Team.</p>
          </body>
        </html>
      """
    )
  end

  def confirm_persona_claim_link_html_email(token, user, email_address) do
    profile_url = PanWeb.Router.Helpers.user_frontend_url(PanWeb.Endpoint, :show, user)

    grant_url =
      PanWeb.Router.Helpers.persona_frontend_url(PanWeb.Endpoint, :grant_access, user,
        token: token
      )

    new(
      to: email_address,
      from: "noreply@panoptikum.social",
      subject: "Panoptikum - Persona manifestation confirmation request",
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>Hello!</p>
            <p>The User with the full name
              <b> #{user.name} </b>
              in <a href="https://panoptikum.social"> Panoptikum.social </a>
              would like to have access to manifest her/himself to the persona with your email address.
            </p>
            <p>The user's user name is
              <b> #{user.username} </b>
              with the email address
              <a href="mailto:#{user.email}">#{user.email}</a>
              .
            </p>
            <p>You could ...
              <ul>
                <li>ignore this mail, if you don't want to provide access.</li>
                <li>reply to this email, if you have questions to that user, before you want to provide access.</li>
                <li>check out the user's
                <a href="#{profile_url}">public profile</a> in Panoptikum before.</li>
                <li>grant access to your persona within the next 48 hours by clicking on this link:
                <a href="#{grant_url}">Grant Access</a>
                </li>
              </ul>
            </p>
            <p>- The Panoptikum Team.</p>
          </body>
        </html>
      """
    )
  end

  def confirm_podcast_claim_link_html_email(token, user, podcast, email_address) do
    escape = &(&1 |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string())

    grant_url =
      PanWeb.Router.Helpers.podcast_frontend_url(PanWeb.Endpoint, :confirm_ownership, podcast,
        token: token
      )

    new(
      to: email_address,
      from: "noreply@panoptikum.social",
      subject: "Panoptikum - Podcast ownership confirmation request",
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>Hello!</p>
            <p>The user <b>#{escape.(user.name)}</b> (user name <b>#{escape.(user.username)}</b>,
              email address #{escape.(user.email)}) in
              <a href="https://panoptikum.social">Panoptikum.social</a>
              would like to manage the podcast <b>#{escape.(podcast.title)}</b>. Your address is
              listed as the owner in that podcast's feed.
            </p>
            <p>You could ...
              <ul>
                <li>ignore this mail, if you don't want to provide access.</li>
                <li>reply to this email, if you have questions before you want to provide access.</li>
                <li>confirm within the next 48 hours by opening this link and approving there:
                <a href="#{grant_url}">Confirm ownership</a>
                </li>
              </ul>
            </p>
            <p>- The Panoptikum Team.</p>
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
end
