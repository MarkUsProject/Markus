#!/bin/bash
# Scratch-repo tests for release/cherry-pick.sh and release/verify.rb.
#
# Usage: bash release/test/test_cherry_pick.sh
#   SRC=<dir> runs the same cases against other copies of those two files
#   (same relative paths under <dir>), e.g. older versions.
#
# Every git write runs in a throwaway repo under $TMPDIR, guarded by a toplevel check.
# `gh` is a local fake (diffs from the sandbox repo) that logs every call.
set -uo pipefail

REPO=$(cd "$(dirname "$0")/../.." && pwd -P)
SRC=${SRC:-$REPO}
T=$(mktemp -d "${TMPDIR:-/var/tmp}/markus-release-test.XXXXXX")
trap 'rm -rf "$T"' EXIT
GIT_CEILING_DIRECTORIES=$(dirname "$T")
GIT_CONFIG_GLOBAL="$T/gitconfig"
GIT_CONFIG_NOSYSTEM=1
GH_LOG="$T/gh.log"
PATH="$T/bin:$PATH"
export GIT_CEILING_DIRECTORIES GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM GH_LOG PATH
git config --global user.name test
git config --global user.email test@example.com
git config --global init.defaultBranch master
git config --global advice.detachedHead false

PASSES=0
FAILURES=0
ok() { PASSES=$((PASSES + 1)); echo "  ok   $1"; }
bad() { FAILURES=$((FAILURES + 1)); echo "  FAIL $1"; echo "$OUT" | sed 's/^/       | /'; }
expect() { # <name> <condition...>
  local name=$1; shift
  if "$@"; then ok "$name"; else bad "$name"; fi
}
has() { grep -qF -- "$1" <<< "$OUT"; }
lacks() { ! has "$1"; }
rc_is() { [ "$RC" -eq "$1" ]; }
no_gh() { [ ! -s "$GH_LOG" ]; }

# Runs git only inside the current sandbox repo.
g() {
  [ "$(git rev-parse --show-toplevel 2>/dev/null)" = "$(cd "$R" && pwd -P)" ] \
    || { echo "SANDBOX ESCAPE: refusing git $* outside $R"; exit 99; }
  git "$@"
}

mkdir -p "$T/bin"
cat > "$T/bin/gh" << 'EOF'
#!/bin/bash
# Fake `gh pr diff <n> [--repo R] [--name-only]`, answered from $PR_MAP.
echo "$*" >> "$GH_LOG"
[ "$1 $2" = "pr diff" ] || exit 98
SHA=$(awk -v n="$3" '$1 == n { print $2 }' "$PR_MAP")
if [[ " $* " == *" --name-only "* ]]; then git diff --name-only "$SHA^1" "$SHA"; else git diff "$SHA^1" "$SHA"; fi
EOF
chmod +x "$T/bin/gh"

# New sandbox repo: base commit (with the release scripts, like the release branch),
# a `release` branch with origin/release on it, and master checked out.
new_repo() {
  R="$T/$1"
  PR_MAP="$R.prmap"; export PR_MAP
  : > "$PR_MAP"; : > "$GH_LOG"
  mkdir -p "$R" && cd "$R" || exit 99
  git init -q
  g rev-parse --show-toplevel > /dev/null
  mkdir -p release
  cp "$SRC/release/cherry-pick.sh" "$SRC/release/verify.rb" release/
  cp "$REPO/release/common.rb" "$REPO/release/lockres.rb" "$REPO/release/recon-format.rb" release/
  echo "puts File.read(ENV.fetch('FAKE_RECON'))" > release/recon.rb
  printf 'A = 1\nB = 1\nC = 1\nD = 1\nE = 1\n' > code.rb
  printf 's1\ns2\ns3\ns4\ns5\n' > spec.rb
  printf '# Changelog\n## [unreleased]\n\n## [v1.0.0]\n- Old (#1)\n' > Changelog.md
  printf 'GEM\n  specs:\n    jwt (2.9.0)\n    rack (3.0.0)\n' > Gemfile.lock
  g add -A && g commit -qm base
  g branch release
  g update-ref refs/remotes/origin/release release
}

