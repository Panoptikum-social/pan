defmodule Pan.Parser.SsrfGuard do
  @moduledoc """
  Blocks outbound feed fetches whose target resolves to a loopback,
  link-local, or private-network address.

  Feed URLs (`self_link_url`, enclosure URLs, ...) are attacker/podcaster
  controlled content that this app fetches server-side — nothing stops a
  malicious feed, or a URL typed in when adding a podcast, from pointing at
  127.0.0.1, an internal service, or a cloud metadata endpoint
  (169.254.169.254, used by AWS/GCP/Azure/Hetzner Cloud alike) unless we
  check first. This is a classic SSRF (Server-Side Request Forgery) guard.

  Known limitation: this resolves the host and checks *those* addresses,
  then the caller connects separately — a DNS answer that changes between
  the two (DNS rebinding) isn't caught. Good enough against the realistic
  threat here (a static malicious feed URL), not a hard guarantee against a
  DNS server actively racing the check.
  """

  require Logger
  import Bitwise

  @doc """
  Returns `:ok` if `url`'s host resolves only to addresses safe to fetch, or
  `{:error, :blocked_host}` if any resolved address falls in a blocked
  range. Fails open (`:ok`) when the URL can't be parsed or the host can't
  be resolved at all — that's not an SSRF concern, the HTTP client will
  raise its own error trying to connect.
  """
  def check(url) do
    with %URI{host: host} when is_binary(host) and host != "" <- URI.parse(url),
         {:ok, addresses} <- resolve(host) do
      if Enum.any?(addresses, &blocked_ip?/1) do
        Logger.warning("SSRF guard blocked #{url} (#{host} resolves to a blocked-range address)")
        {:error, :blocked_host}
      else
        :ok
      end
    else
      _ -> :ok
    end
  end

  defp resolve(host) do
    charlist = String.to_charlist(host)

    addresses =
      for family <- [:inet, :inet6],
          {:ok, addrs} <- [:inet.getaddrs(charlist, family)],
          addr <- addrs,
          do: addr

    case addresses do
      [] -> :error
      addrs -> {:ok, addrs}
    end
  end

  # IPv4: loopback, link-local (incl. cloud metadata services), RFC1918
  # private ranges, "this network", and multicast/reserved space.
  @doc false
  def blocked_ip?({127, _, _, _}), do: true
  def blocked_ip?({169, 254, _, _}), do: true
  def blocked_ip?({10, _, _, _}), do: true
  def blocked_ip?({172, b, _, _}) when b in 16..31, do: true
  def blocked_ip?({192, 168, _, _}), do: true
  def blocked_ip?({0, _, _, _}), do: true
  def blocked_ip?({a, _, _, _}) when a >= 224, do: true

  # IPv6: loopback (::1), link-local (fe80::/10), unique local (fc00::/7).
  def blocked_ip?({0, 0, 0, 0, 0, 0, 0, 1}), do: true
  def blocked_ip?({hd, _, _, _, _, _, _, _}) when (hd &&& 0xFFC0) == 0xFE80, do: true
  def blocked_ip?({hd, _, _, _, _, _, _, _}) when (hd &&& 0xFE00) == 0xFC00, do: true

  def blocked_ip?(_), do: false
end
