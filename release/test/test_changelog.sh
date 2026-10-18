#!/usr/bin/env bash
# Tests for release/changelog.rb, release/validate_changelog.sh and
# release/validate_changelog_master.sh.
# Runs every script for real inside a throwaway git repo with origin/master and
# origin/release refs.
# Run: bash release/test/test_changelog.sh
set -uo pipefail

REPO=$(cd "$(dirname "$0")/../.." && pwd)
REL_VALIDATOR=$REPO/release/validate_changelog.sh
MASTER_VALIDATOR=$REPO/release/validate_changelog_master.sh
BUILDER=$REPO/release/changelog.rb
PASS=0
FAIL=0

T=$(mktemp -d "${TMPDIR:-/var/tmp}/markus-release-test.XXXXXX")
trap 'rm -rf "$T"' EXIT
export GIT_CEILING_DIRECTORIES
GIT_CEILING_DIRECTORIES=$(dirname "$T")
F=$T/fixtures
mkdir -p "$F" "$T/repo"
cd "$T/repo" || exit 1

in_sandbox() { # stop before any git write outside the sandbox
  [ "$(git rev-parse --show-toplevel 2>/dev/null)" = "$(cd "$T/repo" && pwd -P)" ] ||
    { echo "ABORT: git write outside sandbox"; exit 1; }
}

report() { # description, ok(0/1), output
  if [ "$2" -eq 0 ]; then
    PASS=$((PASS + 1)); echo "  PASS  $1"
  else
    FAIL=$((FAIL + 1)); echo "  FAIL  $1"; sed 's/^/        /' <<<"$3"
  fi
}

check() { # description, expected exit, expected text, command...
  local desc=$1 want=$2 text=$3 out code
  shift 3
  out=$("$@" 2>&1); code=$?
  [ "$code" -eq "$want" ] && grep -qF -- "$text" <<<"$out"
  report "$desc (exit $code)" $? "$out"
}

check_absent() { # description, unexpected text, command...
  local desc=$1 text=$2 out
  shift 2
  out=$("$@" 2>&1)
  ! grep -qF -- "$text" <<<"$out"
  report "$desc" $? "$out"
}

# --- Fixtures ------------------------------------------------------------------

SEC="### $(printf '\xF0\x9F\x9B\xA1\xEF\xB8\x8F') Security"
BRK='### 🚨 Breaking changes'
NEW='### ✨ New features and improvements'
BUG='### 🐛 Bug fixes'
DOC='### 📚 Documentation changes'
INT='### 🔧 Internal changes'

unreleased() { # $1 = new-feature entries, $2 = bug-fix entries (newline lists)
  printf '# Changelog\n\n## [unreleased]\n\n'
  printf '%s\n\n%s\n\n' "$SEC" "$BRK"
  printf '%s\n' "$NEW"; [ -n "$1" ] && printf '%s\n' "$1"; printf '\n'
  printf '%s\n' "$BUG"; [ -n "$2" ] && printf '%s\n' "$2"; printf '\n'
  printf '%s\n\n%s\n\n' "$DOC" "$INT"
}

old_sections() {
  printf '## [v3.0.0]\n\n%s\n- Old fix (#50)\n\n' "$BUG"
  printf '## [v2.2.4]\n\n%s\n- Ancient fix (#10)\n\n' "$BUG"
  printf '## [v2.2.4]\n\n%s\n- Ancient fix (#10)\n' "$BUG"
}

v301() { # $1 = new-feature entries, $2 = bug-fix entries
  printf '## [v3.0.1]\n\n'
  [ -n "$1" ] && printf '%s\n%s\n\n' "$NEW" "$1"
  [ -n "$2" ] && printf '%s\n%s\n\n' "$BUG" "$2"
  return 0
}

{ unreleased '' ''; old_sections; } >"$F/release.md"
{ unreleased $'- Feature A (#101)\n- Feature F (#106)' '- Fix B (#102)'; old_sections; } >"$F/master.md"
# Release-branch changelog for v3.0.1 (picks 101-105; 103 is a bot, 104 is changelog-only)
{ unreleased '' ''; v301 '- Feature A (#101)' '- Fix B (#102)'; old_sections; } >"$F/rel_good.md"
# Master changelog after syncing v3.0.1
{ unreleased '- Feature F (#106)' ''; v301 '- Feature A (#101)' '- Fix B (#102)'; old_sections; } >"$F/master_good.md"

# --- Sandbox repo: origin/release at v3.0.0, origin/master with PRs 101-106 -----

git init -q -b master . && in_sandbox
git config user.email test@example.com
git config user.name test
git config commit.gpgsign false
gcommit() { in_sandbox; git add -A && git -c core.hooksPath=/dev/null commit -qm "$1"; }
gref() { in_sandbox; git update-ref "$@"; }

