# Script for populating the database. You can run it as:
#     mix run priv/repo/seeds.exs

alias Pan.Repo
alias Pan.Language
alias Pan.User

Repo.get_by(Language, shortcode: "de-DE") ||
  Repo.insert!(%Language{shortcode: "de-DE", name: "DE"})

Repo.get_by(Language, shortcode: "de") ||
  Repo.insert!(%Language{shortcode: "de", name: "DE"})

Repo.get_by(Language, shortcode: "de-at") ||
  Repo.insert!(%Language{shortcode: "de-at", name: "DE"})

Repo.get_by(User, name: "unknown") ||
  Repo.insert!(%User{name: "Jane Doe",
                     email: "jane@podcasterei.at",
                     username: "unknown",
                     podcaster: true})