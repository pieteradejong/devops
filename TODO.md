# TODO

Open items for this repo. Tick, never delete. Workspace-level items are in `~/dev/TODO.md`.

- [ ] 2026-11-16 Create the private GitHub repo, push, and get CI green (`ci`: security, security-prev, tests) — D76
- [ ] 2026-11-16 Go-public checklist (`docs/policy/security-and-privacy.md` §5), then Pieter decides on the flip to public; run the GitHub sweep `--apply` for this repo after that — D76
- [ ] 2026-11-16 In dotfiles, once branch `daily-report` is merged: turn `security-reusable.yml`, `gitleaks-reusable.yml` and `vercel-live-reusable.yml` into forwarders to this repo, and prove one caller repo green through them — D76 `Verified: NOT YET`
- [ ] 2026-11-16 Repoint this machine to `~/dev/devops`: global git hook commands, `~/.claude/settings.json` hooks, the `securityaudit` LaunchAgent (and the launchd register), the `.zshrc` PATH and `dotaudit` alias, `dev-CLAUDE.md` paths, `codex-agents-sync` — D76 `Verified: NOT YET`
- [ ] 2026-11-16 Prove a clone without the private dir: `DEVOPS_PRIVATE_DIR=/nonexistent SKIPLIST_FILE=scripts/audit/skiplist.example.conf ./test.sh` — D76 `Verified: NOT YET`
- [ ] 2026-11-16 Later, with its own approval: the ~22 project `test.sh` files that call `~/dev/dotfiles/security/gate.sh`, then retire the copies in dotfiles — D76
- [ ] 2026-11-16 `DOTFILES_DIR` is still the name of this repo's root variable in several scripts; rename it to `DEVOPS_DIR` in one pass with the tests — D76
- [ ] 2026-11-16 Split the security parts of dotfiles' `docs/maintenance.md` and `warnings-runbook.md` into this repo, then make the absolute links in `docs/policy/` relative again — D76
- [ ] 2026-11-16 `portfolio.md` and a hero image rendered from fixtures, then list the repo on astropieter (after it is public) — D76
