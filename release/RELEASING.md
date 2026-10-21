# Releasing MarkUs

This guide cuts a MarkUs minor release, step by step. The scripts in this folder do the slow parts. Each step shows the command to run.

## Before you start

- `gh auth status` shows your GitHub login.
- `docker compose up` is running.
- A GitHub milestone exists for the new version.
- Every PR in that milestone has merged.
- `git status` shows a clean tree.

## Phase 1: Setup

### Copy the release tools

The version branch starts from `release`. Its copy of `release/` can be older than the copy on master. Copy the current tools to a folder outside the repo, and run them from there.

```bash
git fetch origin
T=$HOME/markus-release-tools/v2.X.Y && mkdir -p "$T"
export RELEASE_TOOLS=$T/release
```

Copy `release/` into `$T` from one of these places:

| Where the tools are | Command |
|---|---|
| Merged to master | `git archive origin/master release \| tar -x -C "$T"` |
| On a branch, not merged yet | `git archive origin/<branch> release \| tar -x -C "$T"` |
| A working tree, with files not yet committed | `cp -R /path/to/worktree/release "$T/"` |

`git archive` copies committed files alone. The copy must hold `changelog_duplicate_headers.txt`. Without it, the changelog check fails on three old repeated headers.

Check the copy before you go on:

```bash
ruby "$RELEASE_TOOLS/recon.rb" --help 2>&1 | grep -q MIGRATIONS \
  && ruby "$RELEASE_TOOLS/verify.rb" --help 2>&1 | grep -q '<merge_sha>' \
  && test -f "$RELEASE_TOOLS/changelog_duplicate_headers.txt" \
  && echo "release tools OK" || echo "STOP: $RELEASE_TOOLS is an older copy of release/"
```

Every later command uses `$RELEASE_TOOLS`. In a new shell, set it again:

```bash
export RELEASE_TOOLS=$HOME/markus-release-tools/v2.X.Y/release
```

`cherry-pick.sh` runs the `recon.rb` and `verify.rb` that sit in its own folder.

### Create the version branch

Branch from `release`, not from master:

```bash
git checkout release && git pull origin release
git checkout -b v2.X.Y
```

**Check:** `git log --oneline -1` shows the newest commit on `release`.

## Phase 2: Find the PRs to pick

```bash
RECON=$(ruby "$RELEASE_TOOLS/recon.rb" v2.X.Y)
echo "$RECON" | ruby "$RELEASE_TOOLS/recon-format.rb" --summary
echo "$RECON" | ruby "$RELEASE_TOOLS/recon-format.rb" --plan
```

`recon.rb` reads the milestone. It sorts the PRs to pick by merge date.

It skips each PR that already shipped. A PR counts as shipped when one of these names it:

- the changelog on `release`
- a release commit on `release`

That second source catches dependabot PRs, which get no changelog line. The summary lists them under `Skipped:`.

The summary also flags what the sysadmins must act on at deploy, for the PRs you pick:

| Line | What changed |
|---|---|
| `Dependency changes:` | gems, JS packages, Python packages, or system files |
| `Settings changes:` | a settings file or `config/application.rb` |
| `SCHEDULER:` | a job in a `resque_scheduler` block |
| `MIGRATIONS:` | a file under `db/migrate/` |

Later phases use `$RECON` again for the release notes and the PR body.

Read the plan. Check each commit with no PR, such as a direct push or a fork merge. Decide to include it or skip it.

## Phase 3: Cherry-pick

### With the script

```bash
bash "$RELEASE_TOOLS/cherry-pick.sh" v2.X.Y
```

`cherry-pick.sh` picks each PR in order. For each one, it:

1. Runs `git cherry-pick -m1`.
2. Resolves a conflict in `Changelog.md` with the release copy.
3. Resolves a lockfile conflict with `lockres.rb`, which keeps the higher version.
4. Skips the PR when the pick has nothing to commit, since `release` already has it.
5. Runs `verify.rb`, which compares each file line by line with the PR's own diff.

A lockfile version line that differs after step 3 prints `WARN`. Every other difference stops the run.

The run also stops on a code conflict or a failed commit. It prints the cause and the next command.

After you fix the cause, pick up where it stopped:

```bash
bash "$RELEASE_TOOLS/cherry-pick.sh" v2.X.Y --resume
bash "$RELEASE_TOOLS/cherry-pick.sh" v2.X.Y --accept <PR>   # keep a pick you reviewed
bash "$RELEASE_TOOLS/cherry-pick.sh" v2.X.Y --skip <PR>     # leave a PR out
```

`--resume` checks each pick already on the branch with `verify.rb`, including picks you finished by hand. `--accept` and `--skip` turn on `--resume`.

At the end, the script prints the picked PRs and the `changelog.rb` command to run next.

### By hand

For each PR, in the order from Phase 2:

```bash
git cherry-pick -m1 <merge_commit_hash>
ruby "$RELEASE_TOOLS/verify.rb" <PR_NUMBER> <merge_commit_hash>
```

