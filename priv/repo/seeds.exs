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

Repo.get_by(Language, shortcode: "de-AT") ||
  Repo.insert!(%Language{shortcode: "de-AT", name: "DE"})

Repo.get_by(Language, shortcode: "en-US") ||
  Repo.insert!(%Language{shortcode: "en-US", name: "EN"})

Repo.get_by(User, username: "unknown") ||
  Repo.insert!(%User{name: "Jane Doe",
                     email: "jane@podcasterei.at",
                     username: "unknown",
                     podcaster: true})

Repo.get_by(User, username: "admin") ||
  Repo.insert!(%User{name: "Admin",
                     email: "admin@panoptikum.io",
                     username: "admin",
                     podcaster: true,
                     admin: true,
                     password: "changeme"})