# devops

The security and hygiene tooling that guards one person's whole development workspace: a
commit/push gate that runs in every repo, a reusable CI workflow every repo calls, a weekly security
and privacy audit, a read-only audit of every local repo, a GitHub settings sweep, and the policy
docs they enforce. It runs on macOS with bash 3.2, `git` 2.54+, `gitleaks`, `gh` and `jq`.

It was split out of [dotfiles](https://github.com/pieteradejong/dotfiles) on 2026-11-16
([D76](docs/DECISIONS.md)). dotfiles keeps the machine setup; this repo keeps what governs every
repo under `~/dev`.

## Take what you need

Each part stands on its own, and the repo is MIT-licensed.

| Take | What it is | Needs |
|---|---|---|
| `security/gate.sh` | The commit/push gate: blocks secrets, personal values, forbidden files, large binaries and missing CI before they leave the machine. Installed as global git hooks (`pre-commit`, `pre-push`), also `scan-tree`, `ci` and `status` modes | git, gitleaks, gh |
| `security/patterns.sh` | The one list of what must never be published, shared by the gate and the audits | — |
| `.github/workflows/security-reusable.yml` | The CI every repo calls: full-history gitleaks plus the gate in `ci` mode over what was pushed | GitHub Actions |
| `scripts/security-audit.sh` | The weekly audit: gate intact, every repo scanned, GitHub settings, uncloned repos, bypasses, loose credential files, account keys, template and model drift. Opens with what changed since last week | gh, gitleaks, jq |
| `scripts/dev-audit.sh` (`dotaudit`) | A read-only audit of every repo under `~/dev`: git hygiene, repo policy, privacy, disk, gate, launchd register ([docs/dev-audit.md](docs/dev-audit.md)) | git |
| `scripts/github-security-sweep.sh` | Secret scanning, push protection and Dependabot alerts on every owned repo; dry run by default | gh |
| `scripts/audit-dashboard.py` | A local HTML dashboard over the audit output | python3 |
| `bin/whatsup` | What is up in the repo you are in: git state, decision log, changelog, TODO | git |
| `bin/doc-dupes` | Duplicate and near-duplicate entries in a repo's TODO, decision log and changelog | — |
| `bin/vercel-project` | One Vercel project per repo, with deployment checks ([docs/deploy-pipeline.md](docs/deploy-pipeline.md)) | vercel |
| `claude/hooks/*` | Claude Code hooks: the assistant cannot switch the gate off or write past it through the GitHub API, and each session opens and closes with the repo's logs | Claude Code, jq |
| [`docs/policy/`](docs/policy/) | The rules themselves: security and privacy, secure development, privacy by design, supply chain, AI and external services, repo standards, AI instructions, backups | — |

## Private configuration

The tools read a few private files: exact personal values to block, the real skip list of
do-not-touch repos, and registers. None of them is in this repo. They live in a separate private
repo, found at `$DEVOPS_PRIVATE_DIR`. That defaults to `./private/` beside this repo when it
exists, and otherwise to `~/dev/dotfiles/private`.

| Variable | Default | What it points to |
|---|---|---|
| `DEVOPS_PRIVATE_DIR` | `./private`, else `~/dev/dotfiles/private` | the private companion repo |
| `SKIPLIST_FILE` | `$DEVOPS_PRIVATE_DIR/audit/skiplist.conf` | repos the audits must never touch. Format: [`scripts/audit/skiplist.example.conf`](scripts/audit/skiplist.example.conf). The audit **fails closed** without it |
| `DEVOPS_GITHUB_OWNER` | `pieteradejong` | the owner whose repos the standards bind |
| `DEVOPS_LICENSE_HOLDER` | `Pieter de Jong` | the canonical LICENSE holder line |

To use it yourself, set the two `DEVOPS_*` names and point `SKIPLIST_FILE` at your own copy of the
example.

## Commands

```bash
./test.sh                                  # every suite; CI runs exactly this
./test.sh gate                             # one suite (./test.sh --list shows them)
security/gate.sh status                    # is the gate installed and intact?
scripts/security-audit.sh --quick          # the weekly audit without the slow steps
scripts/dev-audit.sh                       # dotaudit, writes to ~/dev/audit-reports/
scripts/github-security-sweep.sh --check   # GitHub settings, read-only
```

Install the gate as global hooks (git 2.54+ config-based hooks):

```bash
git config --global hook.security-gate-commit.event pre-commit
git config --global hook.security-gate-commit.command "$PWD/security/gate.sh pre-commit"
git config --global hook.security-gate-push.event pre-push
git config --global hook.security-gate-push.command "$PWD/security/gate.sh pre-push"
```

Call the reusable CI from a repo's `.github/workflows/security.yml`:

```yaml
jobs:
  security:
    uses: pieteradejong/devops/.github/workflows/security-reusable.yml@main
```

## What it never does

- **Writes to the repos it audits.** The audits are read-only toward every repo. They write only
  their reports to `~/dev/audit-reports/`, which is never inside a git repo, plus a dashboard and a
  mirror cache.
- **Bypasses quietly.** A finding is fixed, or the commit stops. The one escape hatch
  (`SECURITY_GATE_BYPASS`) is logged, and the weekly audit reports every use. The Claude Code hooks
  stop the assistant from using it, or from skipping hooks with `--no-verify`.
- **Publishes private data.** Reports, the private companion repo and the bypass log never enter
  git. The `.gitignore`, the gate and CI each refuse them independently.

## Layout

```
security/          gate.sh, patterns.sh, gitleaks.toml, lib/ (visibility, logs, loose files)
scripts/           security-audit.sh, dev-audit.sh + audit/, github-security-sweep.sh,
                   audit-dashboard.py, template-versions.py, test-*.sh / test-*.py
bin/               whatsup, doc-dupes, vercel-project
claude/hooks/      guard-git-bypass, guard-github-write, session-start, stop-log-check, prompt-followup
.github/workflows/ security-reusable.yml, gitleaks-reusable.yml, vercel-live-reusable.yml, ci.yml
docs/              policy/, dev-audit.md, deploy-pipeline.md, DECISIONS.md
macos/             com.pieterdejong.securityaudit.plist (the weekly audit's LaunchAgent)
```

Earlier design decisions (D1–D75) are in
[dotfiles' decision log](https://github.com/pieteradejong/dotfiles/blob/main/docs/design-decisions.md);
new ones go in [docs/DECISIONS.md](docs/DECISIONS.md).
