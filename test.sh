#!/usr/bin/env bash
#
# test.sh — every test in this repo, in one command. CI runs exactly this.
#
#   ./test.sh                 all suites
#   ./test.sh gate            one suite: toolchain | coverage | scan | shellcheck | ruff |
#                                        gate | tools | dotaudit | logs | docs | templates
#   ./test.sh --verbose       pass --verbose through to each suite
#   ./test.sh --list          print each suite and what it proves; run nothing
#
# Colour only on a terminal; NO_COLOR=1 turns it off, FORCE_COLOR=1 turns it on.
# Every suite runs even after one fails; the summary lists each with its exit code.
#
# Suites:
#   [toolchain]  the tools below are installed, git at 2.54 or newer
#   [coverage]   every tracked shell and Python script is in exactly one lint list, and
#                every scripts/test-* is run by a suite here
#   [scan]       security/gate.sh scan-tree over the working tree
#   [shellcheck] security-relevant shell scripts at default severity, the rest at -S warning
#   [ruff]       ruff check over every Python script
#   gate        scripts/test-security-gate.sh   (the commit/push gate)
#   tools       scripts/test-security-tools.sh  (Claude guard hooks, GitHub sweep, weekly
#                                                audit, dotaudit gate module)
#   dotaudit    scripts/test-dev-audit.sh       (the read-only workspace audit)
#   logs        scripts/test-logs.sh            (decision log and changelog coverage)
#   docs        scripts/test-docs.py            (policy doc links, anchors and index)
#   templates   scripts/test-template-versions.py (template dependency drift, offline)
#
# Requires: git 2.54+, gitleaks, shellcheck, jq, ruff, python3.

set -u
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

VERBOSE=""
LIST=0
ONLY=""
for a in "$@"; do
  case "$a" in
    --verbose) VERBOSE="--verbose" ;;
    --list)    LIST=1 ;;
    toolchain|coverage|scan|shellcheck|ruff|gate|tools|dotaudit|logs|docs|templates) ONLY="$a" ;;
    -h|--help) awk 'NR > 2 && /^#/ { sub(/^# ?/, ""); print; next } NR > 2 { exit }' "$0"; exit 0 ;;
    *) echo "unknown argument: $a" >&2; exit 2 ;;
  esac
done

SHELLCHECK_FILES="
test.sh
security/gate.sh
security/patterns.sh
security/lib/visibility.sh
security/lib/logs.sh
security/lib/loose-files.sh
claude/hooks/guard-git-bypass.sh
claude/hooks/guard-github-write.sh
claude/hooks/session-start.sh
claude/hooks/stop-log-check.sh
claude/hooks/prompt-followup.sh
scripts/dev-audit.sh
scripts/audit/lib.sh
scripts/audit/10-git-hygiene.sh
scripts/audit/20-policy.sh
scripts/audit/30-privacy.sh
scripts/audit/40-disk.sh
scripts/audit/50-gate.sh
scripts/audit/60-launchd.sh
scripts/audit/render-report.sh
scripts/github-security-sweep.sh
scripts/security-audit.sh
scripts/test-security-gate.sh
scripts/test-security-tools.sh
scripts/test-logs.sh
bin/whatsup
bin/doc-dupes
"

# zsh scripts. shellcheck has no zsh support, so these get `zsh -n` instead of a
# lint pass. Keep the two lists disjoint: a file belongs to exactly one.
ZSH_FILES="
"

# Older or less security-relevant shell scripts: shellcheck at -S warning, the floor
# repo-standards.md sets. Style notes (SC2015 `A && B || C` in test assertions) are
# allowed here. A file belongs to exactly one shellcheck list.
SHELLCHECK_WARN_FILES="
bin/vercel-project
scripts/test-dev-audit.sh
"

# Tracked scripts deliberately in no lint list. Reason after the path.
LINT_EXEMPT="
"

# Test scripts that ./test.sh does not run, with the command that does. Not hermetic:
# they read this Mac's live state.
MANUAL_TESTS="
"

