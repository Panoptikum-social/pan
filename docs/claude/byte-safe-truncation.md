When truncating a string to fit a database column defined in **bytes** (e.g. `varchar(255)`), do NOT use `String.slice`, `String.codepoints |> Enum.take`, or any character-count approach — these count Unicode grapheme clusters or codepoints, not bytes. A 255-codepoint string with multi-byte characters can exceed 255 bytes.

**Correct pattern** (`to_255/1` in `lib/pan/parser/helpers.ex`):
```elixir
def to_255(nil), do: nil

def to_255(text) do
  if byte_size(text) > 255 do
    <<head::binary-size(255), _::binary>> = text
    trim_incomplete_codepoint(head)
  else
    text
  end
end

defp trim_incomplete_codepoint(bin) do
  if String.valid?(bin),
    do: bin,
    else: trim_incomplete_codepoint(:binary.part(bin, 0, byte_size(bin) - 1))
end
```

Slices at byte 255, then walks back (at most 3 steps — UTF-8 sequences are max 4 bytes) until the binary is valid UTF-8.

**Why:** The old implementation used `String.codepoints() |> Enum.take(255) |> Enum.join()` which could still produce strings exceeding 255 bytes for non-ASCII content. Found and fixed 2026-06-01.

**How to apply:** Any field with a byte-length DB constraint must use byte-level slicing, not character counting. `truncate_string/2` in `view_helpers.ex` is for display (character limit) — it is NOT the same as `to_255/1`.
