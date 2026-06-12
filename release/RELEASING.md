# Releasing MarkUs

Step-by-step guide for cutting a MarkUs minor release. Helper scripts in this directory automate the tedious parts — each step shows the manual command and the script alternative.

## Prerequisites

- `gh` CLI authenticated (`gh auth status`)
- Docker running (`docker compose up`)
- A GitHub milestone exists for the target version with all relevant PRs merged and tagged
- Clean working tree

## Phase 1: Setup

```bash
git fetch origin
git checkout release && git pull origin release
git checkout -b v2.X.Y   # branch from release, not master
```

**Verify:** `git log --oneline -1` matches the latest release branch commit.

## Phase 2: Recon — discover what to cherry-pick

```bash
RECON=$(ruby release/recon.rb v2.X.Y)
echo "$RECON" | ruby release/recon-format.rb --summary
echo "$RECON" | ruby release/recon-format.rb --plan
```

This queries the milestone, checks which PRs are already on the release branch, resolves file-overlap dependencies, and outputs a JSON plan. The `$RECON` variable is reused in later phases (release notes, PR body).

Review the plan. Note any non-PR commits (direct pushes, fork merges) — decide whether to include or skip.

## Phase 3: Cherry-pick

**Automated (recommended):**

```bash
release/cherry-pick.sh v2.X.Y
```

This cherry-picks all milestone PRs in dependency order, auto-resolves Changelog conflicts, skips empty commits, and verifies each pick for contamination. It stops on code conflicts or contamination and tells you exactly what to do.

After fixing a problem, resume from where it stopped:
```bash
release/cherry-pick.sh v2.X.Y --resume
```

At the end it prints the PR list and the `changelog.rb` command to run next.

<details>
<summary>Manual alternative</summary>

For each PR in the order from recon:

```bash
git cherry-pick -m1 <merge_commit_hash>
ruby release/verify.rb <PR_NUMBER>
```

Conflict handling:
- **Changelog.md only:** `git checkout --ours Changelog.md && git add Changelog.md && GIT_EDITOR=true git cherry-pick --continue`
- **Code files:** Stop. Resolve by comparing against `gh pr diff <N>`.
- **Empty commit:** Already on release. `git cherry-pick --skip`.
</details>

## Phase 4: Rebuild the Changelog

The Changelog is always corrupted after cherry-picks. Rebuild it:

```bash
ruby release/changelog.rb --mode=release --version=v2.X.Y --prs=7783,7851,7858
```

Pass the comma-separated list of cherry-picked PR numbers. The script reads `origin/release` and `origin/master`, filters master's unreleased entries to only the included PRs, and outputs a clean Changelog.

```bash
ruby release/changelog.rb --mode=release --version=v2.X.Y --prs=<PR_LIST> > Changelog.md
```

**Validate:**
```bash
bash release/validate_changelog.sh v2.X.Y
```

All 6 checks should pass: no conflict markers, empty unreleased, version section exists with entries, correct ordering, no duplicate PRs, older sections unchanged.

## Phase 5: Version bump and commit

```bash
echo "VERSION=v2.X.Y,PATCH_LEVEL=DEV" > app/MARKUS_VERSION
git add Changelog.md app/MARKUS_VERSION
git commit -m "v2.X.Y"
```

`PATCH_LEVEL=DEV` is a legacy field — always keep it as-is.

## Phase 6: Test

```bash
docker compose exec rails bundle exec rspec
docker compose exec rails npx jest --no-coverage
```

Pre-existing failures on the release branch are expected. Verify no NEW failures were introduced by the cherry-picks.

## Phase 7: Dependency and settings check

```bash
git diff origin/release -- Gemfile Gemfile.lock package.json package-lock.json
git diff origin/release -- markus.control config/settings.yml
git diff origin/release --name-only -- db/migrate/
```

If any of these show changes, notify sysadmins before deployment. They may need to `bundle install`, `npm install`, apply new settings to `settings.local.yml`, or run migrations.

## Phase 8: Push and PR

```bash
git push -u origin v2.X.Y
gh pr create --base release --title "v2.X.Y" --body "Release v2.X.Y"
```

