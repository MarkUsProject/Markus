#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit tests for release helper pure functions.
# Run: ruby release/test/test_helpers.rb

require 'json'
require 'open3'

RELEASE_DIR = File.expand_path('..', __dir__)
$LOAD_PATH.unshift RELEASE_DIR
require 'common'
require 'recon' # functions only; its main runs only when executed directly

# Simple test harness state.
module TestState
  @pass = 0
  @fail_count = 0
  @errors = []

  class << self
    attr_accessor :pass, :fail_count, :errors
  end
end

def assert(description, condition)
  if condition
    $stdout.puts "  \e[32mPASS\e[0m  #{description}"
    TestState.pass += 1
  else
    $stdout.puts "  \e[31mFAIL\e[0m  #{description}"
    TestState.errors << description
    TestState.fail_count += 1
  end
end

def assert_eq(description, actual, expected)
  assert(description, actual == expected)
  return if actual == expected

  $stdout.puts "         expected: #{expected.inspect}"
  $stdout.puts "         actual:   #{actual.inspect}"
end

# ============================================================================
# Helpers
# ============================================================================

def format_cmd(json, flag)
  stdout, _, status = Open3.capture3('ruby', File.join(RELEASE_DIR, 'recon-format.rb'), flag, stdin_data: json)
  [stdout.strip, status.success?]
end

def valid_version?(version)
  Open3.capture3('ruby', '-I', RELEASE_DIR, '-rcommon', '-e', 'ReleaseHelpers.validate_version!(ARGV[0])',
                 version)[2].success?
end

# ============================================================================
# Tests
# ============================================================================

# --- recon-format.rb ---

puts "\n\e[1m--- recon-format.rb ---\e[0m"

sample = JSON.generate({
  'version' => 'v2.9.6',
  'milestone_prs' => [
    { 'number' => 100, 'title' => 'Feature A', 'dependencies' => [] },
    { 'number' => 200, 'title' => 'Feature B', 'dependencies' => [100] }
  ],
  'proposed_cherry_pick_order' => [
    { 'order' => 1, 'ref' => 'aaa', 'type' => 'milestone_pr', 'number' => 100 },
    { 'order' => 2, 'ref' => 'bbb', 'type' => 'milestone_pr', 'number' => 200 }
  ],
  'skipped' => [{ 'number' => 50, 'reason' => 'Already ancestor' }],
  'migrations' => [],
  'dependency_changes' => { 'summary' => 'No dependency changes', 'settings' => 'No settings changes',
                            'scheduler' => 'No scheduler changes' }
})

out, ok = format_cmd(sample, '--pr-list')
assert('pr-list ok', ok)
assert_eq('pr-list output', out, '100,200')

out, ok = format_cmd(sample, '--order')
assert('order ok', ok)
assert_eq('order lines', out.split("\n"), ['100:aaa', '200:bbb'])

out, ok = format_cmd(sample, '--summary')
assert('summary ok', ok)
assert('summary has count', out.include?('2'))

out, ok = format_cmd(sample, '--release-notes')
assert('release-notes ok', ok)
assert('release-notes has #100', out.include?('#100'))

out, ok = format_cmd(sample, '--skipped')
assert('skipped ok', ok)
assert('skipped has #50', out.include?('#50'))

out, ok = format_cmd(sample, '--pr-body')
assert('pr-body ok', ok)
assert('pr-body has header', out.include?('Release v2.9.6'))

_, ok = format_cmd(sample, '--bogus')
assert('invalid flag rejects', !ok)

_, help_err, help_status = Open3.capture3('ruby', File.join(RELEASE_DIR, 'recon-format.rb'), '--help', stdin_data: '')
assert('--help prints usage without reading JSON', help_status.success? && help_err.include?('--release-notes'))

out, = format_cmd(sample, '--summary')
assert('summary with no migrations says none', out.include?('No migrations'))

old_recon = JSON.parse(sample).except('migrations')
_, old_err, old_status = Open3.capture3('ruby', File.join(RELEASE_DIR, 'recon-format.rb'), '--summary',
                                        stdin_data: JSON.generate(old_recon))
assert('older recon JSON without migrations is refused',
       !old_status.success? && old_err.include?('older recon.rb'))

