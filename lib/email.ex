defmodule Pan.Email do
  use Bamboo.Phoenix, view: PanWeb.EmailView

  def login_link_html_email(token, email_address) do
    new_email()
    |> to(email_address)
    |> from("noreply@panoptikum.io")
    |> subject("Panoptikum - Login link")
    |> put_html_layout({PanWeb.LayoutView, "email.html"})
    |> render("login_link.html", token: token)
  end

  def email_confirmation_link_html_email(token, email_address) do
    new_email()
    |> to(email_address)
    |> from("noreply@panoptikum.io")
    |> subject("Panoptikum - Email Confirmation")
    |> put_html_layout({PanWeb.LayoutView, "email.html"})
    |> render("email_confirmation_link.html", token: token)
  end

  def confirm_persona_claim_link_html_email(token, user, email_address) do
    new_email()
    |> to(email_address)
    |> from("noreply@panoptikum.io")
    |> subject("Panoptikum - Persona manifestation confirmation request")
    |> put_html_layout({PanWeb.LayoutView, "email.html"})
    |> render("confirm_persona_claim_link.html", token: token, user: user)
  end

  def error_notification(mail_body, from, to) do
    {:ok, hostname} = :inet.gethostname()

    new_email()
    |> to(to)
    |> from(from)
    |> subject("Panoptikum - #{hostname} - Error Notification")
    |> text_body(mail_body)
  end

  def pro_expiration_notification(email_address) do
    new_email()
    |> to(email_address)
    |> from("noreply@panoptikum.io")
    |> subject("Panoptikum - Your pro account expires soon")
    |> put_html_layout({PanWeb.LayoutView, "email.html"})
    |> render("pro_expiration_notification.html")
  end
end
