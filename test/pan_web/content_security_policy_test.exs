defmodule PanWeb.ContentSecurityPolicyTest do
  use PanWeb.ConnCase

  test "browser pages get a report-only policy with a fresh nonce", %{conn: conn} do
    conn = get(conn, "/categories")

    assert [policy] = get_resp_header(conn, "content-security-policy-report-only")
    assert policy =~ "default-src 'self'"
    assert policy =~ "script-src 'self' 'nonce-#{conn.assigns.csp_nonce}' 'unsafe-eval'"
    refute policy =~ ~r/script-src[^;]*'unsafe-inline'/

    # put_secure_browser_headers' minimal policy stays the enforced one
    assert get_resp_header(conn, "content-security-policy") == [
             "base-uri 'self'; frame-ancestors 'self';"
           ]
  end

  test "every request gets its own nonce", %{conn: conn} do
    first = get(conn, "/categories").assigns.csp_nonce
    second = get(build_conn(), "/categories").assigns.csp_nonce

    assert first != second
  end

  test "the Podlove Web Player's URL-bearing scripts hash as browsers report them on prod" do
    hashes = PanWeb.ContentSecurityPolicy.podlove_script_hashes("https://panoptikum.social")

    # on panoptikum.social, Firefox accepted the first two and asked for the third
    for reported <- [
          "'sha256-4+hnezgP8/v24b2PA3biARY5j44JfeEruuXP5uSM75w='",
          "'sha256-CS2MFB5mRjHPstOsYPX9N2sZCiSmRRTZhtLP8atlmUk='",
          "'sha256-sJpY9trRuGJnOiZ+k6wp8n5K8kqkhv2AIOGVH2laZ1w='"
        ] do
      assert reported in hashes
    end
  end
end
