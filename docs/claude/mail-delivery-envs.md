Verified 2026-09-21 in config/runtime.exs: only prod uses Swoosh.Adapters.SMTP (relay box.mittenin.at, password from PAN_MAILER_PASSWORD). Dev and qa use Swoosh.Adapters.Local (nothing leaves the machine). Test uses Swoosh.Adapters.Test (added 2026-09-21). Dev has a Swoosh mailbox preview at /dev/mailbox (route only compiled when Mix.env() == :dev) with a dev-only "Dev Mailbox" button on the admin dashboard.

The app only talks to our relay (Mail-in-a-Box/Postfix), so a nonexistent address is not seen immediately: failures come back as bounce mails to the envelope sender. All Pan.Mailer.deliver() call sites ignore the return value.

Bounce exploration 2026-09-21 (user is happy exploring, nothing built): alias bounces@panoptikum.social -> bounce@ mailbox with robot@informatom.com as permitted sender now exists (needed, otherwise 553 5.7.1 "not owned by user"). Swoosh SMTP uses the Sender header as envelope sender. Tested with swaks: bounces arrive in ~3 s as standard delivery reports (5.1.1 nonexistent mailbox, 5.4.4 nonexistent domain, bounced at once) with the full original attached. Step 1 built 2026-09-21 (Pan.Mailer.deliver/2: Sender header bounces@, receipt logged, relay refusals Journaled; user watches real bounces before any reader is built). The backlog item with the details was removed 2026-09-26 (see git history of backlog.md before 894e0781). A bounce contains the original mail, so login/verification links: treat bounce@ as sensitive.

**Why:** needed to reason about verification mails, greylisting (token lifetime was raised to 1 h for it) and retention warning mails.

**How to apply:** To test mail flows in dev, use /dev/mailbox; qa needs the adapter switched to SMTP to send real mail. See [retention-notice-job](retention-notice-job.md).

Update 2026-09-21: the Sender: bounces@ header is deployed to prod, so real bounces now arrive in bounce@.

Update 2026-09-21 (later): user confirmed real bounces arrive in bounce@ after the deploy. A reader was undecided at that time (decided against 2026-09-26, see below).

**Update 2026-09-21 (evening):** the first 7 real bounces arrived in `bounce@`; the user judged all causes unfixable on our side, decided no action, and monitors the box manually for the next days. No reader or auto-action built; revisit only if the user raises it.

**Decided 2026-09-26:** no mailbox reader will be built — the user handles `bounce@` manually. The "Bounce handling" backlog item was removed (commit 894e0781, pushed). Bounce mails still contain login tokens (1 h, 30 days for retention notices), so `bounce@` stays sensitive.