| Conflict | What to do |
|---|---|
| `Changelog.md` alone | `git checkout --ours Changelog.md && git add Changelog.md && GIT_EDITOR=true git cherry-pick --continue` |
| Code files | Stop. Compare with `gh pr diff <N>` and resolve by hand. |
| Nothing to commit | `release` has the PR already. Run `git cherry-pick --skip`. |

## Phase 4: Rebuild the changelog

Cherry-picks leave `Changelog.md` broken. Rebuild it with `changelog.rb`.

- `--prs` lists the picked PRs, such as `--prs=7783,7851,7858`.
- `--bots` lists the dependabot PRs among them.

```bash
ruby "$RELEASE_TOOLS/changelog.rb" --mode=release --version=v2.X.Y --prs=<PR_LIST> --bots=<DEPENDABOT_PR_LIST> > Changelog.md
```

`changelog.rb` reads `Changelog.md` from `origin/release` and `origin/master`. It moves the entries of the picked PRs into the new version section. It keeps the old sections as they are. A second run gives the same file.

Then check it:

```bash
bash "$RELEASE_TOOLS/validate_changelog.sh" v2.X.Y --prs <PR_LIST> --bots <DEPENDABOT_PR_LIST>
```

It checks that:

- The file holds zero conflict markers.
- `[unreleased]` is empty.
- Each version section has entries.
- The versions run newest first.
- Each PR shows up in one version at most.
- Each version header shows up once, except the three in `changelog_duplicate_headers.txt`.
- The older sections match `origin/release`.
- Each picked PR has an entry, except bots and PRs that change `Changelog.md` alone.
- Each entry belongs to a picked PR.

Fix every `FAIL`. Read every `WARN` before you ship.

Without `--prs`, the last two checks print a `WARN` and skip. Ship after a full run with `--prs`.

## Phase 5: Bump the version and commit

```bash
echo "VERSION=v2.X.Y,PATCH_LEVEL=DEV" > app/MARKUS_VERSION
git add Changelog.md app/MARKUS_VERSION
git commit -m "v2.X.Y"
```

Keep `PATCH_LEVEL=DEV`. MarkUs ignores the field at runtime.

## Phase 6: Test

```bash
docker compose exec rails bundle exec rspec
docker compose exec rails npx jest --no-coverage
```

The release branch has some known failures. Your job is to confirm the picks add zero new ones.

Before you blame the release, rule out your setup:

1. Run the failing spec file alone.
2. Run it again with suspect env vars cleared. The dev container sets `MARKUS_URL`, which the autotest job specs read.

A pass in either run points to your setup or the test order. A fail in both is a real regression.

## Phase 7: Check deploy changes

```bash
git diff origin/release -- Gemfile Gemfile.lock package.json package-lock.json
git diff origin/release -- markus.control config/settings.yml config/settings/production.yml
git diff origin/release -- requirements-jupyter.txt .dockerfiles/Dockerfile
git diff origin/release --name-only -- db/migrate/
```

Tell the sysadmins about each change before the deploy. Their steps can include:

- `bundle install`
- `npm install`
- new keys in `settings.local.yml`
- `rails db:migrate`

A change to `requirements-jupyter.txt` can add steps too. In v2.10.2, a playwright bump meant the server also ran `playwright install chromium` and `playwright install-deps`.

### Migrations

`recon-format.rb --summary` prints a `MIGRATIONS:` line when a PR to pick adds or changes a file under `db/migrate/`. When it does:

1. Send the sysadmins a migration notice of its own, with the staging request.
2. In it, list each migration file, what it changes, and the pages that fail without it.
3. Ask them to run `bundle exec rails db:migrate` before the restart, on staging and on production.
4. Ask for the output of this check from staging. It prints nothing once every migration has run:

   ```bash
   bundle exec rails db:migrate:status | grep -w down
   ```

5. Hold production until the staging checks pass (Phase 9.1).

`markus:check` also fails when the database lacks a migration from the code.

Here is why the notice stands alone. In v2.10.5, the migration was step 5 of a 7-step notice. Production skipped it. Grading pages returned 500, and production rolled back the same day.

## Phase 8: Push and open the PR

```bash
git push -u origin v2.X.Y
gh pr create --base release --title "v2.X.Y" --body "Release v2.X.Y"
```

Wait for CI. Get a reviewer to approve.

Release PRs are squash-merged, as every release has been since v2.10.1. A squash commit loses the PR history, so `recon.rb` finds shipped PRs through the changelog and the release commit bodies.

## Phase 9: GitHub release

After the PR merges:

```bash
# In a new shell, set RELEASE_TOOLS first (Phase 1)
RECON=$(ruby "$RELEASE_TOOLS/recon.rb" v2.X.Y)
gh release create v2.X.Y --repo MarkUsProject/Markus --target release --title "v2.X.Y" --notes "$(echo "$RECON" | ruby "$RELEASE_TOOLS/recon-format.rb" --release-notes)"
```

You can also use the GitHub site: Releases, then Create, with tag `v2.X.Y` and target `release`.

### 9.1 Staging checks on ben

