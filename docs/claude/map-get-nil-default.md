`Map.get(map, :key, "default")` returns `nil` when the key exists with an explicit `nil` value. The fallback default only applies when the key is **absent** from the map.

**Why:** `Pan.Parser.Persona.get_or_insert/1` used `Map.put_new(map, :uri, email)` (line 39) which can write `uri: nil` when email is nil. Then `Map.get(map, :uri, "")` on the next line returned `nil` instead of `""`, causing `Repo.get_by(PanWeb.Persona, pid: nil)` → `ArgumentError` from Ecto.

**How to apply:** When building fallback chains for values that will be used in Ecto queries, guard with `&&` at the query callsite rather than relying on `Map.get` defaults:
```elixir
(pid && Repo.get_by(Persona, pid: pid)) ||
  (uri && Repo.get_by(Persona, pid: uri)) ||
  (email && Repo.one(from p in Persona, where: p.email == ^email))
```
This is safe because `nil && expr` short-circuits in Elixir.
