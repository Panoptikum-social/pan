# Handy mainenance tasks

## Dump and restore PostgreSQL database

pg_dump -U postgres pan_prod > ./pan_prod.sql
psql -U postgres pan_prod < pan_prod.sql

## Update podcast counters

```Elixir
PanWeb.Podcast.update_counters(PanWeb.Podcast.changeset(Pan.Repo.get(PanWeb.Podcast, 468))
```
