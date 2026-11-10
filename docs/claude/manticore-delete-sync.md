Every code path that does a real `Repo.delete!`/`Repo.delete` on a Manticore-indexed record (Podcast, Persona, Episode, Category) should pair it with `Search.<Model>.delete_index(id)`. This is correctly wired in:
- `PanWeb.PodcastController.delete/2` (lib/pan_web/controllers/podcast_controller.ex) — also cleans up each episode's index entry before deleting the podcast.
- `PanWeb.PersonaController.merge/2` and `PanWeb.PersonaController.delete/2` (lib/pan_web/controllers/persona_controller.ex)
- `PanWeb.Admin.QueryBuilder.delete/2` (lib/pan_web/admin/query_builder.ex) — **fixed 2026-07-29**. Previously only called `model.delete_search_index(record.id)` if `Map.has_key?(record, :elastic)`, a leftover pre-Manticore (Elasticsearch) check that no schema satisfies, so the generic checkbox-select delete in `PanWeb.Admin.IndexGrid` silently orphaned Manticore entries for every model. Now derives the search module dynamically — `Module.concat(Pan.Search, model |> Module.split() |> List.last())` — and calls `delete_index/1` on it only if `Code.ensure_loaded?/1` + `function_exported?/3` confirm it exists, so non-indexed models (the majority handled by this generic path) are a no-op.

**Known remaining gap:** unlike the dedicated `PodcastController.delete/2`, the generic databrowser path only cleans up the index entry for the record being deleted itself — it does NOT cascade to child records (e.g. deleting a Podcast via `/admin/databrowser/podcasts` won't clean up that podcast's episodes' index entries). User explicitly chose to accept this gap for now rather than add cascade handling to the generic path.

**Why:** discovered while auditing whether persona deletion cleans up Manticore like podcast deletion does; fixed same session once the `:elastic` leftover was identified as unambiguously dead code.

**How to apply:** if asked about search-index orphaning again, the generic admin databrowser is now covered for direct-model cleanup. Only the cascade-to-children case (podcast→episodes, and any other indexed parent/child relationship) remains open if it comes up again.

See also [ecto-on-delete-gotcha](ecto-on-delete-gotcha.md).