# Commits a change on <branch>; <edit> is a shell snippet run in the repo.
commit_on() { # <branch> <subject> <edit>
  g checkout -q "$1" && eval "$3" && g add -A && g commit -qm "$2"
  [ "$1" = release ] && g update-ref refs/remotes/origin/release release
  return 0
}

# A squash-merged PR on master; records "<n> <sha>" in PR_MAP and prints the sha.
pr() { # <n> <edit> [<title>]
  commit_on master "${3:-PR $1} (#$1)" "$2" > /dev/null
  local sha; sha=$(git rev-parse HEAD)
  echo "$1 $sha" >> "$PR_MAP"
  echo "$sha"
}

work_branch() { g checkout -q -B v9.9.9 release; }

# Whole-line replacement in <file>, and a new line under "## [unreleased]".
subst() { FROM="$2" TO="$3" ruby -i -pe '$_ = ENV["TO"] + "\n" if $_.chomp == ENV["FROM"]' "$1"; }
add_log() { LOG="$1" ruby -i -pe '$_ += "- #{ENV["LOG"]}\n" if $_.start_with?("## [unreleased]")' Changelog.md; }

# Fake recon JSON for release/cherry-pick.sh from "<n>:<sha>" pairs.
recon() {
  local order="" prs="" i=0 p
  for p in "$@"; do
    i=$((i + 1))
    order+="${order:+,}{\"order\":$i,\"number\":${p%%:*},\"ref\":\"${p##*:}\"}"
    prs+="${prs:+,}{\"number\":${p%%:*},\"title\":\"PR ${p%%:*}\",\"dependencies\":[]}"
  done
  FAKE_RECON="$R.recon.json"; export FAKE_RECON
  printf '{"version":"v9.9.9","milestone_prs":[%s],"proposed_cherry_pick_order":[%s],"skipped":[],"migrations":[],"dependency_changes":{"summary":"","settings":""}}' \
    "$prs" "$order" > "$FAKE_RECON"
}

run() { OUT=$("$@" 2>&1); RC=$?; }
cp_sh() { run bash release/cherry-pick.sh v9.9.9 "$@"; }

# A code conflict: the PR edits line A, release edits the adjacent line B.
conflict_setup() { # <n> [<title>]; sets S
  commit_on release "release B" "subst code.rb 'B = 1' 'B = 10'"
  S=$(pr "$1" "subst code.rb 'A = 1' 'A = 2'" "${2:-}")
}
RESOLVED='A = 2\nB = 10\nC = 1\nD = 1\nE = 1\n'

echo "verify.rb"

new_repo verify_pass
S1=$(pr 11 "printf 'x\n' >> spec.rb && printf 'N\n' > new.rb")
work_branch && g cherry-pick "$S1" > /dev/null
run ruby release/verify.rb 11 "$S1"
expect "identical pick passes" eval 'rc_is 0 && has "PASS  PR #11"'
expect "local git only" no_gh
run ruby release/verify.rb 11
expect "usage error without a sha" eval 'rc_is 2 && has "Usage: ruby release/verify.rb <pr_number> <merge_sha>"'

new_repo verify_contaminated
S1=$(pr 12 "printf 's6\n' >> spec.rb")
work_branch && commit_on v9.9.9 "PR 12 (#12)" "printf 's6\nFROM_OTHER_PR\n' >> spec.rb"
run ruby release/verify.rb 12 "$S1"
expect "in-file contamination fails" eval 'rc_is 1 && has "spec.rb (line mismatch)"'
commit_on v9.9.9 "extra" "printf 'x\n' > extra.rb && printf 'x\n' >> code.rb"
run ruby release/verify.rb 12 "$S1"
expect "extra file fails" eval 'rc_is 1 && has "extra.rb (extra)"'
commit_on v9.9.9 "PR 12 (#12)" "printf 's6\n' >> spec.rb && printf '\\000\\001' > blob.bin"
run ruby release/verify.rb 12 "$S1"
expect "extra binary file fails" eval 'rc_is 1 && has "blob.bin (extra)"'

new_repo verify_exact_path
S1=$(pr 13 "mkdir -p b && printf 'one\n' > b/c.rb && printf 'two\n' > c.rb")
work_branch && g cherry-pick "$S1" > /dev/null
run ruby release/verify.rb 13 0000000000000000000000000000000000000000
expect "gh fallback matches exact paths" eval 'rc_is 0 && has "missing locally" && has "PASS  PR #13"'

