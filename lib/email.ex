defmodule Pan.Email do
  use Bamboo.Phoenix, view: Pan.EmailView

  def welcome_text_email(email_address) do
    new_email()
    |> to(email_address)
    |> from("noreply@panoptikum.io")
    |> subject("Welcome!")
    |> put_text_layout({Pan.LayoutView, "email.text"})
    |> render("welcome.text")
  end

  def welcome_html_email(email_address) do
    email_address
    |> welcome_text_email()
    |> put_html_layout({Pan.LayoutView, "email.html"})
    |> render("welcome.html")
  end
end