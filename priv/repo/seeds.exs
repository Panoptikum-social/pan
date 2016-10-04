# Script for populating the database. You can run it as:
#     mix run priv/repo/seeds.exs

alias Pan.Repo
alias Pan.Language

Repo.get_by(Language, name: "DE") ||
  Repo.insert!(%Language{shortcode: "de-DE", name: "DE"})
