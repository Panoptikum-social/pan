# Handy mainenance tasks

## Dump and restore PostgreSQL database

pg_dump -U postgres pan_prod > ./pan_prod.sql
psql -U postgres pan_prod < pan_prod.sql

## Update podcast counters

```Elixir
PanWeb.Podcast.update_counters(PanWeb.Podcast.changeset(Pan.Repo.get(PanWeb.Podcast, 468))
```

## Image deduplication

Duplicate images can be replaced with hard links:
`rdfind . -makehardlinks true`
Depending on who the dir is owned by you might want to run it as a different user / root.
