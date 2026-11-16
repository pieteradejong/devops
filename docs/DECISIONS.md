# Design decisions

Appended, never rewritten; a later entry supersedes an earlier one by number. Numbering continues
from [dotfiles' log](https://github.com/pieteradejong/dotfiles/blob/main/docs/design-decisions.md),
which holds D1–D75.

---

## D76 — Split the workspace tooling out of dotfiles into `devops` · 2026-11-16

**Problem.** dotfiles has two goals, restoring this machine and offering files others can copy, and
a scope test for anything new: *does it help restore this machine, or would someone copy it?* Since
2026-09-30 its README has said the workspace security tooling fails that test and "is moving to its
own repo". The gate, the audits, the GitHub sweep, the reusable CI and the policy docs govern every
repo under `~/dev`, not this machine's setup. Nothing recorded how the move would be done.

**Decision.** A new public repo, `pieteradejong/devops`, extracted from dotfiles with
`git filter-repo`. That keeps the history of the moved paths (and of `LICENSE`, so the first commit
carries it) and keeps the relative layout (`security/`, `scripts/`, `bin/`, `claude/hooks/`), so the
`$SCRIPT_DIR/..` lookups resolve unchanged. Four further rules:

- **Private files stay private.** The private companion repo stays where it is. One variable,
  `DEVOPS_PRIVATE_DIR`, finds it: `./private/` beside this repo when present, otherwise
  `~/dev/dotfiles/private`. The skip list still fails closed.
- **Personal values become settable.** The owner and the licence holder are overridable
  (`DEVOPS_GITHUB_OWNER`, `DEVOPS_LICENSE_HOLDER`). Their defaults are the real values, which are
  public already.
- **No caller changes.** About 116 workflow callers use
  `pieteradejong/dotfiles/.github/workflows/security-reusable.yml@main`. They keep working: dotfiles'
  three reusable workflows become thin forwarders that call the copies here (reusable workflows may
  nest). The local machine (git hooks, LaunchAgent, Claude hooks, PATH) is repointed in waves, each
  one verified. dotfiles' copies retire only after every caller has moved.
- **What stays in dotfiles.** Checks of files that stay there (settings.json registration, the
  CLAUDE.md copies, the sync-dotfiles sanitizers) stay in dotfiles with those files. So do the
  personal maintenance tools: daily report, maintenance status, model lineup and CLAUDE.md fact
  check.

**Rejected.**
- *A `dotfiles/devops/` folder.* Reusable workflows must sit in `.github/workflows/` at a repo's
  root, and every hook and LaunchAgent path would change for no gain. It also contradicts the scope
  test.
- *A copy, with dotfiles unchanged.* Two live copies of the gate drift apart, and a security tool
  that exists in two versions gets fixed in one.
- *A docs-only showcase repo.* It would not do what the README promised: the code would still fail
  dotfiles' scope test.
- *Repointing all ~116 callers in one sweep.* It touches do-not-touch repos, forks and other owners'
  repos (one caller is owned by another organisation), and the forwarder makes it unnecessary.

**Cost.**
- Two repos to keep in step until the copies in dotfiles retire.
- Links from the policy docs to dotfiles' decision log and maintenance doc are absolute URLs until
  those docs are split too.
- During the transition a gate fix has to land here. dotfiles' copy only matters for callers not
  yet repointed.

**Verified:** NOT YET:
- the forwarder run in one caller repo
- local repointing (`git config --global --get-regexp '^hook\.'`, the LaunchAgent path)
- a clone with no private dir (`DEVOPS_PRIVATE_DIR=/nonexistent ./test.sh`)

Done: `./test.sh` passes in this repo before its first push (see `docs/SESSIONS.md`).
