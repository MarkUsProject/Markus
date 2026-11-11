#!/bin/bash
# Cherry-pick automation for MarkUs releases.
#
# Usage:
#   release/cherry-pick.sh v2.9.6            Run recon and cherry-pick all PRs
#   release/cherry-pick.sh v2.9.6 --resume   Verify already-picked PRs, continue
#   release/cherry-pick.sh v2.9.6 --skip 8101 --accept 8120
#   release/cherry-pick.sh --help
#
# Every pick, and every already-picked PR on --resume, runs
# `release/verify.rb <PR> <sha>`. --skip leaves a PR out; --accept keeps a
# reviewed pick that differs from its PR diff. Both take comma lists, repeat,
# and imply --resume.
# Stops on code conflicts, failed commits or contamination.
# Outputs the comma-separated PR list at the end for use with changelog.rb.

set -euo pipefail

HELPERS="$(cd "$(dirname "$0")" && pwd)"

VERSION=""
RESUME=false
SKIP_LIST=","
ACCEPT_LIST=","
USAGE="Usage: release/cherry-pick.sh <version> [--resume] [--skip <PR,...>] [--accept <PR,...>]"

# Guard for `--skip`/`--accept <PR,...>`: stop unless a PR list follows.
pr_list_arg() {
  [[ "${2:-}" =~ ^[0-9]+(,[0-9]+)*$ ]] || { echo "$1 needs PR numbers, e.g. $1 8101,8120"; exit 1; }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resume) RESUME=true ;;
    --skip)   pr_list_arg "$@"; SKIP_LIST+="$2,"; RESUME=true; shift ;;
    --accept) pr_list_arg "$@"; ACCEPT_LIST+="$2,"; RESUME=true; shift ;;
    --help|-h)
      echo "$USAGE"
      echo ""
      echo "Cherry-picks all milestone PRs onto the current branch and verifies each."
      echo "Stops on code conflicts, failed commits or contamination."
      echo "Re-run with --resume after fixing; --resume re-verifies picked PRs."
      echo "  --skip <PR,...>    leave these PRs out (not picked, not in the PR list)"
      echo "  --accept <PR,...>  keep these picks although verify.rb reports a difference"
      echo "  --skip and --accept imply --resume."
      exit 0
      ;;
    v[0-9]*) VERSION="$1" ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
  shift
done

if [[ -z "$VERSION" ]]; then
  echo "$USAGE"
  exit 1
fi

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}>>>${RESET} $1"; }
success() { echo -e "${GREEN}  OK${RESET}  $1"; }
warn()    { echo -e "${YELLOW}WARN${RESET}  $1"; }
fail()    { echo -e "${RED}FAIL${RESET}  $1"; }

stop() {
  [[ -n "$PICKED" ]] && echo "  PRs picked so far: $PICKED"
  exit 1
}

in_list() { [[ "$2" == *",$1,"* ]]; }

# Commit on this branch (not on origin/release) whose subject cites (#$1), if any.
picked_commit() {
  git log --format='%H %s' HEAD --not origin/release | awk -v ref="(#$1)" '!found && index($0, ref) { print $1; found = 1 }'
}

pick_in_progress() { git rev-parse -q --verify CHERRY_PICK_HEAD >/dev/null; }

# A cherry-pick stopped with nothing to commit: the PR is already on release.
# Rests on git state only (never on git's message, which quotes the PR title).
empty_pick() { pick_in_progress && git diff --cached --quiet; }

# Verify the pick of $PR at commit $1 against merge sha $SHA; stop on FAIL
# unless the PR was accepted with --accept.
verify_pick() {
  local out
  if out=$(ruby "$HELPERS/verify.rb" "$PR" "$SHA" "$1" 2>&1); then
    echo "$out" | grep '^WARN' | sed 's/^/    /' || true
    success "#$PR verified clean"
    return
  fi
  echo "$out" | sed 's/^/    /'
  if in_list "$PR" "$ACCEPT_LIST"; then
    warn "#$PR differs from its PR diff, accepted with --accept"
    return
  fi
  echo ""
  warn "Contamination detected in #$PR"
  echo ""
  echo "  To undo and skip: git reset --hard HEAD~1"
  echo "                    release/cherry-pick.sh $VERSION --resume --skip $PR"
  echo "  To accept after review: release/cherry-pick.sh $VERSION --resume --accept $PR"
  echo ""
  stop
}

