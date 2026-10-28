defmodule Pan.Repo.Migrations.SeedFormerPodcasts do
  use Ecto.Migration
  import Ecto.Query

  # From the prod journal ("Deleted podcast" and "Podcast merge" log lines)
  # and wisspod.de's podcast list, 2026-10-28, merge chains resolved. The
  # journal has no dates, so deleted_at stays empty. Ids that are still a
  # podcast (a database older than the journal) are skipped.
  def up do
    rows =
      Application.app_dir(:pan, "priv/repo/data/former_podcasts.json")
      |> File.read!()
      |> Jason.decode!(keys: :atoms)

    ids = Enum.map(rows, & &1.id)
    existing = repo().all(from(p in "podcasts", where: p.id in ^ids, select: p.id))

    rows
    |> Enum.reject(&(&1.id in existing))
    |> Enum.chunk_every(500)
    |> Enum.each(&repo().insert_all("former_podcasts", &1, on_conflict: :nothing))
  end

  def down do
    repo().delete_all("former_podcasts")
  end
end
