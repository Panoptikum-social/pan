defmodule Pan.Search.HighlightHtmlTest do
  use ExUnit.Case, async: true

  alias Pan.Parser.Helpers

  defp html(snippet), do: snippet |> Pan.Search.highlight_html() |> Phoenix.HTML.safe_to_string()

  # Manticore decodes entities in snippets, so encoded markup comes back live (#648)
  test "escapes markup in a snippet but keeps the match markers" do
    snippet =
      ~s|<strong style="color: #DA4453;">hello</strong> <img src=x onerror=alert(1)> & more|

    assert html(snippet) ==
             ~s|<strong style="color: #DA4453;">hello</strong> &lt;img src=x onerror=alert(1)&gt; &amp; more|
  end

  test "a snippet without markup stays as it is" do
    assert html("plain text") == "plain text"
  end

  # the podcast page renders the summary raw after this (#647)
  test "scrub removes dangerous markup from a podcast summary" do
    scrubbed = Helpers.scrub(~s|Hi <img src=x onerror=alert(1)><script>x()</script><form></form>|)
    refute scrubbed =~ "onerror"
    refute scrubbed =~ "<script"
    refute scrubbed =~ "<form"
  end
end
