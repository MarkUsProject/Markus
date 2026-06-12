#!/bin/bash
# =============================================================================
# Changelog Validator — Master Branch Sync
# =============================================================================
#
# Validates that the Changelog.md edit on master correctly moves released
# entries from [unreleased] into a new version section, without touching
# anything else.
#
# This script compares the working copy of Changelog.md against origin/master
# (the pre-edit state). It must be run from the repo root on the changelog
# branch (v2.X.Y-changelog), BEFORE pushing.
#
# Usage:
#   ./validate_changelog_master.sh <version> [changelog_path]
#
# Examples:
#   ./validate_changelog_master.sh v2.9.4
#   ./validate_changelog_master.sh v2.9.4 /path/to/Changelog.md
#
# What it checks:
#   1. [unreleased] section still has entries (not wiped out)
#   2. New [v2.X.Y] section exists between [unreleased] and previous version
#   3. Every entry in [v2.X.Y] was present in origin/master's [unreleased]
#   4. No entries disappeared — every entry removed from [unreleased] is in [v2.X.Y]
#   5. Everything from the previous version downward is identical to origin/master
#
# =============================================================================

set -uo pipefail

VERSION="${1:-}"
CHANGELOG="${2:-Changelog.md}"
REFERENCE="origin/master"
ERRORS=0
WARNINGS=0

pass()    { echo "  PASS  $1"; }
fail()    { echo "  FAIL  $1"; ERRORS=$((ERRORS + 1)); }
warn()    { echo "  WARN  $1"; WARNINGS=$((WARNINGS + 1)); }
info()    { echo "  INFO  $1"; }
divider() { echo "------------------------------------------------------------------------"; }

# Extract bullet entries (lines starting with "- ") from a given section.
# Reads from a file. Outputs sorted entries for stable comparison.
# $1 = file path
# $2 = section name (e.g., "unreleased" or "v2.9.4")
extract_entries() {
    local file="$1"
    local section="$2"

    awk -v section="$section" '
        BEGIN { found = 0; IGNORECASE = 1 }
        /^## \[/ {
            if (found) exit
            header = $0
            gsub(/^## \[/, "", header)
            gsub(/\].*$/, "", header)
            if (tolower(header) == tolower(section)) found = 1
            next
        }
        found && /^- / { print }
    ' "$file" | sort
}

# Extract everything from a given version section header to EOF.
# $1 = file path
# $2 = version string (e.g., "v2.9.3")
extract_from_version() {
    local file="$1"
    local version="$2"

    awk -v version="$version" '
        BEGIN { found = 0 }
        $0 ~ "^## \\[" version "\\]" { found = 1 }
        found { print }
    ' "$file"
}

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [changelog_path]"
    echo "  e.g. $0 v2.9.4"
    echo ""
    echo "Validates changelog edits when syncing released entries to master."
    echo "Run from the repo root on the v2.X.Y-changelog branch."
    exit 2
fi

if [ ! -f "$CHANGELOG" ]; then
    echo "Error: $CHANGELOG not found. Run from the repo root or pass the path."
    exit 2
fi

if ! git show "${REFERENCE}:Changelog.md" &>/dev/null; then
    echo "Error: Cannot read ${REFERENCE}:Changelog.md"
    echo "Make sure you've fetched origin and are in the git repo root."
    exit 2
fi

TMPDIR_VALIDATE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_VALIDATE"' EXIT

REF_CHANGELOG="$TMPDIR_VALIDATE/ref_changelog.md"
git show "${REFERENCE}:Changelog.md" > "$REF_CHANGELOG"

echo ""
echo "Master Changelog Validation: $VERSION"
echo "Working file: $CHANGELOG"
echo "Reference:    ${REFERENCE}:Changelog.md"
divider

# =============================================================================
# CHECK 1: [unreleased] section still has entries
# =============================================================================

echo ""
echo "[1/5] Unreleased section has entries"

if ! head -5 "$CHANGELOG" | grep -qi '## \[unreleased\]'; then
    fail "[unreleased] section missing or not at top of file"
else
    NEW_UNRELEASED_COUNT=$(extract_entries "$CHANGELOG" "unreleased" | wc -l | tr -d ' ' || true)

    if [ "$NEW_UNRELEASED_COUNT" -gt 0 ]; then
        pass "[unreleased] section has $NEW_UNRELEASED_COUNT entries"
    else
        fail "[unreleased] section is empty — entries were wiped instead of moved"
        info "The [unreleased] section should retain entries not part of $VERSION"
    fi
fi

# =============================================================================
# CHECK 2: New version section exists in correct position
# =============================================================================

echo ""
echo "[2/5] New [$VERSION] section exists in correct position"

if ! grep -q "^## \[$VERSION\]" "$CHANGELOG"; then
    fail "[$VERSION] section not found"
else
    pass "[$VERSION] section found"

    if grep -q "^## \[$VERSION\]" "$REF_CHANGELOG"; then
        warn "[$VERSION] section already existed in $REFERENCE — is this a re-run?"
    fi

    FIRST_VERSIONED=$(grep '^## \[v' "$CHANGELOG" | head -1 | sed 's/## \[\(.*\)\]/\1/')
    if [ "$FIRST_VERSIONED" != "$VERSION" ]; then
        fail "[$VERSION] is not the first version section (found [$FIRST_VERSIONED] first)"
    else
        pass "[$VERSION] is the first version section after [unreleased]"
    fi

    VERSION_COUNT=$(extract_entries "$CHANGELOG" "$VERSION" | wc -l | tr -d ' ' || true)
    if [ "$VERSION_COUNT" -eq 0 ]; then
        fail "[$VERSION] section has no entries"
    else
        pass "[$VERSION] section has $VERSION_COUNT entries"
    fi