with_migration = JSON.generate(JSON.parse(sample).merge(
                                 'migrations' => [{ 'number' => 200, 'title' => 'Feature B',
                                                    'files' => ['db/migrate/20260926233000_add_x.rb'] }]
                               ))

out, ok = format_cmd(with_migration, '--summary')
assert('summary with migration ok', ok)
assert('summary flags migration PR and file',
       out.include?('MIGRATIONS: #200 (db/migrate/20260926233000_add_x.rb)'))
assert('summary asks for staging checks on ben', out.include?('staging checks on ben'))

out, = format_cmd(with_migration, '--pr-body')
assert('pr-body lists migration', out.include?('- Migrations: MIGRATIONS: #200'))

# --- migration_changes ---

puts "\n\e[1m--- migration_changes ---\e[0m"

prs = [
  { 'number' => 1, 'title' => 'A', 'files_changed' => ['app/models/a.rb', 'db/structure.sql'] },
  { 'number' => 2, 'title' => 'B', 'files_changed' => ['db/migrate/20260101000000_add_b.rb', 'db/structure.sql'] },
  { 'number' => 3, 'title' => 'C', 'files_changed' => ['spec/db/migrate/fake.rb', 'db/migrate/README'] },
  { 'number' => 4, 'title' => 'D', 'files_changed' => [] }
]
assert_eq('only PRs with db/migrate/*.rb files',
          migration_changes(prs),
          [{ 'number' => 2, 'title' => 'B', 'files' => ['db/migrate/20260101000000_add_b.rb'] }])
assert_eq('no PRs, no migrations', migration_changes([]), [])

# --- pr_refs ---

puts "\n\e[1m--- pr_refs ---\e[0m"

assert_eq('single ref', ReleaseHelpers.pr_refs('- Fix (#100)'), [100])
assert_eq('slash pair (Changelog.md v2.x: #6276/#6277)', ReleaseHelpers.pr_refs('- Fix (#6276/#6277)'), [6276, 6277])
assert_eq('comma pair', ReleaseHelpers.pr_refs('- Fix (#1, #2)'), [1, 2])
assert_eq('three refs, validator form', ReleaseHelpers.pr_refs('- Fix (#1/#2, #3)'), [1, 2, 3])
assert_eq('bare #N outside parens ignored', ReleaseHelpers.pr_refs('Add #8150 to v2.10.3 changelog (#8167)'), [8167])
assert_eq('no refs', ReleaseHelpers.pr_refs('- Fix things'), [])

# --- changelog_shipped ---

puts "\n\e[1m--- changelog_shipped ---\e[0m"

