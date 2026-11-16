# Changelog

Notable changes, newest first ([Keep a Changelog](https://keepachangelog.com/en/1.1.0/)). Entries
before this repo existed are in dotfiles' `CHANGELOG.md`.

## [Unreleased]

### Added

- The repo itself: the gate, the reusable CI, the weekly security audit, dotaudit, the GitHub
  sweep, the audit dashboard, template drift, `whatsup`, `doc-dupes`, `vercel-project`, the Claude
  Code hooks and the policy docs, extracted from dotfiles with their history (D76).
- `DEVOPS_PRIVATE_DIR`: where the tools find the private companion repo. It is `./private/` when
  present, else `~/dev/dotfiles/private`. All private lookups go through it, so the private files
  can live anywhere (D76).
- `DEVOPS_GITHUB_OWNER` and `DEVOPS_LICENSE_HOLDER` override the owner and the licence holder that
  the standards bind (D76).

### Changed

- The reusable workflows fetch their policy from `pieteradejong/devops` instead of
  `pieteradejong/dotfiles` (D76).
- The gate's `no-security-ci` message names the devops workflow or the dotfiles forwarder.
- Links from the policy docs to docs that stay in dotfiles (design decisions D1–D75, maintenance,
  llm) are absolute GitHub URLs.

### Removed

- From the copied tests: the checks of files that stay in dotfiles (settings.json hook
  registration and auto-allow list, the CLAUDE.md copies, the sync-dotfiles sanitizers). They keep
  running there.