mkdir app && touch app/.keep && cp "$F/release.md" Changelog.md
gcommit 'v3.0.0 (#90)'
gref refs/remotes/origin/release HEAD
echo a >app/a.rb && gcommit 'Add feature A (#101)'
echo b >app/b.rb && gcommit 'Fix B (#102)'
echo lock >Gemfile.lock && gcommit 'build(deps): bump x (#103)'
cp "$F/master.md" Changelog.md && gcommit 'Add missing changelog lines (#104)'
echo e >app/e.rb && gcommit 'Fix E (#105)'
echo f >app/f.rb && gcommit 'Add feature F (#106)'
gref refs/remotes/origin/master HEAD

rel() { bash "$REL_VALIDATOR" v3.0.1 "$@"; }
mst() { bash "$MASTER_VALIDATOR" v3.0.1 "$@"; }
PICKS=(--prs "101,102,103,104" --bots 103)

# --- Release validator ---------------------------------------------------------

echo "Release validator"
check 'good changelog with picks passes' 0 'RESULT: All checks passed' rel "$F/rel_good.md" "${PICKS[@]}"
check '--prs=/--bots= forms work' 0 'RESULT: All checks passed' rel "$F/rel_good.md" --prs=101,102,103,104 --bots=103
check 'changelog-only PR needs no entry' 0 '#104 changes only Changelog.md' rel "$F/rel_good.md" "${PICKS[@]}"
check 'no flags keeps old checks and warns' 0 'WARN  Pick check skipped' rel "$F/rel_good.md"
check 'entry for unpicked PR fails' 1 'Entry for unpicked PR #102' rel "$F/rel_good.md" --prs 101,103,104 --bots 103
check 'picked non-bot PR without entry fails' 1 'Picked PR #105 has no entry in [v3.0.1]' \
  rel "$F/rel_good.md" --prs 101,102,103,104,105 --bots 103
check 'bot PR without entry passes' 0 'RESULT: All checks passed' rel "$F/rel_good.md" --prs 101,102,103 --bots 103
check 'bot PR with entry warns' 0 'Bot PR #102 has an entry' rel "$F/rel_good.md" --prs 101,102 --bots 102
check 'non-numeric PR list is rejected' 2 'Error: --prs and --bots take' rel "$F/rel_good.md" --prs 101,abc
{ unreleased '' ''; v301 '- Feature A (#101)' '- Fix B and C (#102/#107)'; old_sections; } >"$T/multi.md"
check 'multi-PR entry (#a/#b) counts both' 0 'RESULT: All checks passed' rel "$T/multi.md" --prs 101,102,107
{ unreleased '' ''; v301 '- Feature A (#101)' '- Fix B and C (#102, #107)'; old_sections; } >"$T/comma.md"
check 'multi-PR entry (#a, #b) counts both' 0 'RESULT: All checks passed' rel "$T/comma.md" --prs 101,102,107
check 'unpicked PR in a (#a, #b) entry fails' 1 'Entry for unpicked PR #107' rel "$T/comma.md" --prs 101,102
check 'explicit empty --prs is rejected' 2 'Error: --prs is empty' rel "$F/rel_good.md" --prs ''
check 'separator-only --prs is rejected' 2 'Error: --prs is empty' rel "$F/rel_good.md" --prs=,
check '--help prints usage' 0 'Usage:' rel --help
mkdir -p "$T/tools" && cp "$REL_VALIDATOR" "$T/tools/"
check 'missing shared checks file fails clearly' 2 'changelog_checks.sh' bash "$T/tools/validate_changelog.sh" v3.0.1 "$F/rel_good.md"
cp "$REPO/release/changelog_checks.sh" "$REPO/release/common.rb" "$T/tools/" 2>/dev/null
check 'missing duplicate-header allowlist fails clearly' 2 'changelog_duplicate_headers.txt' \
  bash "$T/tools/validate_changelog.sh" v3.0.1 "$F/rel_good.md"

{ unreleased '' ''; v301 '- Feature A (#101)' '- Fix B (#102)'; printf '## [v3.0.0]\n\n%s\n- Dup (#51)\n\n' "$BUG"; old_sections; } >"$T/dup.md"
check 'repeated version header fails' 1 'Repeated version header [v3.0.0]' rel "$T/dup.md" "${PICKS[@]}"
check_absent 'allowlisted repeated header passes' 'Repeated version header [v2.2.4]' rel "$F/rel_good.md" "${PICKS[@]}"

{ unreleased '' ''; printf '## [v3.0.1]\n\n%s\n\n' "$BUG"; old_sections; } >"$T/empty.md"
check 'empty target section fails' 1 'FAIL  [v3.0.1] section has no entries' rel "$T/empty.md"
{ unreleased '' ''; v301 '- Feature A (#101)' '- Fix B (#102)'; printf '## [v3.0.0]\n\n%s\n\n' "$BUG"; } >"$T/empty_old.md"
check 'empty older section fails' 1 'Empty version section [v3.0.0]' rel "$T/empty_old.md" "${PICKS[@]}"

