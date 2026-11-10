On 2026-10-13 a snippet I gave for the prod remote console failed: the user pastes
it into IEx, and IEx evaluates each complete line on its own, so

```elixir
episode_ids =
  from(...)
  |> Repo.all()
```

stops after `from(...)` (`episode_ids` became the query) and the `|> Repo.all()`
line raises "pipe shorthand is not allowed immediately after a match expression
in IEx". Pipes are fine inside a still-open block (`fn ... end`, `do ... end`).

**Why:** a snippet tested with `Code.eval_file` on dev (tidewave) behaves
differently from pasting into `iex` on prod; a half-run snippet can be dangerous
when the later lines change data.
**How to apply:** for snippets meant for the prod console, write top-level
statements without line-leading pipes after `=`: `x = Repo.all(from(...))`, or
put the whole pipeline on one line, or wrap it in parentheses. Keep a dry_run
switch for anything that changes data. Related: [sql-now-timezone](sql-now-timezone.md).
