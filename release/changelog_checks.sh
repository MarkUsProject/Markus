# shellcheck shell=bash
# Shared parts of release/validate_changelog.sh and release/validate_changelog_master.sh.
# Sourced, not run. The caller defines usage() first, then calls
# parse_args "$@" and check_args, and counts results in ERRORS and WARNINGS.
#
# Sets VERSION, CHANGELOG, BOTS, and PRS only when --prs is given, so an
# absent --prs (pick check skipped with a WARN) differs from an empty one (error).

CHECKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALLOWLIST="$CHECKS_DIR/changelog_duplicate_headers.txt"
VERSION=""
CHANGELOG="Changelog.md"
BOTS=""
ERRORS=0
WARNINGS=0

pass()    { echo "  PASS  $1"; }
fail()    { echo "  FAIL  $1"; ERRORS=$((ERRORS + 1)); }
warn()    { echo "  WARN  $1"; WARNINGS=$((WARNINGS + 1)); }
info()    { echo "  INFO  $1"; }
divider() { echo "------------------------------------------------------------------------"; }

# <version> [changelog_path] [--prs N,N] [--bots N,N], flags in either form.
parse_args() {
    local positional=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            --prs=*)  PRS="${1#*=}" ;;
            --bots=*) BOTS="${1#*=}" ;;
            --prs)    PRS="${2:-}"; shift ;;
            --bots)   BOTS="${2:-}"; shift ;;
            *) positional+=("$1") ;;
        esac
        shift
    done
    VERSION="${positional[0]:-}"
    CHANGELOG="${positional[1]:-Changelog.md}"
}

# Stops with exit 2 on bad arguments or a missing input file.
check_args() {
    [ -n "$VERSION" ] || { usage; exit 2; }
    grep -q '[^0-9#, ]' <<<"${PRS-}$BOTS" && {
        echo "Error: --prs and --bots take comma-separated PR numbers, got '${PRS-}' / '$BOTS'"
        exit 2
    }
    [ -n "${PRS+set}" ] && [ -z "$(list_lines "$PRS")" ] && {
        echo "Error: --prs is empty. Pass the picked PR numbers, or leave out --prs to skip the pick check."
        exit 2
    }
    [ -f "$CHANGELOG" ] || { echo "Error: $CHANGELOG not found. Run from the repo root or pass the path."; exit 2; }
    [ -f "$ALLOWLIST" ] || { echo "Error: $ALLOWLIST not found. Copy it with the validator."; exit 2; }
}

# Bullet entries ("- ...") of section $2 (e.g. "unreleased", "v2.9.6") in file $1
section_entries() {
    awk -v section="$2" '
        /^## \[/ {
            if (found) exit
            header = $0; gsub(/^## \[/, "", header); gsub(/\].*$/, "", header)
            if (tolower(header) == tolower(section)) found = 1
            next
        }
        found && /^- / { print }
    ' "$1"
}

# Version strings from the ## [vX.Y.Z] headers of file $1 (default $CHANGELOG)
version_headers() {
    grep '^## \[v' "${1:-$CHANGELOG}" | sed 's/## \[\(.*\)\]/\1/'
}

# Everything in file $1 ("-" for stdin) from the ## [$2] header to the end
from_section() {
    awk -v version="$2" '$0 ~ "^## \\[" version "\\]" { found = 1 } found { print }' "$1"
}

# One number per line from a comma list ("8056, #8171" -> 8056 / 8171)
list_lines() { echo "$1" | tr ', ' '\n\n' | sed 's/^#//' | grep -v '^$' | sort -u; }
in_list()    { grep -qx -- "$1" <<<"$2"; }

# PR numbers cited in the entries on stdin, read by ReleaseHelpers.pr_refs
pr_numbers() { ruby -r "$CHECKS_DIR/common.rb" -e 'puts ReleaseHelpers.pr_refs($stdin.read).uniq'; }

# True when the PR's commit on origin/master changes only Changelog.md
changelog_only() {
    local sha
    sha=$(git log origin/master --format='%H %s' 2>/dev/null \
        | grep -E "\(#$1\)\$|Merge pull request #$1 " | head -1 | cut -d' ' -f1)
    [ -n "$sha" ] && [ "$(git diff --name-only "$sha^1" "$sha" 2>/dev/null)" = "Changelog.md" ]
}

# Repeated ## [vX.Y.Z] headers (minus the allowlist) and empty version sections
check_structure() {
    local allowed dups empty v
    allowed=$(grep -v -e '^#' -e '^[[:space:]]*$' "$ALLOWLIST")
    dups=$(version_headers | sort | uniq -d)
    for v in $dups; do
        in_list "$v" "$allowed" && { info "[$v] repeats (allowlisted in $(basename "$ALLOWLIST"))"; continue; }
        fail "Repeated version header [$v]"
    done
    empty=$(awk '
        /^## \[/ { if (h != "" && n == 0) print h; h = ($0 ~ /^## \[v/) ? $0 : ""; n = 0; next }
        /^- / { n++ }
        END { if (h != "" && n == 0) print h }
    ' "$CHANGELOG")
    while IFS= read -r v; do
        [ -n "$v" ] && fail "Empty version section ${v#\#\# }"
    done <<<"$empty"
    [ -z "$dups" ] && [ -z "$empty" ] && pass "No repeated version headers or empty version sections"
    return 0
}

# Entries in [$VERSION] (stdin) against the picked PRs
check_picks() {
    local entries listed picked bots before n
    entries=$(cat)
    [ -n "${PRS+set}" ] || { warn "Pick check skipped: pass --prs <picked PRs> and --bots <bot PRs>"; return 0; }
    before=$ERRORS
    listed=$(pr_numbers <<<"$entries")
    picked=$(list_lines "$PRS")
    bots=$(list_lines "$BOTS")
    for n in $listed; do
        in_list "$n" "$picked" || fail "Entry for unpicked PR #$n: $(grep -F "#$n" <<<"$entries" | head -1)"
    done
    for n in $picked; do
        in_list "$n" "$listed" && {
            in_list "$n" "$bots" && warn "Bot PR #$n has an entry (bot bumps get none since v2.10.3)"
            continue
        }
        in_list "$n" "$bots" && continue
        changelog_only "$n" && { info "#$n changes only Changelog.md; no entry needed"; continue; }
        fail "Picked PR #$n has no entry in [$VERSION]"
    done
    while IFS= read -r n; do
        [ -n "$n" ] && warn "Entry without a PR number: $n"
    done <<<"$(grep '^- ' <<<"$entries" | grep -vE '\(#[0-9]+')"
    [ "$ERRORS" -eq "$before" ] && pass "Entries match the $(wc -l <<<"$picked" | tr -d ' ') picked PRs"
    return 0
}
