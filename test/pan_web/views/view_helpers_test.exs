defmodule PanWeb.ViewHelpersTest do
  use ExUnit.Case, async: true

  alias Phoenix.HTML.Safe

  defp markdown(content, options \\ []) do
    content
    |> PanWeb.ViewHelpers.markdown(options)
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  describe "markdown/2 links (#706)" do
    test "http(s) links open in a new tab" do
      assert markdown("[a](https://example.org) [b](http://example.org)") ==
               ~s|<p><a href="https://example.org" target="_blank" rel="noopener noreferrer">a</a> | <>
                 ~s|<a href="http://example.org" target="_blank" rel="noopener noreferrer">b</a></p>|
    end

    test "autolinks open in a new tab" do
      assert markdown("see https://example.org") =~
               ~s|<a href="https://example.org" target="_blank" rel="noopener noreferrer">|
    end

    test "mailto and relative links stay in the same tab" do
      html = markdown("[m](mailto:someone@example.org) [r](/podcasts/1) [h](#top)")

      refute html =~ "target"
      refute html =~ "rel="
      assert html =~ ~s|href="mailto:someone@example.org"|
      assert html =~ ~s|href="/podcasts/1"|
      assert html =~ ~s|href="#top"|
    end

    test "unsafe schemes still lose their href" do
      html = markdown("[x](javascript:alert(1))")

      refute html =~ "javascript"
      refute html =~ "target"
    end

    test "data-sourcepos is kept for the pad preview" do
      assert markdown("[a](https://example.org)", sourcepos: true) =~
               ~s|<a data-sourcepos="1:1-1:24" href="https://example.org" target="_blank" rel="noopener noreferrer">|
    end
  end
end