REQUIRED_TOOLS="git gitleaks shellcheck jq ruff python3"
GIT_MIN="2.54"

# Python scripts (stdlib only, per scripts/README.md), linted with ruff.
# bin/pwd-gen has no extension; ruff lints a file it is given by name.
PYTHON_FILES="
scripts/audit-dashboard.py
scripts/test-docs.py
scripts/template-versions.py
scripts/test-template-versions.py
"

# Colour: on for a terminal, off when piped. NO_COLOR turns it off, FORCE_COLOR turns it on
# (https://no-color.org); GitHub Actions renders ANSI without being a terminal.
if [ -n "${NO_COLOR:-}" ]; then COLOR=0
elif [ "${FORCE_COLOR:-0}" != 0 ] || [ "${GITHUB_ACTIONS:-}" = true ]; then COLOR=1
elif [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]; then COLOR=1
else COLOR=0; fi
if [ "$COLOR" -eq 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
  CYAN=$'\033[36m'; RESET=$'\033[0m'
else
  BOLD=''; DIM=''; RED=''; GREEN=''; CYAN=''; RESET=''
fi

# What each suite proves, in one line: shown as the suite starts and by --list.
suite_what() {
  case "$1" in
    toolchain)  echo "the required tools are installed, git at $GIT_MIN or newer" ;;
    coverage)   echo "every script is in exactly one lint list; every scripts/test-* runs in a suite" ;;
    scan)       echo "the gate finds no secret, personal value or forbidden file in the tree" ;;
    shellcheck) echo "shellcheck is clean: security scripts at default severity, the rest at -S warning" ;;
    zsh-syntax) echo "zsh -n parses the zsh scripts and the shell/ rc files" ;;
    ruff)       echo "ruff check is clean over every Python script" ;;
    bin)        echo "bin/llm routing and zero-cloud guards; the weekly cleanup, asserted statically" ;;
    gate)       echo "the commit/push gate blocks what it must and passes what is clean" ;;
    tools)      echo "the Claude guard hook, the GitHub sweep, the weekly audit, the dotaudit gate module" ;;
    dotaudit)   echo "the read-only workspace audit reports what its fixtures hold" ;;
    containers) echo "the Colima doctor (no Docker Desktop)" ;;
    maint)      echo "the maintenance report and cache quarantine, on a fake HOME" ;;
    pwdgen)     echo "bin/pwd-gen: lengths, classes, wordlist, exit codes" ;;
    logs)       echo "decision log and changelog coverage: whatsup, the hooks, the gate's log rules" ;;
    docs)       echo "policy doc links, anchors and index; workspace CLAUDE.md in sync; mermaid diagrams" ;;
    claudemd)   echo "the CLAUDE.md fact check, against stub tools" ;;
    templates)  echo "template dependency drift, against fixture registries (offline)" ;;
    models)     echo "newer local models against the llm lineup, from fixture pages (offline)" ;;
    daily)      echo "the daily report over a fake HOME and ~/dev: jobs, repos, TODO diff, privacy (offline)" ;;
    app)        echo "the local web app on a loopback port: token, Host check, paths, escaping, CSP" ;;
    entry)      echo "init.sh and run.sh: help, usage errors, --check never installs" ;;
    restore)    echo "a clean restore in a debian container ends in the expected state" ;;
    *)          echo "(no description: add one to suite_what)" ;;
  esac
}