Wait for CI. Get reviewer approval. **Merge with "Create a merge commit"** (never squash into release).

## Phase 9: GitHub Release

After the PR is merged:

```bash
# Re-run if your shell session expired since Phase 2
RECON=$(ruby release/recon.rb v2.X.Y)
gh release create v2.X.Y --repo MarkUsProject/Markus --target release --title "v2.X.Y" --notes "$(echo "$RECON" | ruby release/recon-format.rb --release-notes)"
```

Or create manually via GitHub UI: Releases > Create > tag `v2.X.Y`, target `release`.

## Phase 10: Milestone management

```bash
# Close released milestone
MILESTONE_ID=$(gh api repos/MarkUsProject/Markus/milestones --jq ".[] | select(.title==\"v2.X.Y\") | .number")
gh api -X PATCH "repos/MarkUsProject/Markus/milestones/$MILESTONE_ID" -f state=closed

# Create next milestone
gh api repos/MarkUsProject/Markus/milestones -f title="v2.X.Z"
```

## Phase 11: Sync Changelog to master

Move released entries from `[unreleased]` into a new version section on master:

```bash
git checkout master && git pull origin master
git checkout -b v2.X.Y-changelog

ruby release/changelog.rb --mode=master-sync --version=v2.X.Y --prs=<PR_LIST> > Changelog.md
bash release/validate_changelog_master.sh v2.X.Y

git add Changelog.md
git commit -m "Update changelog with new release v2.X.Y [ci skip]"
git push -u origin v2.X.Y-changelog
gh pr create --base master --title "Update changelog for v2.X.Y" --body "Sync released entries."
```

Squash-merge is fine here (same branch lineage, `[ci skip]` skips CI).

## Phase 12: Satellite repos (Wiki, Autotester)

Check each repo's milestone for PRs. If any exist, follow the same cherry-pick + PR + release flow. If none, still create a GitHub release with the version tag.

## Phase 13: Cleanup

Delete version branches:
```bash
git push origin --delete v2.X.Y v2.X.Y-changelog
git branch -d v2.X.Y v2.X.Y-changelog
```

---

## Helper Scripts Reference

| Script | What it does |
|--------|-------------|
| `cherry-pick.sh <version>` | Automated cherry-pick loop with verification. `--resume` to continue after fixing a conflict |
| `recon.rb <version>` | Queries milestone, resolves cherry-pick order, outputs JSON |
| `recon-format.rb --flag` | Formats recon JSON (pipe from stdin). Flags: `--summary`, `--plan`, `--order`, `--pr-list`, `--pr-body`, `--release-notes`, `--skipped` |
| `verify.rb <pr_number>` | Compares last cherry-pick diff against original PR. Exit 0 = clean, 1 = contaminated |
| `changelog.rb --mode=MODE --version=V --prs=N,N` | Rebuilds Changelog. Modes: `release` (for release branch), `master-sync` (for master) |
| `validate_changelog.sh <version>` | 6-check validation for release branch changelog |
| `validate_changelog_master.sh <version>` | 5-check validation for master changelog sync |

All scripts accept `--help` for usage details.

---

## Pitfalls

| Problem | Solution |
|---------|----------|
| Changelog corrupted after cherry-picks | Always rebuild with `changelog.rb`. Never trust the auto-merged result. |
| Cherry-pick pulls in extra code | Git 3-way merge can import dependency PR code. Always run `verify.rb` after each pick. |
| Empty cherry-pick commit | PR was in a prior release. Check changelog, `git cherry-pick --skip`. |
| `PATCH_LEVEL=RELEASE` | Wrong. Always `PATCH_LEVEL=DEV`. Legacy field, unused at runtime. |
| API returns 404 | Include `/csc108` prefix. Use `MarkUsAuth` not `Bearer`. |
| Jest flag | `--testPathPatterns` (plural), not singular. |
| Rails runner `!` escaping | Pipe via stdin: `echo '...' | docker compose exec -T rails bundle exec rails runner -` |
| Squash-merge into release | Never. Use "Create a merge commit" to preserve commit history. |
| Copying release Changelog to master | Never overwrite. Use `--mode=master-sync` to move entries from unreleased. |
