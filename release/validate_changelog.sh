#!/bin/bash
# =============================================================================
# Changelog Validator for MarkUs Releases
# =============================================================================
#
# Validates Changelog.md on a release/version branch to catch common issues
# introduced by cherry-pick conflict resolution.
#
# Usage:
#   ./validate_changelog.sh <version> [changelog_path] [--prs N,N,...] [--bots N,N,...]
#
# Examples:
#   ./validate_changelog.sh v2.9.3
#   ./validate_changelog.sh v2.9.3 /path/to/Changelog.md
#   ./validate_changelog.sh v2.9.3 --prs 8056,8171,8194 --bots 8194
#
# What it checks:
#   1. No git conflict markers left in file
#   2. [unreleased] section exists and is empty
#   3. Target version section exists and has entries
#   4. Version sections appear in correct descending order
#   5. No PR numbers duplicated across different version sections
#   6. Sections below the release version match the original release branch
#   7. No repeated version headers (except changelog_duplicate_headers.txt)
#      and no empty version sections anywhere in the file
#   8. Entries match the picks (--prs): no entry for an unpicked PR, and an
#      entry for every picked PR except bots (--bots) and PRs whose only
#      changed file is Changelog.md. Skipped with a WARN when --prs is absent;
#      an empty --prs value is an error (exit 2).
#
# =============================================================================

set -uo pipefail

usage() {
    echo "Usage: $0 <version> [changelog_path] [--prs N,N,...] [--bots N,N,...]"
    echo "  e.g. $0 v2.9.3 --prs 8056,8171,8194 --bots 8194"
}

# Shared checks; common.rb and changelog_duplicate_headers.txt sit beside them.
CHECKS="$(dirname "$0")/changelog_checks.sh"
# shellcheck source=release/changelog_checks.sh
source "$CHECKS" 2>/dev/null || { echo "Error: $CHECKS not found. Copy it with the validator."; exit 2; }
parse_args "$@"
check_args

echo ""
echo "Changelog Validation: $VERSION"
echo "File: $CHANGELOG"
divider

# =============================================================================
# CHECK 1: No conflict markers
# =============================================================================

echo ""
echo "[1/8] Conflict markers"

MARKERS=$(grep -n '^\(<<<<<<<\|=======\|>>>>>>>\)' "$CHANGELOG" 2>/dev/null || true)
if [ -z "$MARKERS" ]; then
    pass "No conflict markers"
else
    fail "Conflict markers found in file:"
    echo "$MARKERS" | head -10 | sed 's/^/        /'
fi

# =============================================================================
# CHECK 2: [unreleased] section exists and is empty
# =============================================================================

echo ""
echo "[2/8] Unreleased section"

if ! head -5 "$CHANGELOG" | grep -qi '## \[unreleased\]'; then
    fail "[unreleased] section missing or not at top of file"
else
    pass "[unreleased] section present at top of file"
fi

UNRELEASED_ENTRIES=$(section_entries "$CHANGELOG" "unreleased" | wc -l | tr -d ' ')

if [ "$UNRELEASED_ENTRIES" -eq 0 ]; then
    pass "[unreleased] section is empty"
else
    warn "[unreleased] section has $UNRELEASED_ENTRIES entries (should be empty on release branch)"
    section_entries "$CHANGELOG" "unreleased" | head -5 | sed 's/^/        /'
fi

# =============================================================================
# CHECK 3: Target version section exists and has entries
# =============================================================================

echo ""
echo "[3/8] Version section [$VERSION]"

if ! grep -q "^## \[$VERSION\]" "$CHANGELOG"; then
    fail "[$VERSION] section missing"
else
    pass "[$VERSION] section found"
fi

VERSION_ENTRIES=$(section_entries "$CHANGELOG" "$VERSION" | wc -l | tr -d ' ')

if [ "$VERSION_ENTRIES" -eq 0 ]; then
    fail "[$VERSION] section has no entries"
else
    pass "[$VERSION] section has $VERSION_ENTRIES entries"
fi

# =============================================================================
# CHECK 4: Version sections are in descending order
# =============================================================================

