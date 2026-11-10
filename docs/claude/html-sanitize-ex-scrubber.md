The project has a custom scrubber at `lib/HtmlSanitizeEx/Scrubber/basic_html_reduced.ex`. It was originally written using the old `Meta` macro approach:

```elixir
require HtmlSanitizeEx.Scrubber.Meta
alias HtmlSanitizeEx.Scrubber.Meta
Meta.remove_cdata_sections_before_scrub()
Meta.strip_comments()
Meta.allow_tag_with_these_attributes("p", [])
# ...
Meta.strip_everything_not_covered()  # deprecated
```

The correct modern approach is:

```elixir
use HtmlSanitizeEx, extend: :strip_tags

allow_tag_with_uri_attributes("a", ["href"], ["http", "https", "mailto"])
allow_tag_with_these_attributes("p", [])
# ... macros imported directly, no Meta. prefix
# no strip_everything_not_covered needed
```

`use HtmlSanitizeEx` automatically adds `@before_compile HtmlSanitizeEx.ScrubberCompiler`, imports all macros, handles `remove_cdata_sections_before_scrub` and `strip_comments`, and generates the catch-all `scrub("" <> text), do: text` clause for plain text nodes.

**Why:** Without `use HtmlSanitizeEx` (or the deprecated `Meta.strip_everything_not_covered()`), the `ScrubberCompiler` never runs, so plain-text HTML nodes (strings with no tags) hit no matching `scrub/1` clause → `FunctionClauseError`. This caused podcast import to crash on Italian episode descriptions with no HTML markup.
**How to apply:** Any new or modified scrubber in this project must use `use HtmlSanitizeEx, extend: :strip_tags` (or another base). Never use the `Meta.*` macro approach.