new_repo verify_lock_extra
S1=$(pr 14 "subst Gemfile.lock '    jwt (2.9.0)' '    jwt (2.10.1)'")
work_branch && commit_on v9.9.9 "PR 14 (#14)" \
  "subst Gemfile.lock '    jwt (2.9.0)' '    jwt (2.10.1)' && printf '    evil (1.0)\n' >> Gemfile.lock"
run ruby release/verify.rb 14 "$S1"
expect "lockfile line for another package fails" eval 'rc_is 1 && has "Gemfile.lock (line mismatch)"'

new_repo verify_binary
S1=$(pr 15 "printf 'A\\000' > logo.bin")
work_branch && g cherry-pick "$S1" > /dev/null
run ruby release/verify.rb 15 "$S1"
expect "identical binary pick passes" eval 'rc_is 0 && has "PASS  PR #15"'
g reset -q --hard HEAD~1 && commit_on v9.9.9 "PR 15 (#15)" "printf 'B\\000' > logo.bin"
run ruby release/verify.rb 15 "$S1"
expect "binary content mismatch fails" eval 'rc_is 1 && has "logo.bin (line mismatch)"'

echo "release/cherry-pick.sh"

new_repo cp_happy
S1=$(pr 21 "printf 'x\n' >> spec.rb")
S2=$(pr 22 "printf 'y\n' > y.rb")
work_branch && recon "21:$S1" "22:$S2"
cp_sh
expect "picks and verifies every PR" eval 'rc_is 0 && has "#21 verified clean" && has "#22 verified clean" && has "Picked:  21,22"'
expect "no gh calls" no_gh
# shellcheck disable=SC2034 # read inside the eval below
H=$(cd release && pwd)
expect "next steps use this copy and pass --prs" \
  eval 'has "ruby $H/changelog.rb --mode=release --version=v9.9.9 --prs=21,22" && has "bash $H/validate_changelog.sh v9.9.9 --prs 21,22"'

new_repo cp_empty
work_branch && recon
cp_sh
expect "empty order says so and stops" eval 'rc_is 0 && has "No PRs to cherry-pick for v9.9.9" && lacks "Cherry-picking #"'

new_repo cp_bad_sha
work_branch && recon "23:deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
cp_sh
expect "non-conflict failure prints git output" \
  eval 'rc_is 1 && has "failed without a conflict" && has "deadbeef" && has "fatal: bad object deadbeef"'

new_repo cp_hook
commit_on release "release log" "add_log 'Release fix (#100)'"
S1=$(pr 24 "add_log 'Feature (#24)' && printf 'X = 2\n' > other.rb")
work_branch && recon "24:$S1"
printf '#!/bin/sh\necho "hook says no"\nexit 1\n' > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
cp_sh
expect "hook failure on --continue stops, not skipped" \
  eval 'rc_is 1 && has "Commit of #24 failed" && has "hook says no" && lacks "Skipped: 24"'
expect "PR change still staged after F2 stop" eval 'git diff --cached --name-only | grep -qx other.rb'

new_repo cp_already_applied
commit_on release "release has it" "printf 'x\n' >> spec.rb"
S1=$(pr 31 "printf 'x\n' >> spec.rb")
S2=$(pr 32 "printf 'y\n' > y.rb")
work_branch && recon "31:$S1" "32:$S2"
cp_sh
expect "empty pick is skipped" eval 'rc_is 0 && has "#31 already on release, skipped" && has "Picked:  32" && has "Skipped: 31"'

new_repo cp_already_applied_log
commit_on release "release has it" "printf 'x\n' >> spec.rb && add_log 'Release fix (#100)'"
S1=$(pr 33 "printf 'x\n' >> spec.rb && add_log 'Feature (#33)'")
work_branch && recon "33:$S1"
cp_sh
expect "pick empty after changelog auto-resolve is skipped" eval 'rc_is 0 && has "#33 already on release, skipped"'

