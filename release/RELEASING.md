# Releasing MarkUs

Step-by-step guide for cutting a MarkUs minor release. Scripts in this folder automate the slow parts. Each step shows the manual command plus the script that does it for you.

## Prerequisites

- The `gh` CLI is logged in (`gh auth status`)
- Docker running (`docker compose up`)
- A GitHub milestone exists for the target version. All its PRs are merged.
- Clean working tree

## Phase 1: Setup

```bash
git fetch origin
git checkout release && git pull origin release
git checkout -b v2.X.Y   # branch from release, not master
```

**Verify:** `git log --oneline -1` matches the latest release branch commit.

## Phase 2: Recon, discover what to cherry-pick

```bash
RECON=$(ruby release/recon.rb v2.X.Y)
echo "$RECON" | ruby release/recon-format.rb --summary
echo "$RECON" | ruby release/recon-format.rb --plan
```

This queries the milestone. It flags PRs that already shipped. It resolves file-overlap order. It prints a JSON plan. Later phases reuse `$RECON` for release notes plus the PR body.

Review the plan. Check any non-PR commits (direct pushes, fork merges). Decide: include or skip.

## Phase 3: Cherry-pick

**Automated (recommended):**

```bash
release/cherry-pick.sh v2.X.Y
```

This picks every milestone PR in dependency order. It auto-resolves `Changelog.md` plus lockfile conflicts. It skips empty commits. It verifies each pick against the PR's file list. On a code conflict it stops, and it tells you what to do.

After fixing a problem, resume from where it stopped:
```bash
release/cherry-pick.sh v2.X.Y --resume
```

At the end it prints the PR list and the `changelog.rb` command to run next.

### Manual alternative

For each PR in the order from recon:

```bash
git cherry-pick -m1 <merge_commit_hash>
ruby release/verify.rb <PR_NUMBER>
```

Conflict handling:
- **`Changelog.md` alone:** `git checkout --ours Changelog.md && git add Changelog.md && GIT_EDITOR=true git cherry-pick --continue`
- **Code files:** Stop. Resolve by comparing against `gh pr diff <N>`.
- **Empty commit:** Already on release. `git cherry-pick --skip`.

## Phase 4: Rebuild the Changelog

Cherry-picks always corrupt `Changelog.md`. Rebuild it:

```bash
ruby release/changelog.rb --mode=release --version=v2.X.Y --prs=7783,7851,7858
```

Pass the picked PR numbers, comma-separated. The script reads `origin/release` plus `origin/master`. It keeps the unreleased entries whose PRs you picked, plus the old sections. It prints a clean `Changelog.md`.

```bash
ruby release/changelog.rb --mode=release --version=v2.X.Y --prs=<PR_LIST> > Changelog.md
```

**Validate:**
```bash
bash release/validate_changelog.sh v2.X.Y
```

All 6 checks must pass: zero conflict markers, empty unreleased, a filled version section, correct order, zero duplicate PRs, older sections intact.

## Phase 5: Version bump and commit

```bash
echo "VERSION=v2.X.Y,PATCH_LEVEL=DEV" > app/MARKUS_VERSION
git add Changelog.md app/MARKUS_VERSION
git commit -m "v2.X.Y"
```

`PATCH_LEVEL=DEV` is a legacy field. Keep it as is, always.

## Phase 6: Test

```bash
docker compose exec rails bundle exec rspec
docker compose exec rails npx jest --no-coverage
```

The release branch has known failures. Your job: confirm the cherry-picks added zero NEW ones.

Before blaming the release, rule out the environment. Rerun the failing spec
file alone. Rerun it with suspect env vars cleared (the dev container sets
`MARKUS_URL`, which the autotest job specs read). A pass in isolation points at
the environment or test order. A fail either way is a real regression.

## Phase 7: Dependency and settings check

```bash
git diff origin/release -- Gemfile Gemfile.lock package.json package-lock.json
git diff origin/release -- markus.control config/settings.yml config/settings/production.yml
git diff origin/release -- requirements-jupyter.txt Dockerfile
git diff origin/release --name-only -- db/migrate/
```

A `requirements-jupyter.txt` change can alter deploy steps too. In v2.10.2 the
playwright bump required `playwright install chromium` plus
`playwright install-deps` on the server.

When any of these show changes, tell the sysadmins before deploy. Their steps: `bundle install`, `npm install`, new settings in `settings.local.yml`, or migrations.

## Phase 8: Push and PR

```bash
git push -u origin v2.X.Y
gh pr create --base release --title "v2.X.Y" --body "Release v2.X.Y"
```

Wait for CI. Get reviewer approval. Ask for **"Create a merge commit"**. Recent releases were squash-merged in practice. That is why recon finds shipped PRs via the changelog, never via ancestry.

## Phase 9: GitHub Release

After the PR is merged:

```bash
# Re-run if your shell session expired since Phase 2
RECON=$(ruby release/recon.rb v2.X.Y)
gh release create v2.X.Y --repo MarkUsProject/Markus --target release --title "v2.X.Y" --notes "$(echo "$RECON" | ruby release/recon-format.rb --release-notes)"
```

Or create it in the GitHub UI: Releases > Create > tag `v2.X.Y`, target `release`.

## Phase 10: Milestone management

```bash
# Close released milestone
MILESTONE_ID=$(gh api repos/MarkUsProject/Markus/milestones --jq ".[] | select(.title==\"v2.X.Y\") | .number")
gh api -X PATCH "repos/MarkUsProject/Markus/milestones/$MILESTONE_ID" -f state=closed

# Create next milestone
gh api repos/MarkUsProject/Markus/milestones -f title="v2.X.Z"
```

## Phase 11: Sync Changelog to master

Move the released entries out of `[unreleased]` into a new version section on master:

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

Squash-merge works here (same branch lineage; `[ci skip]` skips CI).

## Phase 12: Satellite repos

Check the markus-autotesting milestone for PRs. When PRs exist, follow the same
cherry-pick, PR, release flow. When zero exist, skip the release. The autotester
releases on its own pace (it skipped v2.10.1 plus v2.10.2). Master sitting ahead
of release there is normal future-milestone work.

The Wiki is retired. Docs moved into this repo in v2.10.2 (#8022). MarkUs links
point at the docs site (#8049). Skip it until a milestone PR appears there again.

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

Every script prints usage with `--help`.

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
