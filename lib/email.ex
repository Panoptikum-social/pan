defmodule Pan.Email do
  import Bamboo.Email
  import Phoenix.HTML.Link

  def login_link_html_email(token, email_address) do
    new_email(
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
              #{link("Login link", to: PanWeb.Router.Helpers.session_url(PanWeb.Endpoint, :login_via_token, token: token))}
            </p>
            <p>- The Panoptikum Team.</p>
          </body>
        </html>
      """
    )
  end

  def email_confirmation_link_html_email(token, email_address) do
    new_email(
      to: email_address,
      from: "noreply@panoptikum.social",
      subject: "Panoptikum - Email Confirmation",
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>Hello!</p>
            <p>Please confirm your email address clicking on this link:
              #{link("Confirm Email", to: PanWeb.Router.Helpers.session_url(PanWeb.Endpoint, :confirm_email, token: token))}
            </p>

            <p>If you don't confirm your email address, you won't be able to claim personas.</p>
            <p>- The Panoptikum Team.</p>
          </body>
        </html>
      """
    )
  end

  def confirm_persona_claim_link_html_email(token, user, email_address) do
    new_email(
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
              <a href=#{"mailto:" <> user.email} #{user.email} </a>
              .
            </p>
            <p>You could ...
              <ul>
                <li>ignore this mail, if you don't want to provide access.</li>
                <li>reply to this email, if you have questions to that user, before you want to provide access.</li>
                <li>check out the user's
                #{link("public profile", to: PanWeb.Router.Helpers.user_frontend_url(PanWeb.Endpoint, :show, user))} in Panoptikum before.</li>
                <li>grant access to your persona within the next 48 hours by clicking on this link:
                #{link("Grant Access", to: PanWeb.Router.Helpers.persona_frontend_url(PanWeb.Endpoint, :grant_access, user, token: token))}
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

    new_email(
      to: to,
      from: from,
      subject: "Panoptikum - #{hostname} - Error Notification",
      text_body: mail_body
    )
  end

  def pro_expiration_notification(email_address) do
    new_email(
      to: email_address,
      from: "noreply@panoptikum.social",
      subject: "Panoptikum - Your pro account expires soon",
      html_body: ~s"""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width">
          </head>
          <body>
            <p>Hello!</p>
            <p> We would like to let you know, that your Panoptikum pro account will expire in less than one week. </p>
            <p>
              If you would like to extend your pro account, please login to your account and find
              more information on your
              #{link("Your profile page", to: PanWeb.Router.Helpers.user_frontend_url(PanWeb.Endpoint, :my_profile))} .
            </p>
            <p>We won't bother you with any more emails, promised!</p>
            <p>- The Panoptikum Team.</p>
          </body>
        </html>
      """
    )
  end
end
