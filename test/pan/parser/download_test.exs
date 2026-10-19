defmodule Pan.Parser.DownloadTest do
  use ExUnit.Case, async: true

  import Pan.Parser.Download, only: [check_for_redirect_loop: 2]

  @url "https://example.com/podcast/feed.xml"

  describe "check_for_redirect_loop/2" do
    test "an absolute target is followed as it is" do
      assert check_for_redirect_loop(@url, "https://new.example.com/feed") ==
               {:redirect, "https://new.example.com/feed"}
    end

    test "a root-relative target stays on the host" do
      assert check_for_redirect_loop(@url, "/new.xml") ==
               {:redirect, "https://example.com/new.xml"}
    end

    test "a path-relative target resolves against the directory of the URL" do
      assert check_for_redirect_loop(@url, "new.xml") ==
               {:redirect, "https://example.com/podcast/new.xml"}
    end

    test "a protocol-relative target keeps the scheme" do
      assert check_for_redirect_loop(@url, "//cdn.example.net/feed.xml") ==
               {:redirect, "https://cdn.example.net/feed.xml"}
    end

    test "a redirect to the URL itself is refused, also when given relatively" do
      assert check_for_redirect_loop(@url, @url) == {:error, "redirects to itself"}
      assert check_for_redirect_loop(@url, "/podcast/feed.xml") == {:error, "redirects to itself"}
    end

    test "http to https is a redirect, not a loop" do
      assert check_for_redirect_loop("http://example.com/feed", "https://example.com/feed") ==
               {:redirect, "https://example.com/feed"}
    end
  end
end