shipped_changelog = <<~MD
  # Changelog
  See (#1) for history.

  ## [unreleased]
  - Pending on release (#300)

  ## [v2.10.5]
  ### Bug fixes
  - Fix A (#200)
  * Fix B (#201/#202)
  - A long entry that wraps
    onto a second line (#203)

  Prose mentioning (#204) is not an entry.

  ## [v2.10.4]
  - Fix A again (#200)
  - Old fix (#100)
MD
cs = changelog_shipped(shipped_changelog)
assert_eq('changelog: bullet PRs only', cs.keys.sort, [100, 200, 201, 202, 203, 300])
assert_eq('changelog: [unreleased] on release counts', cs[300]['version'], 'unreleased')
assert_eq('changelog: newest section wins', cs[200]['version'], 'v2.10.5')
assert_eq('changelog: wrapped bullet line', cs[203]['version'], 'v2.10.5')
assert_eq('changelog: evidence names the section', cs[100]['evidence'], 'Changelog.md [v2.10.4]')

# --- release_log_shipped ---

puts "\n\e[1m--- release_log_shipped ---\e[0m"

release_log = "\x1eeae8161\nv2.10.5 (#8217)\n\n* Added JWKS rotation (#8056)\n\n" \
              "* build(deps): bump redis (#8153)\n\nBumps redis.\n  - Upstream fix (#999)\n" \
              "<li>Upstream (#998)</li>\n" \
              "\x1e4fcc452\nFix production JS builds (#8162)\n\nBody text (#997)\n" \
              "\x1e8b3a14a\nV2.10.2 (#8136)\n\n* Old (#7000)\n"
ls = release_log_shipped(release_log)
assert_eq('log: subjects and * lines only', ls.keys.sort, [7000, 8056, 8136, 8153, 8162, 8217])
assert_eq('log: bot bump gets the release version', ls[8153]['version'], 'v2.10.5')
assert_eq('log: upper-case V subject', ls[7000]['version'], 'v2.10.2')
assert_eq('log: hotfix commit has no version', ls[8162]['version'], nil)
assert('log: evidence names the commit', ls[8153]['evidence'].include?('eae8161'))

revert_log = "\x1eabc1234\nv2.10.6 (#8300)\n\n* Revert \"Fix X (#8250)\" (#8260)\n* Revert rackup to v1.0.0\n" \
             "\x1edef5678\nRevert @rjsf/core to v5.18.3 (#7110)\n"
assert_eq('log: reverted PR is not shipped, the revert and a "Revert ..." title are',
          release_log_shipped(revert_log).keys.sort, [7110, 8260, 8300])

merged = shipped_prs(shipped_changelog, release_log)
assert_eq('shipped_prs: changelog evidence wins', merged[200]['evidence'], 'Changelog.md [v2.10.5]')
assert_eq('shipped_prs: union of both', merged.key?(8153) && merged.key?(300), true)

# --- skip_reason ---

puts "\n\e[1m--- skip_reason ---\e[0m"

assert_eq('skip: shipped',
          skip_reason({ 'shipped_evidence' => 'Changelog.md [v2.10.5]', 'files_changed' => ['a.rb'] }, false),
          'Shipped: Changelog.md [v2.10.5]')
assert_eq('skip: ancestor', skip_reason({ 'files_changed' => ['a.rb'] }, true), 'Already ancestor of release branch')
assert_eq('skip: Changelog.md only', skip_reason({ 'files_changed' => ['Changelog.md'] }, false),
          'Changes only Changelog.md')
assert_eq('pending: code PR', skip_reason({ 'files_changed' => ['Changelog.md', 'a.rb'] }, false), nil)

# --- build_cherry_pick_order ---

puts "\n\e[1m--- build_cherry_pick_order ---\e[0m"

# #8153 pattern: a PR with a file dependency was deferred behind every later dependency-free PR.
pending = [
  { 'number' => 3, 'mergedAt' => '2026-01-03T00:00:00Z', 'merge_commit' => 'c', 'files_changed' => ['b.rb'] },
  { 'number' => 1, 'mergedAt' => '2026-01-01T00:00:00Z', 'merge_commit' => 'a', 'files_changed' => ['a.rb'] },
  { 'number' => 2, 'mergedAt' => '2026-01-02T00:00:00Z', 'merge_commit' => 'b', 'files_changed' => ['a.rb'] },
  { 'number' => 4, 'mergedAt' => '2026-01-04T00:00:00Z', 'merge_commit' => 'd', 'files_changed' => ['Gemfile.lock'] },
  { 'number' => 5, 'mergedAt' => '2026-01-05T00:00:00Z', 'merge_commit' => 'e',
    'files_changed' => ['Gemfile.lock', 'Changelog.md'] }
]
pick_order = build_cherry_pick_order(pending)
assert_eq('order: merge-date order', pick_order.map { |o| o['number'] }, [1, 2, 3, 4, 5])
assert_eq('order: positions and refs', pick_order.map { |o| [o['order'], o['ref']] },
          [[1, 'a'], [2, 'b'], [3, 'c'], [4, 'd'], [5, 'e']])
assert_eq('order: dependency kept for information', pending.find { |p| p['number'] == 2 }['dependencies'], [1])
assert_eq('order: lockfile-only overlap is no dependency', pending.find { |p| p['number'] == 5 }['dependencies'], [])
assert_eq('order: empty input', build_cherry_pick_order([]), [])

# --- forecast_candidates ---

puts "\n\e[1m--- forecast_candidates ---\e[0m"

others = [{ 'number' => 8211, 'files' => ['a.rb'] }, { 'number' => 8204, 'files' => ['a.rb'] },
          { 'number' => 8000, 'files' => ['a.rb'] }]
subjects = "Restricted grader access (#8211)\nReplaced MarkusLogger (#8204)"
assert_eq('forecast: drops shipped and out-of-range PRs',
          forecast_candidates(others, subjects, { 8211 => {} }).map { |p| p['number'] }, [8204])
assert_eq('forecast: comma pair in a subject counts both',
          forecast_candidates(others, 'Combined (#8000, #8204)', {}).map { |p| p['number'] }, [8204, 8000])
assert_eq('forecast: overlap on shared code file',
          forecast_overlaps([{ 'number' => 1, 'files_changed' => ['a.rb', 'Changelog.md'] }],
                            [{ 'number' => 9, 'title' => 'T', 'files' => ['a.rb', 'Changelog.md'] }]),
          { '1' => [{ 'number' => 9, 'title' => 'T', 'overlap_count' => 1, 'top_files' => ['a.rb'] }] })

# --- change_category ---

puts "\n\e[1m--- change_category ---\e[0m"

{
  'Gemfile' => 'gems', 'Gemfile.lock' => 'gems', 'package.json' => 'js', 'package-lock.json' => 'js',
  'requirements-jupyter.txt' => 'python', 'requirements-scanner.txt' => 'python',
  'markus.control' => 'system', '.dockerfiles/Dockerfile' => 'system',
  'config/settings.yml' => 'settings', 'config/settings/production.yml' => 'settings',
  'config/application.rb' => 'settings',
  'Dockerfile' => nil, 'config/settings/nested/x.yml' => nil, 'app/models/user.rb' => nil,
  'lib/requirements-x.txt' => nil
}.each { |path, category| assert_eq("category: #{path}", ReleaseHelpers.change_category(path), category) }

# --- categorized_changes and change_summaries ---

puts "\n\e[1m--- categorized_changes ---\e[0m"

cat_prs = [
  { 'number' => 1, 'files_changed' => ['Gemfile', 'Gemfile.lock', 'app/a.rb'] },
  { 'number' => 2, 'files_changed' => ['requirements-scanner.txt'] },
  { 'number' => 3, 'files_changed' => ['config/settings/production.yml'] },
  { 'number' => 4, 'files_changed' => ['app/b.rb'] }
]
cats = categorized_changes(cat_prs)
assert_eq('categories: only touched ones', cats.keys, %w[gems python settings])
assert_eq('categories: files per PR', cats['gems'], [{ 'number' => 1, 'files' => ['Gemfile', 'Gemfile.lock'] }])
assert_eq('categories: none for code-only PRs', categorized_changes([cat_prs[3]]), {})

none = change_summaries({})
assert_eq('summary: no changes', none.values, ['No dependency changes', 'No settings changes', 'No scheduler changes'])
some = change_summaries({ 'gems' => [{ 'number' => 1, 'files' => ['Gemfile'], 'lines' => 4 }],
                          'python' => [{ 'number' => 2, 'files' => ['requirements-scanner.txt'], 'lines' => 2 }],
                          'settings' => [{ 'number' => 3, 'files' => ['config/settings.yml'], 'lines' => 1 }],
                          'scheduler' => [{ 'number' => 3, 'files' => ['config/settings.yml'] }] })
assert_eq('summary: per category', some['summary'],
          'Dependency changes: gems: #1 (Gemfile, 4 lines); python: #2 (requirements-scanner.txt, 2 lines)')
assert_eq('summary: settings names PR and file', some['settings'],
          'Settings changes: #3 (config/settings.yml, 1 lines). Notify sysadmin')
assert_eq('summary: scheduler flagged', some['scheduler'],
          'SCHEDULER: resque_scheduler jobs change in #3 (config/settings.yml). Notify sysadmin')

# --- yaml_block ---

puts "\n\e[1m--- yaml_block ---\e[0m"

settings_old = <<~YML
  rails:
    cache: x
  resque_scheduler:
    CleanTmpJob:
      every: 2d

  queues:
    default: DEFAULT_QUEUE
YML
settings_new = settings_old.sub("    every: 2d\n", "    every: 2d\n  LtiKeyMaintenanceJob:\n    every: 1d\n")
settings_other = settings_old.sub('cache: x', 'cache: y').sub('DEFAULT_QUEUE', 'OTHER')
assert_eq('yaml_block: block lines', yaml_block(settings_old, 'resque_scheduler').length, 3)
assert_eq('yaml_block: absent key', yaml_block("a: 1\n", 'resque_scheduler'), [])
assert('yaml_block: new job changes block',
       yaml_block(settings_old, 'resque_scheduler') != yaml_block(settings_new, 'resque_scheduler'))
assert_eq('yaml_block: other settings leave block equal',
          yaml_block(settings_other, 'resque_scheduler'), yaml_block(settings_old, 'resque_scheduler'))

jwks = ReleaseHelpers.run_stripped('git', 'log', 'origin/master', '--format=%H', '--grep=(#8056)', '-1')
if jwks.empty?
  puts '  SKIP  scheduler_files: #8056 not in local origin/master'
else
  assert_eq('scheduler_files: #8056 adds LtiKeyMaintenanceJob',
            scheduler_files({ 'merge_commit' => jwks, 'files_changed' => ReleaseHelpers.pr_files(jwks) }),
            ['config/settings.yml'])
end

# --- fetch_pr_files ---

puts "\n\e[1m--- fetch_pr_files ---\e[0m"

big = ReleaseHelpers.run_stripped('git', 'log', 'origin/release', '--format=%H', '--grep=(#8136)', '-1')
if big.empty?
  puts '  SKIP  fetch_pr_files: #8136 not in local origin/release'
else
  assert('local git lists > 300 files for #8136', fetch_pr_files(8136, big).length > 300)
end
gh_stub = "$LOAD_PATH.unshift('#{RELEASE_DIR}'); require 'recon'; " \
          "def gh_pr_files(_) = raise(ReleaseHelpers::CommandError, 'HTTP 406'); " \
          "p fetch_pr_files(9, 'deadbeefdeadbeef')"
gh_out, gh_err, = Open3.capture3('ruby', '-e', gh_stub)
assert('missing commit falls back to gh, failure warns',
       gh_err.include?('using gh pr diff') && gh_err.include?('needs_review'))
assert_eq('missing commit and gh failure give nil, not an abort', gh_out.strip, 'nil')

# --- recon-format.rb: scheduler and release notes ---

puts "\n\e[1m--- recon-format.rb (scheduler, release notes) ---\e[0m"

with_scheduler = JSON.parse(sample)
with_scheduler['dependency_changes']['scheduler'] = 'SCHEDULER: resque_scheduler jobs change in settings: #200'
out, = format_cmd(JSON.generate(with_scheduler), '--summary')
assert('summary prints scheduler line', out.include?('SCHEDULER: resque_scheduler jobs change'))
out, = format_cmd(JSON.generate(with_scheduler), '--pr-body')
assert('pr-body prints scheduler line', out.include?('- Scheduler: SCHEDULER:'))
out, = format_cmd(sample, '--summary')
assert('summary with no scheduler change says none', out.include?('No scheduler changes') && !out.include?('SCHEDULER'))

after_merge = JSON.parse(sample).merge('proposed_cherry_pick_order' => [])
after_merge['milestone_prs'] = [
  { 'number' => 100, 'title' => 'Feature A', 'already_released_in' => 'v2.9.6', 'merged_at' => '2026-01-02' },
  { 'number' => 200, 'title' => 'Bump', 'already_released_in' => 'v2.9.6', 'merged_at' => '2026-01-01' },
  { 'number' => 50, 'title' => 'Old', 'already_released_in' => 'v2.9.5', 'merged_at' => '2025-12-01' }
]
out, = format_cmd(JSON.generate(after_merge), '--release-notes')
assert_eq('release-notes after merge: PRs shipped in this version', out.split("\n"),
          ['- #200 — Bump', '- #100 — Feature A'])

# --- validate_version! ---

puts "\n\e[1m--- validate_version! ---\e[0m"

assert 'v2.9.6 valid', valid_version?('v2.9.6')
assert 'v0.0.1 valid', valid_version?('v0.0.1')
assert 'no v prefix invalid', !valid_version?('2.9.6')
assert 'two parts invalid', !valid_version?('v2.9')
assert 'verbose invalid', !valid_version?('verbose')
assert 'rc suffix invalid', !valid_version?('v2.9.6-rc1')

# ============================================================================
# Summary
# ============================================================================

total = TestState.pass + TestState.fail_count
puts "\n#{'=' * 60}"
if TestState.fail_count.zero?
  puts "\e[32m#{total} tests passed\e[0m"
else
  puts "\e[31m#{TestState.fail_count} of #{total} tests failed:\e[0m"
  TestState.errors.each { |e| puts "  - #{e}" }
end
puts '=' * 60

exit(TestState.fail_count.zero? ? 0 : 1)
