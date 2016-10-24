defmodule Pan.Parser.User do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.User

  def get_or_create_by(name, email) do
    user = Repo.get_by(User, email: email)
    unless user, do: Repo.insert(%User{email: email, name: name, username: email, podcaster: true})

    user or Repo.get_by(User, email: email)
  end
end