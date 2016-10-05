# Script for populating the database. You can run it as:
#     mix run priv/repo/seeds.exs

alias Pan.Repo
alias Pan.Language

Repo.get_by(Language, shortcode: "de-DE") ||
  Repo.insert!(%Language{shortcode: "de-DE", name: "DE"})

Repo.get_by(Language, shortcode: "de") ||
  Repo.insert!(%Language{shortcode: "de", name: "DE"})

Repo.get_by(Language, shortcode: "de-at") ||
  Repo.insert!(%Language{shortcode: "de-at", name: "DE"})