# --- Master validator ----------------------------------------------------------

echo "Master validator"
check 'good master sync with picks passes' 0 'RESULT: All checks passed' mst "$F/master_good.md" "${PICKS[@]}"
check 'no flags keeps old checks and warns' 0 'WARN  Pick check skipped' mst "$F/master_good.md"
check 'explicit empty --prs is rejected' 2 'Error: --prs is empty' mst "$F/master_good.md" --prs ''
check '--help prints usage' 0 'Usage:' mst --help
check 'entry for unpicked PR fails' 1 'Entry for unpicked PR #101' mst "$F/master_good.md" --prs 102,103,104 --bots 103
check 'picked non-bot PR without entry fails' 1 'Picked PR #106 has no entry in [v3.0.1]' \
  mst "$F/master_good.md" --prs 101,102,104,106
{ unreleased '- Feature F (#106)' ''; v301 '- Feature A (#101)' '- Fix B (#102)'; printf '## [v3.0.1]\n\n%s\n- X (#101)\n\n' "$BUG"; old_sections; } >"$T/mdup.md"
check 'repeated version header fails' 1 'Repeated version header [v3.0.1]' mst "$T/mdup.md" "${PICKS[@]}"
{ unreleased '- Feature F (#106)' ''; v301 '- Feature A (#101)' '- Fix B (#102)'; printf '## [v3.0.0]\n\n%s\n\n' "$BUG"; } >"$T/mempty_old.md"
check 'empty older section fails' 1 'Empty version section [v3.0.0]' mst "$T/mempty_old.md" "${PICKS[@]}"

# --- changelog.rb --------------------------------------------------------------

echo "changelog.rb"
build() { ruby "$BUILDER" "$@" 2>"$T/stderr"; }
count() { grep -c -- "$1" "$2"; }

build --mode=master-sync --version=v3.0.1 --prs=101,102 >"$T/sync1.md"
cmp -s "$T/sync1.md" "$F/master_good.md"
report 'master-sync moves picked entries into [v3.0.1]' $? "$(diff "$T/sync1.md" "$F/master_good.md")"

build --mode=release --version=v3.0.1 --prs=101,102 >"$T/rel1.md"
cmp -s "$T/rel1.md" "$F/rel_good.md"
report 'release mode builds the release changelog' $? "$(diff "$T/rel1.md" "$F/rel_good.md")"

build --mode=master-sync --version=v3.0.1 --prs=101,102,103,105 --bots=103 >/dev/null
check 'warns for a picked PR with no entry' 0 'Warning: picked PR #105 has no entry in [v3.0.1]' cat "$T/stderr"
check_absent 'no warning for a bot PR' '#103' cat "$T/stderr"

# Land the sync on master, then rerun both modes.
cp "$T/sync1.md" Changelog.md && gcommit 'v3.0.1 changelog (#110)'
gref refs/remotes/origin/master HEAD

build --mode=master-sync --version=v3.0.1 --prs=101,102 >"$T/sync2.md"
cmp -s "$T/sync2.md" "$T/sync1.md"
report 'master-sync rerun is a no-op' $? "$(diff "$T/sync1.md" "$T/sync2.md")"

build --mode=release --version=v3.0.1 --prs=101,102 >"$T/rel2.md"
cmp -s "$T/rel2.md" "$F/rel_good.md"
report 'release mode after master-sync keeps the entries' $? "$(diff "$T/rel2.md" "$F/rel_good.md")"

# A second batch: #106 picked after #101/#102 were already synced.
build --mode=master-sync --version=v3.0.1 --prs=101,102,106 >"$T/sync3.md"
[ "$(count '^## \[v3.0.1\]' "$T/sync3.md")" -eq 1 ] && [ "$(count '#101' "$T/sync3.md")" -eq 1 ] &&
  [ "$(count '#106' "$T/sync3.md")" -eq 1 ] && ! sed -n '/^## \[unreleased\]/,/^## \[v/p' "$T/sync3.md" | grep -q '#106'
report 'master-sync merges new picks into the existing section' $? "$(cat "$T/sync3.md")"

# A hand-added entry on the release branch survives a release-mode rebuild.
in_sandbox && git checkout -q -b rel refs/remotes/origin/release
{ unreleased '' ''; v301 '' '- Hand fix (#107)'; old_sections; } >Changelog.md && gcommit 'Hand entry'
gref refs/remotes/origin/release HEAD
build --mode=release --version=v3.0.1 --prs=101,102,107 >"$T/rel3.md"
ok=0; [ "$(count '#107' "$T/rel3.md")" -eq 1 ] && [ "$(count '#101' "$T/rel3.md")" -eq 1 ] && [ "$(count '^## \[v3.0.1\]' "$T/rel3.md")" -eq 1 ] || ok=1
report 'release mode merges with the existing release section' $ok "$(cat "$T/rel3.md")"

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