echo ""
echo "[4/8] Section ordering"

VERSIONS_IN_FILE=$(version_headers | head -10)
SORTED_VERSIONS=$(echo "$VERSIONS_IN_FILE" | sort -t. -k1,1r -k2,2rn -k3,3rn)

if [ "$VERSIONS_IN_FILE" != "$SORTED_VERSIONS" ]; then
    warn "Version sections may be out of order"
    info "Found order:"
    echo "$VERSIONS_IN_FILE" | head -5 | sed 's/^/        /'
else
    pass "Version sections in correct descending order"
fi

FIRST_VERSION=$(version_headers | head -1)
if [ "$FIRST_VERSION" != "$VERSION" ]; then
    warn "Expected [$VERSION] as first version, found [$FIRST_VERSION]"
else
    pass "[$VERSION] is the first version after [unreleased]"
fi

# =============================================================================
# CHECK 5: No PR numbers duplicated across version sections
# =============================================================================

echo ""
echo "[5/8] Duplicate PR references"

TARGET_PRS=$(section_entries "$CHANGELOG" "$VERSION" | grep -o '#[0-9]\+' | sort -u)
OTHER_PRS=$(awk "found && /^## \[v/{p=1} p{print} /^## \[$VERSION\]/{found=1}" "$CHANGELOG" \
    | grep -o '#[0-9]\+' | sort -u)

DUPLICATES=""
for pr in $TARGET_PRS; do
    if echo "$OTHER_PRS" | grep -q "^${pr}$"; then
        DUPLICATES="$DUPLICATES $pr"
    fi
done

if [ -n "$DUPLICATES" ]; then
    warn "PRs appearing in both [$VERSION] and older sections:$DUPLICATES"
    info "This may indicate cherry-pick entries leaked into wrong sections"
    for pr in $DUPLICATES; do
        info "  $pr appears on lines: $(grep -n "$pr" "$CHANGELOG" | cut -d: -f1 | tr '\n' ' ')"
    done
else
    pass "No PR numbers duplicated between [$VERSION] and older sections"
fi

# =============================================================================
# CHECK 6: Older sections unchanged from release branch
# =============================================================================

echo ""
echo "[6/8] Integrity of older sections"

PREV_VERSION=$(version_headers | awk "found{print; exit} /^$VERSION\$/{found=1}")

if [ -n "$PREV_VERSION" ] && git show origin/release:Changelog.md &>/dev/null; then
    CURRENT_TAIL=$(from_section "$CHANGELOG" "$PREV_VERSION")
    ORIGINAL_TAIL=$(git show origin/release:Changelog.md | from_section - "$PREV_VERSION")

    if [ "$CURRENT_TAIL" != "$ORIGINAL_TAIL" ]; then
        fail "Sections from [$PREV_VERSION] onwards differ from origin/release"
        info "This suggests cherry-pick entries leaked into older sections"
        info "Compare with: git show origin/release:Changelog.md"
    else
        pass "Sections from [$PREV_VERSION] onwards match origin/release"
    fi
else
    info "Skipped (could not determine previous version or origin/release not available)"
fi

# =============================================================================
# CHECK 7: No repeated version headers or empty version sections
# =============================================================================

echo ""
echo "[7/8] Version headers"

check_structure

# =============================================================================
# CHECK 8: Entries match the picked PRs
# =============================================================================

echo ""
echo "[8/8] Entries match picks"

check_picks <<<"$(section_entries "$CHANGELOG" "$VERSION")"

# =============================================================================
# Summary
# =============================================================================

echo ""
divider
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "RESULT: All checks passed"
elif [ $ERRORS -eq 0 ]; then
    echo "RESULT: Passed with $WARNINGS warning(s)"
else
    echo "RESULT: FAILED with $ERRORS error(s) and $WARNINGS warning(s)"
    echo ""
    echo "To debug:"
    echo "  View master reference:  git show master:Changelog.md | head -60"
    echo "  View release reference: git show origin/release:Changelog.md | head -30"
    echo "  Search for markers:     grep -n '<<<<<<' Changelog.md"
fi
echo ""
[ "$ERRORS" -eq 0 ]
