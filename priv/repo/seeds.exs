# Script for populating the database. You can run it as:
#     mix run priv/repo/seeds.exs

alias Pan.Repo
alias PanWeb.User

Repo.get_by(User, username: "unknown") ||
  Repo.insert!(%User{
    name: "Jane Doe",
    email: "jane@podcasterei.at",
    username: "unknown",
    podcaster: true
  })

admin_changeset =
  User.registration_changeset(
    %User{},
    %{
      name: "Admin",
      email: "admin@panoptikum.io",
      username: "admin",
      podcaster: true,
      password: "changeme",
      password_confirmation: "changeme"
    }
  )

Repo.get_by(User, username: "admin") ||
  Repo.insert!(admin_changeset)

Repo.get_by(User, username: "admin")
|> User.changeset(%{admin: true})
|> Repo.update()
