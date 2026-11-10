The QA Docker stack (DOCKER.md, docker-compose.yml) runs on the user's home server, reached as port 4001 of the home server (by its LAN name or IP). The user pulls `main` there and runs `docker compose build && docker compose up -d`; `.env` should have `PAN_HOST=<the home server's LAN name>`.

**Why:** prod (panoptikum.social) sends HSTS with includeSubdomains, so browsers force `qa.panoptikum.social:4001` to https, which QA doesn't serve (found 2026-10-19). QA's endpoint uses `check_origin: :conn` (debf88a7) so name and IP both work for websockets.

**How to apply:** for QA tests, tell the user to open the home server on port 4001; a "Could not check origin" log means an old image (rebuild). The QA image is on Elixir 1.20.4 / OTP 29.1.1 like prod since d1111a92 — keep the Dockerfile tags in step with prod upgrades ([otp29-upgrade](otp29-upgrade.md)). The image can be built locally too (`docker build -t pan-qa-trial .`) to check a build before the user pulls.
