## stream/3 resets by default — use reset: false for load-more

`stream(socket, :name, items)` resets the stream on every call, replacing all existing DOM items. For infinite scroll / load-more, always use:
```elixir
stream(socket, :name, new_items, reset: false)
```
This appends/updates items rather than replacing them. Safe for initial load (stream starts empty).

## has_gigs pattern for stream-based conditional rendering

Since streams can't be checked for emptiness in templates, track a separate boolean alongside:
```elixir
socket
|> stream(:gig_rows, rows, reset: false)
|> assign(has_gigs: rows != [] || Map.get(socket.assigns, :has_gigs, false))
```
The `|| Map.get(...)` ensures `has_gigs` stays `true` once set, even when a subsequent page returns empty rows (which would otherwise hide the panel mid-scroll).

## InfiniteScroll hook: re-observe in updated() for large screens

`IntersectionObserver` only fires on intersection *state changes* (non-intersecting → intersecting). If the sentinel is already visible after a DOM update, it never re-fires and infinite scroll stalls.

Fix in `assets/js/infinite_scroll.js`:
```javascript
updated() {
  this.pending = this.page();
  this.observer.unobserve(this.el);
  this.observer.observe(this.el);
}
```
Re-observing forces the observer to fire with the current intersection state.

## data-page attribute must match dataset.page

The hook reads `this.el.dataset.page` which maps to the HTML attribute `data-page`. Using `data-gigs-page` (camelCase maps to `dataset.gigsPage`) caused `this.page()` to always return `undefined`. Always use `data-page={@page}` on the sentinel element.

## has_more pattern — stop firing load-more when all data is loaded

Without a guard, the sentinel stays visible after the last page and keeps triggering `load-more` indefinitely. Track `has_more` in assigns and conditionally render the sentinel:

```elixir
# mount
items = fetch(page, per_page)
assign(socket, has_more: length(items) == per_page)

# handle_event "load-more"
items = fetch(page, per_page)
assign(socket, page: page, has_more: length(items) == per_page)
```

```heex
<div :if={@has_more} id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
```

`search.ex` already used this pattern (`has_more` from Manticore total count) and is the reference. Fixed 2026-04-27 in: `episode/index`, `recommendation/index`, `podcast/index`, `category/show`, `category/latest_episodes`, `podcast/show` + `episode_list`, `persona/show` (uses `has_more_gigs`).

For stream-based pages, check `length(returned_list) == per_page`. For non-stream (e.g. `category/show` which still uses `@podcasts`), the same check in `fetch/1`.

**Why:** The sentinel element stays in the DOM and visible after the last page loads, causing infinite load-more loops.
**How to apply:** Every new paginated list must track `has_more` from the start. Never render the InfiniteScroll sentinel unconditionally.

## has_more must be checked on raw items, not grouped rows

When data is grouped before display (e.g. gigs grouped by episode in `persona/show`), checking `length(grouped_rows) == per_page` is wrong — grouping reduces the count, so a full 10-gig page might yield only 7 rows, causing `has_more` to be `false` prematurely.

Always check the raw (ungrouped) fetch result:
```elixir
gigs = Gig.get_by_persona_ids(persona_ids, page, per_page)
grouped = Gig.grouped_gigs(gigs)
rows = ...  # grouped
assign(socket, has_more_gigs: length(gigs) == per_page)  # NOT length(rows)
```
Fixed 2026-05-01 in `persona/show.ex`.

## Sentinel must have non-zero height

A zero-height sentinel div (`<div ...></div>` with no content or height class) is unreliable with `IntersectionObserver` at `threshold: 1.0`. Add `class="h-4"` (or `h-24` as used in `podcast/episode_list.ex`) to guarantee the observer fires.

```heex
<div :if={@has_more} id="infinite-scroll" class="h-4" phx-hook="InfiniteScroll" data-page={@page}></div>
```