# Abort the in-progress cherry-pick and record the current $PR as skipped.
# Caller must `continue` the loop afterwards.
skip_pr() {
  git cherry-pick --skip 2>/dev/null
  success "#$PR already on release, skipped"
  SKIPPED="${SKIPPED:+$SKIPPED,}$PR"
}

# Show hook diff and stop for user review
stop_for_hook_review() {
  local hook_diff="$1"
  local diff_lines
  diff_lines=$(echo "$hook_diff" | wc -l | tr -d ' ')
  echo ""
  warn "Pre-commit hook modified files in #$PR ($diff_lines lines):"
  echo "$hook_diff" | head -40 | sed 's/^/    /'
  if [[ "$diff_lines" -gt 40 ]]; then
    echo "    ... ($((diff_lines - 40)) more lines, run: git diff)"
  fi
  echo ""
  echo "  If the above is only formatting, accept and continue."
  echo ""
  echo "  To accept: git add -u && git cherry-pick --continue"
  echo "             release/cherry-pick.sh $VERSION --resume --accept $PR"
  echo "  To reject: git checkout -- . && git cherry-pick --abort"
  echo "             release/cherry-pick.sh $VERSION --resume --skip $PR"
  echo ""
  stop
}

if pick_in_progress; then
  fail "A cherry-pick is in progress. Finish it (git cherry-pick --continue) or abort it first."
  exit 1
fi

# --- Recon ---

info "Running recon for $VERSION..."
RECON_JSON=$(ruby "$HELPERS/recon.rb" "$VERSION")
ORDER=$(echo "$RECON_JSON" | ruby "$HELPERS/recon-format.rb" --order)

if [[ -z "$ORDER" ]]; then
  warn "No PRs to cherry-pick for $VERSION (recon returned none). Check the milestone name."
  exit 0
fi
TOTAL=$(echo "$ORDER" | wc -l | tr -d ' ')

echo -e "\n${BOLD}Cherry-pick plan ($TOTAL PRs):${RESET}"
echo "$RECON_JSON" | ruby "$HELPERS/recon-format.rb" --plan
echo ""

# --- Cherry-pick loop ---

PICKED=""
SKIPPED=""
NUM=0

