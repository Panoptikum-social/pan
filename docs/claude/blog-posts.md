Blog posts live in the qed site (see [jekyll-docs-repo](jekyll-docs-repo.md)) as
`pages/blog/YYYY-MM-DD-slug.md` with TOML front matter:

```
+++
title = "..."
date = 2026-10-12
authors = ["Stefan"]
+++
```

(`redirect_from` only for posts migrated from Jekyll.) English. Contact for readers:
mail@panoptikum.social and https://fosstodon.org/@panoptikum.

On 2026-10-12 I wrote "Same title, different podcast" about the #54/#125 title change;
user: "really good, you anticipated my intentions".

**What worked:** written for an intelligent podcaster, not a developer; no code details;
structure: the old rule → problems it caused (with real examples and an honest apology)
→ what changed → "what this means for you" by case → cleanup + ask readers to report issues.
Clearly separate what is live from what is planned.

**How to apply:** same audience and structure for future posts about platform changes.
Flag before publishing anything that is only true after a deploy, and offer to drop
real podcast names if a neutral tone is preferred. Don't commit in the blog repo unless asked.