new_repo cp_empty_title_log
commit_on release "release log" "add_log 'Release fix (#100)'"
S1=$(pr 61 "add_log 'Assign zeros (#61)' && printf 'Z\n' > zeros.rb" "Assign zeros to empty submissions")
work_branch && recon "61:$S1"
cp_sh
expect "changelog conflict on an 'empty' title is picked" \
  eval 'rc_is 0 && has "#61 auto-resolved" && has "Picked:  61" && lacks "Skipped"'

new_repo cp_empty_title_code
conflict_setup 62 "Fix empty state crash"
work_branch && recon "62:$S"
cp_sh
expect "code conflict on an 'empty' title stops" eval 'rc_is 1 && has "Code conflict in #62" && lacks "Skipped"'

new_repo cp_lock
commit_on release "release jwt" "subst Gemfile.lock '    jwt (2.9.0)' '    jwt (3.2.0)'"
S1=$(pr 25 "subst Gemfile.lock '    jwt (2.9.0)' '    jwt (2.10.1)' && printf 'L\n' > lock_user.rb")
work_branch && recon "25:$S1"
cp_sh
expect "lockfile resolution passes with WARN" \
  eval 'rc_is 0 && has "jwt 3.2.0 | 2.10.1 -> 3.2.0" && has "WARN  PR #25 — Gemfile.lock" && has "Picked:  25"'

new_repo cp_resume
conflict_setup 26
S2=$(pr 27 "printf 'y\n' > y.rb")
work_branch && recon "26:$S" "27:$S2"
cp_sh
expect "code conflict stops" eval 'rc_is 1 && has "Code conflict in #26" && has "--resume --skip 26"'
cp_sh --resume
expect "rerun mid-pick refuses" eval 'rc_is 1 && has "A cherry-pick is in progress"'
printf "$RESOLVED" > code.rb && g add code.rb && GIT_EDITOR=true g cherry-pick --continue > /dev/null
cp_sh --resume
expect "resume verifies a clean hand-resolved pick" \
  eval 'rc_is 0 && has "#26 already picked" && has "#26 verified clean" && has "Picked:  26,27"'

new_repo cp_resume_bad
conflict_setup 28
work_branch && recon "28:$S"
cp_sh
printf "${RESOLVED}EVIL = 1\n" > code.rb && g add code.rb && GIT_EDITOR=true g cherry-pick --continue > /dev/null
cp_sh --resume
expect "resume catches a contaminated hand-resolved pick" \
  eval 'rc_is 1 && has "#28 already picked" && has "Contamination detected in #28"'
cp_sh --resume --accept 28
expect "--accept keeps a reviewed pick" eval 'rc_is 0 && has "accepted with --accept" && has "Picked:  28"'

new_repo cp_skip
conflict_setup 29
S2=$(pr 30 "printf 'y\n' > y.rb")
work_branch && recon "29:$S" "30:$S2"
cp_sh
g cherry-pick --abort
cp_sh --resume --skip 29
expect "--skip leaves the PR out and continues" \
  eval 'rc_is 0 && has "#29 skipped with --skip" && has "Picked:  30" && has "Skipped: 29"'
expect "skipped PR absent from branch" eval '! git log --format=%s | grep -q "(#29)"'

new_repo cp_skip_alone
S1=$(pr 81 "printf 'y\n' > y.rb")
conflict_setup 82
work_branch && recon "81:$S1" "82:$S"
cp_sh
g cherry-pick --abort
cp_sh --skip 82
expect "--skip without --resume keeps earlier picks" \
  eval 'rc_is 0 && has "#81 already picked" && has "Picked:  81" && has "Skipped: 82"'

new_repo cp_accept_alone
S1=$(pr 83 "printf 'y\n' > y.rb")
conflict_setup 84
work_branch && recon "83:$S1" "84:$S"
cp_sh
printf "${RESOLVED}EVIL = 1\n" > code.rb && g add code.rb && GIT_EDITOR=true g cherry-pick --continue > /dev/null
cp_sh --accept 84
expect "--accept without --resume keeps earlier picks" \
  eval 'rc_is 0 && has "#83 already picked" && has "accepted with --accept" && has "Picked:  83,84"'

echo ""
echo "$PASSES passed, $FAILURES failed"
[ "$FAILURES" -eq 0 ]