while IFS= read -r entry; do
  PR="${entry%%:*}"
  SHA="${entry##*:}"
  NUM=$((NUM + 1))

  if in_list "$PR" "$SKIP_LIST"; then
    success "[$NUM/$TOTAL] #$PR skipped with --skip"
    SKIPPED="${SKIPPED:+$SKIPPED,}$PR"
    continue
  fi

  # Resume: a commit for this PR is already on the branch (possibly finished
  # by hand), so verify it instead of picking again.
  if $RESUME && PICK_COMMIT=$(picked_commit "$PR") && [[ -n "$PICK_COMMIT" ]]; then
    info "[$NUM/$TOTAL] #$PR already picked (${PICK_COMMIT:0:10}), verifying"
    verify_pick "$PICK_COMMIT"
    PICKED="${PICKED:+$PICKED,}$PR"
    continue
  fi

  info "[$NUM/$TOTAL] Cherry-picking #$PR (${SHA:0:10})..."

  CHERRY_OUT=$(git cherry-pick -m1 "$SHA" 2>&1) || {
    CONFLICTED_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)

    if [[ -z "$CONFLICTED_FILES" ]]; then
      # Nothing to commit: PR already on release via a different path
      empty_pick && { skip_pr; continue; }

      # Something else went wrong: bad SHA, dirty tree, or another git error
      echo ""
      fail "Cherry-pick of #$PR (${SHA:0:10}) failed without a conflict:"
      echo "$CHERRY_OUT" | sed 's/^/    /'
      echo ""
      echo "  Fix the cause, then: release/cherry-pick.sh $VERSION --resume"
      echo "  To skip this PR:     release/cherry-pick.sh $VERSION --resume --skip $PR"
      echo ""
      stop
    fi

    # Check if all conflicts are auto-resolvable (Changelog.md + lockfiles)
    HAS_CODE_CONFLICT=false
    while IFS= read -r f; do
      case "$f" in
        Changelog.md|Gemfile.lock|package.json|package-lock.json) ;;
        *) HAS_CODE_CONFLICT=true; break ;;
      esac
    done <<< "$CONFLICTED_FILES"

    if $HAS_CODE_CONFLICT; then
      echo ""
      fail "Code conflict in #$PR"
      echo "$CONFLICTED_FILES" | sed 's/^/    /'
      echo ""
      echo "  To fix:"
      echo "    1. Compare: gh pr diff $PR"
      echo "    2. Resolve conflicts, then: git add <files> && git cherry-pick --continue"
      echo "    3. Re-run: release/cherry-pick.sh $VERSION --resume"
      echo ""
      echo "  To skip this PR:"
      echo "    git cherry-pick --abort"
      echo "    release/cherry-pick.sh $VERSION --resume --skip $PR"
      echo ""
      stop
    fi

    # Auto-resolve: Changelog with ours (rebuilt later); lockfiles keep the
    # higher version per key via lockres.rb (release can be ahead of a PR's
    # base). lockres.rb refuses non-trivial blocks, which stops the run.
    while IFS= read -r f; do
      case "$f" in
        Changelog.md)  git checkout --ours "$f" && git add "$f" ;;
        Gemfile.lock|package.json|package-lock.json)
          ruby "$HELPERS/lockres.rb" "$f" || {
            fail "Lockfile conflict in #$PR needs manual resolution: $f"
            echo "  Resolve against: gh pr diff $PR"
            echo "  Then: git add $f && git cherry-pick --continue"
            echo "  And:  release/cherry-pick.sh $VERSION --resume"
            stop
          }
          git add "$f" ;;
      esac
    done <<< "$CONFLICTED_FILES"
    if ! CONTINUE_OUT=$(GIT_EDITOR=true git cherry-pick --continue 2>&1); then
      # Commit failed: check if a pre-commit hook modified files
      HOOK_DIFF=$(git diff 2>/dev/null)
      [[ -n "$HOOK_DIFF" ]] && stop_for_hook_review "$HOOK_DIFF"
      # Nothing staged: the commit became empty after resolution (PR already applied)
      empty_pick && { skip_pr; continue; }
      # Staged changes remain: the commit itself failed (e.g. a pre-commit hook)
      echo ""
      fail "Commit of #$PR failed after auto-resolve ($(echo "$CONFLICTED_FILES" | paste -sd, -)):"
      echo "$CONTINUE_OUT" | sed 's/^/    /'
      echo ""
      echo "  Fix the cause, then: GIT_EDITOR=true git cherry-pick --continue"
      echo "                       release/cherry-pick.sh $VERSION --resume"
      echo ""
      stop
    fi
    success "#$PR auto-resolved ($(echo "$CONFLICTED_FILES" | paste -sd, -))"
  }

  verify_pick HEAD
  PICKED="${PICKED:+$PICKED,}$PR"
done <<< "$ORDER"

# --- Summary ---

echo ""
echo -e "${BOLD}Cherry-pick complete${RESET}"
echo "  Picked:  $PICKED"
[[ -n "$SKIPPED" ]] && echo "  Skipped: $SKIPPED"
echo ""
echo "Next steps (<bots> = the dependabot PRs among the picks):"
echo "  ruby $HELPERS/changelog.rb --mode=release --version=$VERSION --prs=$PICKED --bots=<bots> > Changelog.md"
echo "  bash $HELPERS/validate_changelog.sh $VERSION --prs $PICKED --bots <bots>"
