#!/bin/bash
# Cherry-pick automation for MarkUs releases.
#
# Usage:
#   release/cherry-pick.sh v2.9.6            Run recon and cherry-pick all PRs
#   release/cherry-pick.sh v2.9.6 --resume   Skip already-picked PRs, continue
#   release/cherry-pick.sh --help
#
# Stops on code conflicts or contamination. Re-run with --resume after fixing.
# Outputs the comma-separated PR list at the end for use with changelog.rb.

set -euo pipefail

HELPERS="$(cd "$(dirname "$0")" && pwd)"

VERSION=""
RESUME=false

for arg in "$@"; do
  case "$arg" in
    --resume) RESUME=true ;;
    --help|-h)
      echo "Usage: release/cherry-pick.sh <version> [--resume]"
      echo ""
      echo "Cherry-picks all milestone PRs onto the current branch."
      echo "Stops on code conflicts or contamination."
      echo "Re-run with --resume after fixing to continue."
      exit 0
      ;;
    v[0-9]*) VERSION="$arg" ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  echo "Usage: release/cherry-pick.sh <version> [--resume]"
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
  echo "             release/cherry-pick.sh $VERSION --resume"
  echo "  To reject: git checkout -- . && git cherry-pick --abort"
  echo "             release/cherry-pick.sh $VERSION --resume"
  echo ""
  stop
}

# --- Recon ---

info "Running recon for $VERSION..."
RECON_JSON=$(ruby "$HELPERS/recon.rb" "$VERSION")
ORDER=$(echo "$RECON_JSON" | ruby "$HELPERS/recon-format.rb" --order)
TOTAL=$(echo "$ORDER" | wc -l | tr -d ' ')

if [[ "$TOTAL" -eq 0 ]]; then
  warn "No PRs to cherry-pick."
  exit 0
fi

echo -e "\n${BOLD}Cherry-pick plan ($TOTAL PRs):${RESET}"
echo "$RECON_JSON" | ruby "$HELPERS/recon-format.rb" --plan
echo ""

# --- Cherry-pick loop ---

PICKED=""
SKIPPED=""
NUM=0
BRANCH_LOG="$(git log --oneline HEAD --not origin/release)"

while IFS= read -r entry; do
  PR="${entry%%:*}"
  SHA="${entry##*:}"
  NUM=$((NUM + 1))

  # Resume: skip if a cherry-picked commit for this PR is already on the branch
  if $RESUME && [[ "$BRANCH_LOG" == *"(#$PR)"* ]]; then
    success "[$NUM/$TOTAL] #$PR — already picked, skipping"
    PICKED="${PICKED:+$PICKED,}$PR"
    continue
  fi

  info "[$NUM/$TOTAL] Cherry-picking #$PR (${SHA:0:10})..."

  CHERRY_OUT=$(git cherry-pick -m1 "$SHA" 2>&1) || {
    # Empty commit — PR already on release via different path
    if [[ "$CHERRY_OUT" =~ (empty|nothing.*to\ commit) ]]; then
      git cherry-pick --skip 2>/dev/null
      success "#$PR — already on release, skipped"
      SKIPPED="${SKIPPED:+$SKIPPED,}$PR"
      continue
    fi

    CONFLICTED_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)

    # No merge conflicts — likely a pre-commit hook failure on a clean pick
    if [[ -z "$CONFLICTED_FILES" ]]; then
      HOOK_DIFF=$(git diff 2>/dev/null)
      [[ -n "$HOOK_DIFF" ]] && stop_for_hook_review "$HOOK_DIFF"
      # No conflicts, no hook changes — truly empty commit
      git cherry-pick --skip 2>/dev/null
      success "#$PR — already on release, skipped"
      SKIPPED="${SKIPPED:+$SKIPPED,}$PR"
      continue
    fi

    # Check if all conflicts are auto-resolvable (Changelog.md, Gemfile.lock)
    HAS_CODE_CONFLICT=false
    while IFS= read -r f; do
      case "$f" in
        Changelog.md|Gemfile.lock) ;;
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
      echo "    release/cherry-pick.sh $VERSION --resume"
      echo ""
      stop
    fi

    # Auto-resolve: Changelog with ours (rebuilt later), Gemfile.lock by accepting incoming version
    while IFS= read -r f; do
      case "$f" in
        Changelog.md)  git checkout --ours "$f" && git add "$f" ;;
        Gemfile.lock)
          # Resolve conflict markers: drop ours, keep theirs (incoming version)
          awk '/^<<<<<<</{skip=1;next} /^=======/{skip=0;next} /^>>>>>>>/{next} !skip{print}' "$f" > "$f.tmp" \
            && mv "$f.tmp" "$f" && git add "$f" ;;
      esac
    done <<< "$CONFLICTED_FILES"
    if ! GIT_EDITOR=true git cherry-pick --continue 2>/dev/null; then
      # Commit failed — check if a pre-commit hook modified files
      HOOK_DIFF=$(git diff 2>/dev/null)
      [[ -n "$HOOK_DIFF" ]] && stop_for_hook_review "$HOOK_DIFF"
      # No hook changes — commit became empty after resolution (PR already applied)
      git checkout -- . 2>/dev/null
      git cherry-pick --skip 2>/dev/null
      success "#$PR — already on release, skipped"
      SKIPPED="${SKIPPED:+$SKIPPED,}$PR"
      continue
    fi
    success "#$PR — auto-resolved ($(echo "$CONFLICTED_FILES" | paste -sd, -))"
    BRANCH_LOG="$(git log --oneline HEAD --not origin/release)"
  }

  if ! VERIFY_OUT=$(ruby "$HELPERS/verify.rb" "$PR" 2>/dev/null); then
    echo "$VERIFY_OUT"
    echo ""
    warn "Contamination detected in #$PR"
    echo ""
    echo "  To undo: git reset --hard HEAD~1"
    echo "  To accept: release/cherry-pick.sh $VERSION --resume"
    echo ""
    stop
  fi

  success "#$PR — verified clean"
  PICKED="${PICKED:+$PICKED,}$PR"
  BRANCH_LOG="$(git log --oneline HEAD --not origin/release)"
done <<< "$ORDER"

# --- Summary ---

echo ""
echo -e "${BOLD}Cherry-pick complete${RESET}"
echo "  Picked:  $PICKED"
[[ -n "$SKIPPED" ]] && echo "  Skipped: $SKIPPED"
echo ""
echo "Next steps:"
echo "  ruby release/changelog.rb --mode=release --version=$VERSION --prs=$PICKED > Changelog.md"
echo "  bash release/validate_changelog.sh $VERSION"