fi

# =============================================================================
# CHECK 3: Every entry in [VERSION] was in origin/master's [unreleased]
# =============================================================================

echo ""
echo "[3/5] All [$VERSION] entries came from [unreleased]"

OLD_UNRELEASED="$TMPDIR_VALIDATE/old_unreleased.txt"
extract_entries "$REF_CHANGELOG" "unreleased" > "$OLD_UNRELEASED"

VERSION_ENTRIES_FILE="$TMPDIR_VALIDATE/version_entries.txt"
extract_entries "$CHANGELOG" "$VERSION" > "$VERSION_ENTRIES_FILE"

VERSION_COUNT=$(wc -l < "$VERSION_ENTRIES_FILE" | tr -d ' ')

FROM_UNRELEASED=0
NEW_ENTRIES=0
while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    if grep -qFx -- "$entry" "$OLD_UNRELEASED"; then
        FROM_UNRELEASED=$((FROM_UNRELEASED + 1))
    else
        if [ "$NEW_ENTRIES" -eq 0 ]; then
            info "Some [$VERSION] entries are NEW (not in ${REFERENCE}'s [unreleased]):"
        fi
        NEW_ENTRIES=$((NEW_ENTRIES + 1))
        echo "        $entry"
    fi
done < "$VERSION_ENTRIES_FILE"

if [ "$NEW_ENTRIES" -gt 0 ]; then
    warn "$NEW_ENTRIES entries in [$VERSION] were not in ${REFERENCE}'s [unreleased] (e.g., dep bumps added during release)"
    info "Verify these entries belong in this release"
fi
if [ "$FROM_UNRELEASED" -gt 0 ]; then
    pass "$FROM_UNRELEASED of $VERSION_COUNT entries in [$VERSION] came from ${REFERENCE}'s [unreleased]"
fi

# =============================================================================
# CHECK 4: No entries vanished — removed entries accounted for in [VERSION]
# =============================================================================

echo ""
echo "[4/5] No entries lost — every removal from [unreleased] is in [$VERSION]"

NEW_UNRELEASED_FILE="$TMPDIR_VALIDATE/new_unreleased.txt"
extract_entries "$CHANGELOG" "unreleased" > "$NEW_UNRELEASED_FILE"

MISSING_ENTRIES=0
MOVED_COUNT=0
while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    if ! grep -qFx -- "$entry" "$NEW_UNRELEASED_FILE"; then
        # This entry was removed from unreleased — it must be in [VERSION]
        MOVED_COUNT=$((MOVED_COUNT + 1))
        if ! grep -qFx -- "$entry" "$VERSION_ENTRIES_FILE"; then
            if [ "$MISSING_ENTRIES" -eq 0 ]; then
                fail "Entries removed from [unreleased] but NOT in [$VERSION]:"
            fi
            MISSING_ENTRIES=$((MISSING_ENTRIES + 1))
            echo "        $entry"
        fi
    fi
done < "$OLD_UNRELEASED"

if [ "$MISSING_ENTRIES" -gt 0 ]; then
    info "$MISSING_ENTRIES entries were deleted instead of moved"
else
    pass "All $MOVED_COUNT entries removed from [unreleased] are present in [$VERSION]"
fi

# =============================================================================
# CHECK 5: Everything from previous version downward is identical
# =============================================================================

echo ""
echo "[5/5] Older sections unchanged"

PREV_VERSION=$(grep '^## \[v' "$REF_CHANGELOG" | head -1 | sed 's/## \[\(.*\)\]/\1/')

if [ -z "$PREV_VERSION" ]; then
    warn "Could not determine previous version section in $REFERENCE"
else
    CURRENT_TAIL=$(extract_from_version "$CHANGELOG" "$PREV_VERSION")
    ORIGINAL_TAIL=$(extract_from_version "$REF_CHANGELOG" "$PREV_VERSION")

    if [ "$CURRENT_TAIL" != "$ORIGINAL_TAIL" ]; then
        fail "Content from [$PREV_VERSION] onwards differs from $REFERENCE"
        info "Older sections must not be modified"
        DIFF_OUTPUT=$(diff <(echo "$CURRENT_TAIL") <(echo "$ORIGINAL_TAIL") | head -20)
        if [ -n "$DIFF_OUTPUT" ]; then
            info "First differences:"
            echo "$DIFF_OUTPUT" | sed 's/^/        /'
        fi
    else
        pass "Everything from [$PREV_VERSION] onwards is identical to $REFERENCE"
    fi
fi

# =============================================================================
# Summary
# =============================================================================

echo ""
divider
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "RESULT: All checks passed ✅"
elif [ $ERRORS -eq 0 ]; then
    echo "RESULT: Passed with $WARNINGS warning(s)"
else
    echo "RESULT: FAILED with $ERRORS error(s) and $WARNINGS warning(s)"
    echo ""
    echo "To debug:"
    echo "  View current:   head -60 $CHANGELOG"
    echo "  View reference: git show $REFERENCE:Changelog.md | head -60"
    echo "  Full diff:      git diff $REFERENCE -- Changelog.md"
fi
echo ""
exit $ERRORS
