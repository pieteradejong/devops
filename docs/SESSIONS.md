# Sessions

Newest first.

## 2026-11-16 — repo created from dotfiles

- Extracted the workspace tooling from dotfiles `origin/main` (`c5f2473`) with `git filter-repo`.
  The extraction keeps the moved paths' history and LICENSE, so the first commit carries it.
- Routed every private-file lookup through `DEVOPS_PRIVATE_DIR`. Pointed the reusable workflows at
  this repo. Made the owner and licence holder overridable.
- Trimmed the copied tests of checks for files that stay in dotfiles. Pointed policy-doc links to
  dotfiles-only docs at absolute URLs.
- Added README, CHANGELOG, TODO, DECISIONS (D76), this log, `ci.yml` and `.gitignore`.
- Unverified (D76 `Verified: NOT YET`), tracked in `TODO.md`:
  - the dotfiles forwarder
  - local repointing
  - a clone without the private dir
