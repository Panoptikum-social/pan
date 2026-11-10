On 2026-10-18 I told the user to push the check-my-feed commits and then amended the last one (package description). The user had already pushed the original → local and origin diverged ("voraus 1, hinterher 1"). Fixed without force push via `git reset --soft origin/main` + a new commit.

**Why:** the user pushes as soon as I hand over; amending afterwards creates a divergence that needs cleanup and could tempt a force push.

**How to apply:** once a commit is announced as ready to push (or `git status -sb` shows it on the remote), only add new commits. Amend only commits that are clearly local and not yet handed over; check `git status -sb` before amending.