RESULTS=""
FAILED=0
T0=$(date +%s)
run_suite() { # <name> <command...>: says what the suite proves, runs it with its output streaming
  local name="$1" rc start took; shift
  [ -z "$ONLY" ] || [ "$ONLY" = "$name" ] || return 0
  if [ "$LIST" = 1 ]; then printf '%s%-11s%s %s\n' "$BOLD" "$name" "$RESET" "$(suite_what "$name")"; return 0; fi
  printf '\n%s════ %s ════%s  %s\n' "$BOLD$CYAN" "$name" "$RESET" "$(suite_what "$name")"
  start=$(date +%s)
  "$@"; rc=$?
  took=$(( $(date +%s) - start ))
  if [ "$rc" = 0 ]; then
    RESULTS="$RESULTS\n  ${GREEN}✓${RESET} $(printf '%-11s' "$name") ${DIM}${took}s${RESET}"
  else
    RESULTS="$RESULTS\n  ${BOLD}${RED}✗ $(printf '%-11s' "$name")${RESET} ${DIM}${took}s${RESET}  exit $rc  ${DIM}rerun: ./test.sh $name${RESET}"
    FAILED=1
  fi
}

# version_ge <have> <want> — dotted versions, numeric per field.
# shellcheck disable=SC2329 # called from toolchain_check
version_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -n 1)" = "$2" ]
}

# shellcheck disable=SC2329 # invoked through run_suite
toolchain_check() {
  local t rc=0 v
  for t in $REQUIRED_TOOLS; do
    if command -v "$t" >/dev/null 2>&1; then echo "  ok    $t"; else echo "  MISSING $t — run ./init.sh"; rc=1; fi
  done
  if command -v git >/dev/null 2>&1; then
    v="$(git --version | awk '{ print $3 }')"
    if version_ge "$v" "$GIT_MIN"; then echo "  ok    git $v (>= $GIT_MIN)"; else echo "  OLD   git $v, need $GIT_MIN+ (brew upgrade git)"; rc=1; fi
  fi
  command -v pre-commit >/dev/null 2>&1 && echo "  ok    pre-commit (optional)" || echo "  skip  pre-commit (optional, not installed)"
  return "$rc"
}

# list_paths <list> — the first field of each non-empty line.
# shellcheck disable=SC2329 # called from coverage_check
list_paths() { printf '%s\n' "$1" | awk 'NF { print $1 }'; }

# script_kind <file> — sh | zsh | py | "" from the extension, then the shebang.
# shellcheck disable=SC2329 # called from coverage_check
script_kind() {
  local f="$1" first kind=""
  case "$f" in *.sh) kind="sh" ;; *.py) kind="py" ;; esac
  first="$(head -n 1 "$f" 2>/dev/null)"
  case "$first" in
    '#!'*python*) kind="py" ;;
    '#!'*zsh*) kind="zsh" ;;
    '#!'*bash*|'#!/bin/sh'*|'#!/usr/bin/env sh'*) kind="sh" ;;
  esac
  printf '%s' "$kind"
}

# shellcheck disable=SC2329 # invoked through run_suite
coverage_check() {
  local f kind n rc=0 lists all_sc exempt manual
  all_sc="$(list_paths "$SHELLCHECK_FILES"; list_paths "$SHELLCHECK_WARN_FILES")"
  exempt="$(list_paths "$LINT_EXEMPT")"
  manual="$(list_paths "$MANUAL_TESTS")"
  # A file in two lists would be linted twice, at two severities.
  for f in $(printf '%s\n' "$all_sc" "$(list_paths "$ZSH_FILES")" "$(list_paths "$PYTHON_FILES")" "$exempt" | sort | uniq -d); do
    echo "  in two lists: $f"; rc=1
  done
  # Every listed file must exist (a rename leaves a dead entry behind).
  for f in $all_sc $(list_paths "$ZSH_FILES") $(list_paths "$PYTHON_FILES") $exempt $manual; do
    [ -f "$f" ] || { echo "  listed but missing: $f"; rc=1; }
  done
  n=0
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    printf '%s\n' "$exempt" | grep -qxF "$f" && continue
    kind="$(script_kind "$f")"
    case "$kind" in
      sh)  lists="$all_sc" ;;
      zsh) lists="$(list_paths "$ZSH_FILES")" ;;
      py)  lists="$(list_paths "$PYTHON_FILES")" ;;
      *)   continue ;;
    esac
    n=$((n + 1))
    printf '%s\n' "$lists" | grep -qxF "$f" || { echo "  not linted ($kind): $f — add it to the $kind list in test.sh, or to LINT_EXEMPT with a reason"; rc=1; }
  done <<EOF
