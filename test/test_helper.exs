ExUnit.start

Mix.Task.run "ecto.create", ~w(-r Pan.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r Pan.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(Pan.Repo)

