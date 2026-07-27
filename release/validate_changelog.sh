#!/bin/bash
# =============================================================================
# Changelog Validator for MarkUs Releases
# =============================================================================
#
# Validates Changelog.md on a release/version branch to catch common issues
# introduced by cherry-pick conflict resolution.
#
# Usage:
#   ./validate_changelog.sh <version> [changelog_path]
#
# Examples:
#   ./validate_changelog.sh v2.9.3
#   ./validate_changelog.sh v2.9.3 /path/to/Changelog.md
#
# What it checks:
#   1. No git conflict markers left in file
#   2. [unreleased] section exists and is empty
#   3. Target version section exists and has entries
#   4. Version sections appear in correct descending order
#   5. No PR numbers duplicated across different version sections
#   6. Sections below the release version match the original release branch
#
# =============================================================================

set -uo pipefail

VERSION="${1:-}"
CHANGELOG="${2:-Changelog.md}"
ERRORS=0
WARNINGS=0

pass()    { echo "  PASS  $1"; }
fail()    { echo "  FAIL  $1"; ERRORS=$((ERRORS + 1)); }
warn()    { echo "  WARN  $1"; WARNINGS=$((WARNINGS + 1)); }
info()    { echo "  INFO  $1"; }
divider() { echo "------------------------------------------------------------------------"; }

# Extract bullet entries from a section. $1 = section name (e.g., "unreleased", "$VERSION")
section_entries() {
    awk -v section="$1" '
        BEGIN { IGNORECASE = 1 }
        /^## \[/ {
            if (found) exit
            header = $0; gsub(/^## \[/, "", header); gsub(/\].*$/, "", header)
            if (tolower(header) == tolower(section)) found = 1
            next
        }
        found && /^- / { print }
    ' "$CHANGELOG"
}

# Extract version strings from ## [vX.Y.Z] headers
version_headers() {
    grep '^## \[v' "$CHANGELOG" | sed 's/## \[\(.*\)\]/\1/'
}

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [changelog_path]"
    echo "  e.g. $0 v2.9.3"
    exit 2
fi

if [ ! -f "$CHANGELOG" ]; then
    echo "Error: $CHANGELOG not found. Run from the repo root or pass the path."
    exit 2
fi

echo ""
echo "Changelog Validation: $VERSION"
echo "File: $CHANGELOG"
divider

# =============================================================================
# CHECK 1: No conflict markers
# =============================================================================

echo ""
echo "[1/6] Conflict markers"

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
echo "[2/6] Unreleased section"

if ! head -5 "$CHANGELOG" | grep -qi '## \[unreleased\]'; then
    fail "[unreleased] section missing or not at top of file"
else
    pass "[unreleased] section present at top of file"
fi

UNRELEASED_ENTRIES=$(section_entries "unreleased" | wc -l | tr -d ' ')

if [ "$UNRELEASED_ENTRIES" -eq 0 ]; then
    pass "[unreleased] section is empty"
else
    warn "[unreleased] section has $UNRELEASED_ENTRIES entries (should be empty on release branch)"
    section_entries "unreleased" | head -5 | sed 's/^/        /'
fi

# =============================================================================
# CHECK 3: Target version section exists and has entries
# =============================================================================

echo ""
echo "[3/6] Version section [$VERSION]"

if ! grep -q "^## \[$VERSION\]" "$CHANGELOG"; then
    fail "[$VERSION] section missing"
else
    pass "[$VERSION] section found"
fi

VERSION_ENTRIES=$(section_entries "$VERSION" | wc -l | tr -d ' ')

if [ "$VERSION_ENTRIES" -eq 0 ]; then
    warn "[$VERSION] section has no entries"
else
    pass "[$VERSION] section has $VERSION_ENTRIES entries"
fi

# =============================================================================
# CHECK 4: Version sections are in descending order
# =============================================================================

echo ""
echo "[4/6] Section ordering"

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
echo "[5/6] Duplicate PR references"

TARGET_PRS=$(section_entries "$VERSION" | grep -o '#[0-9]\+' | sort -u)
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
echo "[6/6] Integrity of older sections"

PREV_VERSION=$(version_headers | awk "found{print; exit} /^$VERSION\$/{found=1}")

if [ -n "$PREV_VERSION" ] && git show origin/release:Changelog.md &>/dev/null; then
    # Extract everything from the previous version onwards in both files
    CURRENT_TAIL=$(awk "/^## \[$PREV_VERSION\]/{found=1} found{print}" "$CHANGELOG")
    ORIGINAL_TAIL=$(git show origin/release:Changelog.md | awk "/^## \[$PREV_VERSION\]/{found=1} found{print}")

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
exit $ERRORS
