defmodule Pan.Parser.SsrfGuardTest do
  use ExUnit.Case, async: true

  alias Pan.Parser.SsrfGuard

  describe "blocked_ip?/1" do
    test "blocks IPv4 loopback" do
      assert SsrfGuard.blocked_ip?({127, 0, 0, 1})
    end

    test "blocks IPv4 link-local, including cloud metadata addresses" do
      assert SsrfGuard.blocked_ip?({169, 254, 169, 254})
      assert SsrfGuard.blocked_ip?({169, 254, 0, 1})
    end

    test "blocks RFC1918 private ranges" do
      assert SsrfGuard.blocked_ip?({10, 0, 0, 1})
      assert SsrfGuard.blocked_ip?({172, 16, 0, 1})
      assert SsrfGuard.blocked_ip?({172, 31, 255, 255})
      assert SsrfGuard.blocked_ip?({192, 168, 1, 1})
    end

    test "does not block adjacent-but-public 172.x addresses" do
      refute SsrfGuard.blocked_ip?({172, 15, 255, 255})
      refute SsrfGuard.blocked_ip?({172, 32, 0, 0})
    end

    test "blocks 0.0.0.0/8 and multicast/reserved space" do
      assert SsrfGuard.blocked_ip?({0, 0, 0, 0})
      assert SsrfGuard.blocked_ip?({224, 0, 0, 1})
      assert SsrfGuard.blocked_ip?({255, 255, 255, 255})
    end

    test "allows ordinary public IPv4 addresses" do
      refute SsrfGuard.blocked_ip?({1, 1, 1, 1})
      refute SsrfGuard.blocked_ip?({93, 184, 216, 34})
    end

    test "blocks IPv6 loopback, link-local, and unique-local" do
      assert SsrfGuard.blocked_ip?({0, 0, 0, 0, 0, 0, 0, 1})
      assert SsrfGuard.blocked_ip?({0xFE80, 0, 0, 0, 0, 0, 0, 1})
      assert SsrfGuard.blocked_ip?({0xFC00, 0, 0, 0, 0, 0, 0, 1})
      assert SsrfGuard.blocked_ip?({0xFD12, 0x3456, 0, 0, 0, 0, 0, 1})
    end

    test "allows ordinary public IPv6 addresses" do
      refute SsrfGuard.blocked_ip?({0x2606, 0x4700, 0x4700, 0, 0, 0, 0, 0x1111})
    end
  end

  describe "check/1" do
    test "allows a URL whose host is a literal public IP" do
      assert SsrfGuard.check("http://1.1.1.1/feed.xml") == :ok
    end

    test "blocks a URL whose host is a literal loopback IP" do
      assert {:error, :blocked_host} = SsrfGuard.check("http://127.0.0.1/feed.xml")
    end

    test "blocks a URL pointing at the cloud metadata address" do
      assert {:error, :blocked_host} = SsrfGuard.check("http://169.254.169.254/feed.xml")
    end

    test "blocks localhost, which resolves to loopback without any network access" do
      assert {:error, :blocked_host} = SsrfGuard.check("http://localhost/feed.xml")
    end

    test "fails open on an unparseable URL" do
      assert SsrfGuard.check("not a url") == :ok
    end
  end
end