Test the release on the ben staging server before the production deploy:

1. The sysadmin confirms each deploy step.
2. For a migration release, the sysadmin sends the `db:migrate:status` output.
3. Open each page that reads a migrated table.
4. Look for 500s in the browser's Network tab.
5. Look for NaN or blank values on the page.
6. Run the main flows: the instructor grading page, the TA grading page, a student results view, and one submission collection.
7. Run the staging items from the release testing checklist.
8. Send the sysadmins a clear OK for production.

## Phase 10: Milestones

```bash
# Close the released milestone
MILESTONE_ID=$(gh api repos/MarkUsProject/Markus/milestones --jq ".[] | select(.title==\"v2.X.Y\") | .number")
gh api -X PATCH "repos/MarkUsProject/Markus/milestones/$MILESTONE_ID" -f state=closed

# Create the next milestone
gh api repos/MarkUsProject/Markus/milestones -f title="v2.X.Z"
```

## Phase 11: Sync the changelog to master

Move the released entries out of `[unreleased]` into a new version section on master:

```bash
git checkout master && git pull origin master
git checkout -b v2.X.Y-changelog

ruby "$RELEASE_TOOLS/changelog.rb" --mode=master-sync --version=v2.X.Y --prs=<PR_LIST> --bots=<DEPENDABOT_PR_LIST> > Changelog.md
bash "$RELEASE_TOOLS/validate_changelog_master.sh" v2.X.Y --prs <PR_LIST> --bots <DEPENDABOT_PR_LIST>

git add Changelog.md
git commit -m "Update changelog with new release v2.X.Y [ci skip]"
git push -u origin v2.X.Y-changelog
gh pr create --base master --title "Update changelog for v2.X.Y" --body "Sync released entries."
```

Squash-merge this PR. `[ci skip]` skips CI.

## Phase 12: Other repos

Check the markus-autotesting milestone for PRs.

- When it has PRs, run the same cherry-pick, PR, and release steps there.
- When it has none, skip that release.

The autotester keeps its own pace. It skipped v2.10.1 and v2.10.2. Its master runs ahead of its `release` with work for later milestones.

The docs live in this repo since v2.10.2 (#8022). MarkUs links point to the docs site (#8049). Skip the old Wiki.

## Phase 13: Clean up

Delete the version branches:

```bash
git push origin --delete refs/heads/v2.X.Y refs/heads/v2.X.Y-changelog
git branch -d v2.X.Y v2.X.Y-changelog
```

The full `refs/heads/` name matters. The `v2.X.Y` tag shares the branch name, so a bare `v2.X.Y` fails.

---

## Scripts

| Script | What it does |
|---|---|
| `cherry-pick.sh <version>` | Picks each PR and checks it with `verify.rb`. Takes `--resume`, `--accept <PR>`, and `--skip <PR>`. |
| `recon.rb <version>` | Reads the milestone, skips shipped PRs, and prints the plan as JSON. |
| `recon-format.rb --flag` | Prints parts of the plan JSON from stdin. Flags: `--summary`, `--plan`, `--skipped`, `--order`, `--pr-list`, `--pr-body`, `--release-notes`. |
| `verify.rb <pr_number> <merge_sha> [<pick>]` | Compares a pick (default `HEAD`) with the PR's diff, line by line. Exit 0 is clean, 1 is a mismatch, 2 is a usage error. |
| `lockres.rb <file>` | Resolves version-line conflicts in a lockfile. The higher version wins. |
| `changelog.rb --mode=MODE --version=V --prs=N,N [--bots=N,N]` | Rebuilds `Changelog.md`. Use `release` mode on the release branch and `master-sync` mode on master. |
| `validate_changelog.sh <version> [--prs N,N] [--bots N,N]` | Checks the release branch changelog. |
| `validate_changelog_master.sh <version> [--prs N,N] [--bots N,N]` | Checks the changelog sync on master. |

Each script prints its usage with `--help`.

---

## Common problems

| Problem | Fix |
|---|---|
| `Changelog.md` is broken after the picks | Rebuild it with `changelog.rb`. Skip the merged copy git made. |
| A pick pulls in extra code | Git's 3-way merge can bring in code from another PR. Run `verify.rb` after each pick. |
| A pick has nothing to commit | The PR shipped in an earlier release. Check the changelog, then run `git cherry-pick --skip`. |
| `PATCH_LEVEL=RELEASE` | Use `PATCH_LEVEL=DEV`. |
| The API returns 404 | Add the `/csc108` prefix. Send `MarkUsAuth`, not `Bearer`. |
| Jest test filter flag | Use `--testPathPatterns`, with an `s` at the end. |
| Rails runner breaks on `!` | Pipe the script through stdin: `echo '...' \| docker compose exec -T rails bundle exec rails runner -` |
| Old tools on the version branch | Run the current copy through `$RELEASE_TOOLS`, and check it (Phase 1). |
| Master's changelog after the release | Use `--mode=master-sync`. Keep master's own `Changelog.md`, rather than copying the release one. |
