#!/bin/bash
# =============================================================================
# Changelog Validator: Master Branch Sync
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
#   ./validate_changelog_master.sh <version> [changelog_path] [--prs N,N,...] [--bots N,N,...]
#
# Examples:
#   ./validate_changelog_master.sh v2.9.4
#   ./validate_changelog_master.sh v2.9.4 /path/to/Changelog.md
#   ./validate_changelog_master.sh v2.9.4 --prs 7783,7851,7858 --bots 7858
#
# CHANGELOG_REFERENCE=<ref> replaces origin/master as the pre-edit reference.
#
# What it checks:
#   1. [unreleased] section still has entries (not wiped out)
#   2. New [v2.X.Y] section exists between [unreleased] and previous version
#   3. Every entry in [v2.X.Y] was present in origin/master's [unreleased]
#   4. No entries disappeared: every entry removed from [unreleased] is in [v2.X.Y]
#   5. Everything from the previous version downward is identical to origin/master
#   6. No repeated version headers (except changelog_duplicate_headers.txt)
#      and no empty version sections anywhere in the file
#   7. Entries match the picks (--prs): no entry for an unpicked PR, and an
#      entry for every picked PR except bots (--bots) and PRs whose only
#      changed file is Changelog.md. Skipped with a WARN when --prs is absent;
#      an empty --prs value is an error (exit 2).
#
# =============================================================================

set -uo pipefail

REFERENCE="${CHANGELOG_REFERENCE:-origin/master}"

usage() {
    echo "Usage: $0 <version> [changelog_path] [--prs N,N,...] [--bots N,N,...]"
    echo "  e.g. $0 v2.9.4 --prs 7783,7851,7858 --bots 7858"
    echo ""
    echo "Validates changelog edits when syncing released entries to master."
    echo "Run from the repo root on the v2.X.Y-changelog branch."
}

# Shared checks; common.rb and changelog_duplicate_headers.txt sit beside them.
CHECKS="$(dirname "$0")/changelog_checks.sh"
# shellcheck source=release/changelog_checks.sh
source "$CHECKS" 2>/dev/null || { echo "Error: $CHECKS not found. Copy it with the validator."; exit 2; }
parse_args "$@"
check_args

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
echo "[1/7] Unreleased section has entries"

if ! head -5 "$CHANGELOG" | grep -qi '## \[unreleased\]'; then
    fail "[unreleased] section missing or not at top of file"
else
    NEW_UNRELEASED_COUNT=$(section_entries "$CHANGELOG" "unreleased" | wc -l | tr -d ' ' || true)

    if [ "$NEW_UNRELEASED_COUNT" -gt 0 ]; then
        pass "[unreleased] section has $NEW_UNRELEASED_COUNT entries"
    else
        fail "[unreleased] section is empty. Entries were wiped instead of moved"
        info "The [unreleased] section should retain entries not part of $VERSION"
    fi
fi

# =============================================================================
# CHECK 2: New version section exists in correct position
# =============================================================================

echo ""
echo "[2/7] New [$VERSION] section exists in correct position"

if ! grep -q "^## \[$VERSION\]" "$CHANGELOG"; then
    fail "[$VERSION] section not found"
else
    pass "[$VERSION] section found"

    if grep -q "^## \[$VERSION\]" "$REF_CHANGELOG"; then
        warn "[$VERSION] section already existed in $REFERENCE. Is this a re-run?"
    fi

    FIRST_VERSIONED=$(version_headers | head -1)
    if [ "$FIRST_VERSIONED" != "$VERSION" ]; then
        fail "[$VERSION] is not the first version section (found [$FIRST_VERSIONED] first)"
    else
        pass "[$VERSION] is the first version section after [unreleased]"
    fi

    VERSION_COUNT=$(section_entries "$CHANGELOG" "$VERSION" | wc -l | tr -d ' ' || true)
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
echo "[3/7] All [$VERSION] entries came from [unreleased]"

OLD_UNRELEASED="$TMPDIR_VALIDATE/old_unreleased.txt"
section_entries "$REF_CHANGELOG" "unreleased" > "$OLD_UNRELEASED"

VERSION_ENTRIES_FILE="$TMPDIR_VALIDATE/version_entries.txt"
section_entries "$CHANGELOG" "$VERSION" > "$VERSION_ENTRIES_FILE"

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
# CHECK 4: No entries vanished; removed entries accounted for in [VERSION]
# =============================================================================

echo ""
echo "[4/7] No entries lost: every removal from [unreleased] is in [$VERSION]"

NEW_UNRELEASED_FILE="$TMPDIR_VALIDATE/new_unreleased.txt"
section_entries "$CHANGELOG" "unreleased" > "$NEW_UNRELEASED_FILE"

MISSING_ENTRIES=0
MOVED_COUNT=0
while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    if ! grep -qFx -- "$entry" "$NEW_UNRELEASED_FILE"; then
        # This entry left unreleased, so it must be in [VERSION]
        MOVED_COUNT=$((MOVED_COUNT + 1))
        if ! grep -qFx -- "$entry" "$VERSION_ENTRIES_FILE"; then
            # Reworded entry: same PR number in [VERSION] => warn, not fail
            PR_NUM=$(echo "$entry" | grep -o '(#[0-9]*)' | tail -1)
            # Renumbered entry: same text in [VERSION] with a PR suffix added
            STRIPPED_MATCH=$(sed 's/ (#[0-9]*)$//' "$VERSION_ENTRIES_FILE" | grep -cFx -- "$entry")
            if [ -n "$PR_NUM" ] && grep -qF -- "$PR_NUM" "$VERSION_ENTRIES_FILE"; then
                warn "Reworded (same PR $PR_NUM appears in [$VERSION]): $entry"
            elif [ "$STRIPPED_MATCH" -gt 0 ]; then
                warn "Renumbered (same text in [$VERSION] with a PR suffix): $entry"
            else
                if [ "$MISSING_ENTRIES" -eq 0 ]; then
                    fail "Entries removed from [unreleased] but NOT in [$VERSION]:"
                fi
                MISSING_ENTRIES=$((MISSING_ENTRIES + 1))
                echo "        $entry"
            fi
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
echo "[5/7] Older sections unchanged"

PREV_VERSION=$(version_headers "$REF_CHANGELOG" | head -1)

if [ -z "$PREV_VERSION" ]; then
    warn "Could not determine previous version section in $REFERENCE"
else
    CURRENT_TAIL=$(from_section "$CHANGELOG" "$PREV_VERSION")
    ORIGINAL_TAIL=$(from_section "$REF_CHANGELOG" "$PREV_VERSION")

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
# CHECK 6: No repeated version headers or empty version sections
# =============================================================================

echo ""
echo "[6/7] Version headers"

check_structure

# =============================================================================
# CHECK 7: Entries match the picked PRs
# =============================================================================

echo ""
echo "[7/7] Entries match picks"

check_picks <<<"$(section_entries "$CHANGELOG" "$VERSION")"

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
[ "$ERRORS" -eq 0 ]