$(git ls-files 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)
EOF
  # Every test script runs somewhere.
  for f in scripts/test-*; do
    [ -f "$f" ] || continue
    grep -q "run_suite [a-z-]* *[a-z0-9]* *$f" "$0" && continue
    printf '%s\n' "$manual" | grep -qxF "$f" && continue
    echo "  test never run: $f — add a run_suite line, or list it in MANUAL_TESTS"; rc=1
  done
  [ "$rc" = 0 ] && echo "coverage: every one of $n scripts is linted, every test script runs"
  return "$rc"
}

# shellcheck disable=SC2329 # invoked through run_suite
scan_tree() {
  [ -x security/gate.sh ] || { echo "security/gate.sh missing"; return 1; }
  security/gate.sh scan-tree && echo "scan: working tree clean (gate scan-tree)"
}

# shellcheck disable=SC2329 # invoked through run_suite
shellcheck_all() {
  command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck is not installed"; return 1; }
  local rc=0
  # shellcheck disable=SC2086 # the lists are deliberately word-split
  shellcheck -x $SHELLCHECK_FILES || rc=1
  # shellcheck disable=SC2086
  shellcheck -x -S warning $SHELLCHECK_WARN_FILES || rc=1
  # shellcheck disable=SC2086
  [ "$rc" = 0 ] && echo "shellcheck: clean ($(echo $SHELLCHECK_FILES | wc -w | tr -d ' ') files at default severity, $(echo $SHELLCHECK_WARN_FILES | wc -w | tr -d ' ') at -S warning)"
  return "$rc"
}

# shellcheck disable=SC2329 # invoked through run_suite
zsh_syntax_all() {
  command -v zsh >/dev/null 2>&1 || { echo "zsh is not installed"; return 1; }
  local f rc=0
  for f in $ZSH_FILES; do
    zsh -n "$f" || { echo "zsh -n failed: $f"; rc=1; }
  done
  [ "$rc" = 0 ] && echo "zsh -n: clean ($(echo "$ZSH_FILES" | wc -w | tr -d ' ') files)"
  return "$rc"
}

# shellcheck disable=SC2329 # invoked through run_suite
ruff_all() {
  command -v ruff >/dev/null 2>&1 || { echo "ruff is not installed"; return 1; }
  # shellcheck disable=SC2086 # the list is deliberately word-split
  ruff check $PYTHON_FILES && echo "ruff: clean ($(echo $PYTHON_FILES | wc -w | tr -d ' ') files)"
}

run_suite toolchain toolchain_check
run_suite coverage coverage_check
run_suite scan     scan_tree
run_suite shellcheck shellcheck_all
run_suite ruff     ruff_all
run_suite gate     bash scripts/test-security-gate.sh $VERBOSE
run_suite tools    bash scripts/test-security-tools.sh $VERBOSE
run_suite dotaudit bash scripts/test-dev-audit.sh $VERBOSE
run_suite logs     bash scripts/test-logs.sh $VERBOSE
run_suite docs     python3 scripts/test-docs.py $VERBOSE
run_suite templates python3 scripts/test-template-versions.py $VERBOSE
[ "$LIST" = 0 ] || exit 0

printf '\n%s════ test.sh summary ════%s%b\n' "$BOLD" "$RESET" "$RESULTS"
if [ "$FAILED" = 0 ]; then
  printf '\n%sAll suites passed%s  %sin %ss%s\n' "$BOLD$GREEN" "$RESET" "$DIM" "$(( $(date +%s) - T0 ))" "$RESET"
else
  printf '\n%sSome suites failed%s  %sin %ss%s\n' "$BOLD$RED" "$RESET" "$DIM" "$(( $(date +%s) - T0 ))" "$RESET"
fi
exit "$FAILED"
