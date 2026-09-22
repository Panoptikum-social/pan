---
title: Panoptikum — Project Progress
type: slide
slideOptions:
  transition: slide
---

# Panoptikum
## Project Progress

News for Users, Podcasters & Moderators

---

# News for Users
## Design, performance & discovery

- Complete **visual refresh**: modern Phoenix LiveView components, new Tailwind/DaisyUI look — cleaner pages, better contrast, more readable buttons and forms
- Noticeably **faster page loads** (switched the underlying web server, ~20% faster)
- New: browse podcasts organized into curated **[Communities](/communities)**
- Search can now be **filtered by language**, with a grouped language picker and a remembered preference

---

# News for Users
## New features

- Recommendations/comments now work on **individual chapters**, not just whole episodes or podcasts
- Persona profiles support **markdown descriptions** and a **"rel=me" link** (for verifying Mastodon/fediverse accounts)
- The paid "Pro" plan has been **discontinued** — Panoptikum is now completely free to use
- Added links to the **Podcaster and Listener manuals**, and to the **API docs**, in the site footer

---

# News for Users
## Latest: installable app & account features

- Panoptikum can now be **installed as an app** on your phone or desktop; visited pages work **offline**, and the playing episode's artwork shows in your device's media controls
- New **"Remember me for 30 days"** option on login
- Password login now requires a **verified email**; a new page lets you resend the verification mail
- Long-inactive or unverified accounts now get a **warning mail with a one-click login link** before deletion

---

# News for Podcasters
## Feed handling

- Podcast metadata (title, description, artwork, categories, contributors, etc.) now **refreshes automatically** about once a month
- **`<podcast:person>`** contributors now import correctly; stale roles are cleaned up automatically on re-parse
- Podcast **artwork refreshes** together with the rest of your feed data

---

# News for Podcasters
## Latest: new tools

- New **"Check my feed"** button runs Panoptikum's feed-compliance checker directly on your podcast page
- New: **claim ownership** of your podcast from `/my_podcasts`; admins can assign, reassign or unassign ownership
- The paid "Pro" plan has been **discontinued** — every podcast gets the same treatment, for free

---

# News for Moderators
## Moderation tools

- New **Communities** feature: moderators can add podcasts into a community's feed and curate its categories
- New **audit log (Journal)** tracks moderation/admin actions, with a clear button
- New admin action to **reset runaway update intervals** back down to at most a week
- **Moderation grid rebuilt** on the new component system, with a column for next metadata refresh

---

# News for Moderators
## Latest: retention & ownership admin

- Admin/moderator grids now support **select-all and deleting multiple rows** at once
- New admin page (**`/admin/users/retention`**): filters, search, bulk mark/unmark and delete, and sending deletion-notice mails
- New admin page (**`/admin/podcasts/owners`**) to assign, reassign or unassign podcast ownership

---

# Thank you

Questions?
