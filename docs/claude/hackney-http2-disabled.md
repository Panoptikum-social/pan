hackney 4.8.4 defaults to HTTP/2 via ALPN; its HTTP/2 client hangs on larger response bodies (4 MB feed of podcast 3872: never completes, HTTP/1.1 takes 5 s). Fixed 2026-10-02 with `config :hackney, default_protocols: [:http1]` in config/config.exs (bcc91098), deployed and confirmed on prod 2026-10-02 (3872 probes 200, reactivated). Also: hackney 4 turns HEAD into GET on 301/302/303 when `follow_redirect: true` — `Pan.Parser.Download.head/2` follows redirects itself for that reason.

**Why:** regression from the hackney 4 upgrade (see [httpoison-req-migration](httpoison-req-migration.md)); could make feed updates time out and retire live podcasts.

**How to apply:** don't remove the http1 setting without re-testing a large feed over HTTP/2. If podcasts retired between 2026-10-01 and the deploy of bcc91098 look alive, HTTP/2 hangs are a suspect.

2026-10-29: hackney 4.9.1 (1e957ad9) still reads `default_protocols` from the app env (hackney_util:default_protocols/0), so the HTTP/1.1-only setting stays. Retry HTTP/2 only after checking whether 4.9.x fixed the large-body stall.
