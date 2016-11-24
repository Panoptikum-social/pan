defmodule Pan.Email do
  use Bamboo.Phoenix, view: Pan.EmailView

  def login_link_html_email(token, email_address) do
    new_email()
    |> to(email_address)
    |> from("noreply@panoptikum.io")
    |> subject("Panoptikum - Login link")
    |> put_html_layout({Pan.LayoutView, "email.html"})
    |> render("login_link.html", token: token)
  end
end