#!/usr/bin/env ruby
# frozen_string_literal: true

# Release Recon: discovers milestone PRs and builds a cherry-pick plan.
#
# Usage:
#   ruby release/recon.rb <version>
#   ruby release/recon.rb --help
#
# Output: JSON to stdout with milestone PRs, cherry-pick order, and skipped items.

require 'json'
require 'time'
require_relative 'common'

# Files from local git (no 300-file limit); `gh pr diff` only when the commit is missing locally.
def fetch_pr_files(number, sha)
  return ReleaseHelpers.pr_files(sha) if ReleaseHelpers.commit_exists?(sha)

  warn "Warning: merge commit of ##{number} missing locally (run git fetch origin); using gh pr diff"
  gh_pr_files(number)
rescue ReleaseHelpers::CommandError => e
  warn "Warning: files of ##{number} unavailable, marked needs_review (#{e.message.lines.last.strip})"
  nil
end

def gh_pr_files(number)
  ReleaseHelpers.run_stripped('gh', 'pr', 'diff', number.to_s, '--repo', ReleaseHelpers::REPO, '--name-only')
                .split("\n")
end

def ancestor_of_release?(sha)
  ReleaseHelpers.command_succeeds?('git', 'merge-base', '--is-ancestor', sha, 'origin/release')
end

# PR numbers on changelog bullets (and their wrapped lines), by section:
# { N => { 'version' => 'v2.10.5' | 'unreleased', 'evidence' => 'Changelog.md [v2.10.5]' } }.
def changelog_shipped(changelog)
  shipped = {}
  section = nil
  in_bullet = false
  changelog.each_line do |line|
    header = line[/\A## \[([^\]]+)\]/, 1]
    section = header.casecmp?('unreleased') ? 'unreleased' : header if header
    in_bullet = !section.nil? && (line.start_with?('- ', '* ') || (in_bullet && line.match?(/\A\s+\S/)))
    next unless in_bullet

    ReleaseHelpers.pr_refs(line).each do |num|
      shipped[num] ||= { 'version' => section, 'evidence' => "Changelog.md [#{section}]" }
    end
  end
  shipped
end

# PR numbers in release commits, from +log+ = `git log --format=%x1e%h%n%B`. Reads each subject
# and the `* ` lines of squash bodies, which list every picked PR, bot bumps included. A
# `Revert "..."` line ships the revert, not the PRs quoted in it.
def release_log_shipped(log)
  log.split("\x1e").each_with_object({}) do |entry, shipped|
    sha, subject, *body = entry.lines(chomp: true)
    next if subject.nil?

    version = subject[/\Av\d+\.\d+\.\d+/i]&.downcase
    ([subject] + body.grep(/\A\* /)).each do |line|
      ReleaseHelpers.pr_refs(line.sub(/Revert ".*"/, 'Revert')).each do |num|
        shipped[num] ||= { 'version' => version, 'evidence' => "release commit #{sha} (#{subject})" }
      end
    end
  end
end

# Release PRs are squash-merged, so ancestry checks miss shipped PRs. The changelog lists
# human PRs; squash bodies list everything, including bot bumps with no changelog line.
def shipped_prs(changelog, log)
  release_log_shipped(log).merge(changelog_shipped(changelog))
end

def release_shipped
  @release_shipped ||= shipped_prs(
    ReleaseHelpers.run('git', 'show', 'origin/release:Changelog.md'),
    ReleaseHelpers.run('git', 'log', 'origin/release', '--format=%x1e%h%n%B')
  )
end

def skip_reason(pull, ancestor)
  return "Shipped: #{pull['shipped_evidence']}" if pull['shipped_evidence']
  return 'Already ancestor of release branch' if ancestor

  'Changes only Changelog.md' if pull['files_changed'] == ['Changelog.md']
end

def enrich_pr(pull)
  sha = pull.dig('mergeCommit', 'oid')
  files = fetch_pr_files(pull['number'], sha)
  shipped = release_shipped[pull['number']]
  ancestor = !sha.to_s.empty? && ancestor_of_release?(sha)
  pull.merge!('merge_commit' => sha, 'files_changed' => files || [],
              'already_released_in' => shipped&.dig('version'),
              'shipped_evidence' => shipped&.dig('evidence'),
              'already_in_release' => ancestor || !shipped.nil?)
  pull['needs_review'] = true if files.nil?
  pull['skip_reason'] = skip_reason(pull, ancestor)
end

# Reads the milestone's PRs through GraphQL, since the search index behind
# `gh pr list --search` can lag hours behind milestone edits.
MILESTONE_QUERY = <<~GRAPHQL
  query($owner: String!, $name: String!, $milestone: String!) {
    repository(owner: $owner, name: $name) {
      milestones(query: $milestone, first: 100) {
        nodes {
          title
          pullRequests(first: 100, states: MERGED) {
            nodes {
              number
              title
              mergedAt
              mergeCommit { oid }
              author { login }
            }
          }
        }
      }
    }
  }
GRAPHQL

def fetch_milestone_prs(version)
  owner, name = ReleaseHelpers::REPO.split('/')
  raw = ReleaseHelpers.run_stripped(
    'gh', 'api', 'graphql', '-f', "query=#{MILESTONE_QUERY}",
    '-F', "owner=#{owner}", '-F', "name=#{name}", '-F', "milestone=#{version}"
  )
  nodes = JSON.parse(raw).dig('data', 'repository', 'milestones', 'nodes') || []
  milestone = nodes.find { |m| m['title'] == version }
  abort "Error: milestone #{version} not found on #{ReleaseHelpers::REPO}" if milestone.nil?

  pr_nodes = milestone.dig('pullRequests', 'nodes') || []
  warn "Warning: milestone #{version} hit the 100-PR query cap; some PRs may be missing" if pr_nodes.length >= 100
  prs = pr_nodes.sort_by { |pr| pr['mergedAt'] }
  warn "Warning: No merged PRs found in milestone #{version}" if prs.empty?
  prs.each { |pr| enrich_pr(pr) }
end

# Commits on master but not release whose subject cites no PR: direct pushes.
def find_non_pr_commits
  log = ReleaseHelpers.run_stripped('git', 'log', 'origin/release..origin/master', '--oneline')
  log.split("\n").filter_map do |line|
    next if line.include?('(#') || line.strip.empty?

    hash, *msg = line.split
    { 'hash' => hash, 'message' => msg.join(' ') }
  end
end

def earlier_prs(prs, current, timestamps)
  prs.select { |o| timestamps[o['number']] < timestamps[current['number']] }
end

# Changelog.md is excluded from overlap (v2.10.2: 46/92 PRs touched it, marking
# 88/92 as dependent, all noise). PRs overlapping on lockfiles alone get no edge.
LOCKFILES = ['Gemfile.lock', 'package.json', 'package-lock.json'].freeze

def ordering_files(pull)
  pull['files_changed'] - ['Changelog.md']
end

# Records, for information, the earlier PRs each PR shares a non-lockfile file with.
def detect_dependencies(pending_prs)
  timestamps = pending_prs.to_h { |pr| [pr['number'], Time.parse(pr['mergedAt'])] }
  pending_prs.each do |pr|
    earlier = earlier_prs(pending_prs, pr, timestamps)
    overlapping = earlier.select { |o| ((ordering_files(pr) & ordering_files(o)) - LOCKFILES).any? }
    pr['dependencies'] = overlapping.map { |o| o['number'] }
  end
end

# Cherry-pick order is merge-date order. Every dependency points to an earlier
# merge, so this order satisfies them all.
def build_cherry_pick_order(pending_prs)
  detect_dependencies(pending_prs)
  pending_prs.sort_by { |pr| pr['mergedAt'] }.map.with_index(1) do |pr, i|
    { 'order' => i, 'ref' => pr['merge_commit'], 'type' => 'milestone_pr', 'number' => pr['number'] }
  end
end

# Cherry-pick conflicts come mostly from master PRs outside the milestone
# (v2.10.2: 11 of 12). Forecast them by file overlap so conflicts are resolved
# with intent. Broad PRs report a count and top files, never the cross-product.
def fetch_non_milestone_prs(milestone_numbers)
  raw = ReleaseHelpers.run_stripped(
    'gh', 'pr', 'list', '--repo', ReleaseHelpers::REPO, '--state', 'merged',
    '--base', 'master', '--limit', '100',
    '--json', 'number,title,mergedAt,files',
    '--jq', '[.[] | {number, title, mergedAt, files: [.files[].path]}]'
  )
  JSON.parse(raw).reject { |pr| milestone_numbers.include?(pr['number']) }
rescue StandardError => e
  warn "Warning: conflict forecast skipped (#{e.message})"
  []
end

# Master PRs that can conflict: in the master log, and not already shipped on release.
def forecast_candidates(prs, master_subjects, shipped)
  in_range = ReleaseHelpers.pr_refs(master_subjects)
  prs.select { |pr| in_range.include?(pr['number']) && !shipped.key?(pr['number']) }
end

def overlap_entry(other, shared)
  { 'number' => other['number'], 'title' => other['title'],
    'overlap_count' => shared.length, 'top_files' => shared.first(5) }
end

def forecast_overlaps(pending_prs, candidates)
  pending_prs.each_with_object({}) do |pr, forecast|
    hits = candidates.filter_map do |other|
      shared = ordering_files(pr) & other['files']
      overlap_entry(other, shared) unless (shared - LOCKFILES).empty?
    end
    forecast[pr['number'].to_s] = hits if hits.any?
  end
end

def conflict_forecast(pending_prs)
  return {} if pending_prs.empty?

  in_range = ReleaseHelpers.run_stripped('git', 'log', 'origin/release..origin/master', '--format=%s')
  others = fetch_non_milestone_prs(pending_prs.map { |pr| pr['number'] })
  forecast_overlaps(pending_prs, forecast_candidates(others, in_range, release_shipped))
end

# Per CHANGE_CATEGORIES key, the PRs touching it and their files:
# { 'gems' => [{ 'number' => 1, 'files' => ['Gemfile.lock'] }], ... }, empty categories left out.
def categorized_changes(prs)
  ReleaseHelpers::CHANGE_CATEGORIES.keys.each_with_object({}) do |category, result|
    hits = prs.filter_map do |pull|
      files = pull['files_changed'].select { |f| ReleaseHelpers.change_category(f) == category }
      { 'number' => pull['number'], 'files' => files } unless files.empty?
    end
    result[category] = hits unless hits.empty?
  end
end

# The lines of the +key+: block in YAML +text+, blank lines dropped. Plain text, because
# settings files can hold ERB.
def yaml_block(text, key)
  lines = text.lines.reject { |l| l.strip.empty? }
  start = lines.index { |l| l.match?(/\A\s*#{Regexp.escape(key)}:/) }
  return [] if start.nil?

  indent = lines[start][/\A */].length
  [lines[start]] + lines[(start + 1)..].take_while { |l| l[/\A */].length > indent }
end

def file_at(rev, path)
  ReleaseHelpers.run('git', 'show', "#{rev}:#{path}")
rescue ReleaseHelpers::CommandError
  ''
end

# Settings files whose resque_scheduler block the PR's merge commit changes.
def scheduler_files(pull)
  sha = pull['merge_commit']
  pull['files_changed'].select do |path|
    path.end_with?('.yml') && ReleaseHelpers.change_category(path) == 'settings' &&
      yaml_block(file_at("#{sha}^1", path), 'resque_scheduler') != yaml_block(file_at(sha, path), 'resque_scheduler')
  end
end

def change_lines_count(pull, files)
  ReleaseHelpers.change_lines(ReleaseHelpers.pr_diff(pull['merge_commit'], *files)).length
end

# "#1 (Gemfile, Gemfile.lock, 12 lines), #2 (Gemfile.lock, 4 lines)"
def describe_hits(hits)
  hits.map { |h| "##{h['number']} (#{[*h['files'], h['lines'] && "#{h['lines']} lines"].compact.join(', ')})" }
      .join(', ')
end

def sysadmin_notice(hits, label, none)
  hits ? "#{label} #{describe_hits(hits)}. Notify sysadmin" : none
end

def change_summaries(categories)
  deps = categories.except('settings', 'scheduler').map { |cat, hits| "#{cat}: #{describe_hits(hits)}" }
  {
    'summary' => deps.empty? ? 'No dependency changes' : "Dependency changes: #{deps.join('; ')}",
    'settings' => sysadmin_notice(categories['settings'], 'Settings changes:', 'No settings changes'),
    'scheduler' => sysadmin_notice(categories['scheduler'], 'SCHEDULER: resque_scheduler jobs change in',
                                   'No scheduler changes')
  }
end

# Dependency, settings and scheduler changes of the pending PRs' own commits, not of
# origin/release..origin/master, which holds every master change since the last squash.
def dependency_changes(pending_prs)
  categories = categorized_changes(pending_prs)
  by_num = pending_prs.to_h { |pr| [pr['number'], pr] }
  categories.each_value do |hits|
    hits.each { |h| h['lines'] = change_lines_count(by_num[h['number']], h['files']) }
  end
  scheduler = pending_prs.filter_map do |pull|
    files = scheduler_files(pull)
    { 'number' => pull['number'], 'files' => files } unless files.empty?
  end
  categories['scheduler'] = scheduler unless scheduler.empty?
  change_summaries(categories).merge('categories' => categories)
end

# PRs that add or change database migrations. Each one means the sysadmins must run
# `rails db:migrate` on staging and production. In v2.10.5 a skipped migration made
# grading pages return 500, and production rolled back.
def migration_changes(prs)
  prs.filter_map do |pull|
    files = pull['files_changed'].grep(%r{\Adb/migrate/.+\.rb\z})
    { 'number' => pull['number'], 'title' => pull['title'], 'files' => files } unless files.empty?
  end
end

def pr_summary(pull)
  summary = { 'number' => pull['number'], 'title' => pull['title'], 'author' => pull.dig('author', 'login'),
              'merged_at' => pull['mergedAt'], 'merge_commit' => pull['merge_commit'],
              'files_changed' => pull['files_changed'], 'already_in_release' => pull['already_in_release'],
              'already_released_in' => pull['already_released_in'],
              'shipped_evidence' => pull['shipped_evidence'],
              'dependencies' => pull['dependencies'] || [] }
  pull['needs_review'] ? summary.merge('needs_review' => true) : summary
end

def skipped_entry(pull)
  { 'ref' => pull['merge_commit'], 'number' => pull['number'], 'reason' => pull['skip_reason'] }
end

def build_result(version, prs)
  skipped, pending = prs.partition { |pr| pr['skip_reason'] }
  order = build_cherry_pick_order(pending)
  {
    'version' => version,
    'timestamp' => Time.now.utc.iso8601,
    'release_branch_tip' => ReleaseHelpers.run_stripped('git', 'log', 'origin/release', '--oneline', '-1'),
    'milestone_prs' => prs.map { |pr| pr_summary(pr) },
    'non_pr_commits' => find_non_pr_commits,
    'proposed_cherry_pick_order' => order,
    'conflict_forecast' => conflict_forecast(pending),
    'skipped' => skipped.map { |pr| skipped_entry(pr) },
    'dependency_changes' => dependency_changes(pending),
    'migrations' => migration_changes(pending)
  }
end

# --- Main ---

if $PROGRAM_NAME == __FILE__
  version = ARGV[0]

  # RELEASING.md (Phase 1) greps this help for MIGRATIONS to reject older copies.
  if version.nil? || ['-h', '--help'].include?(version)
    warn <<~HELP
      Usage: ruby release/recon.rb <version>
        e.g. ruby release/recon.rb v2.9.6

      Queries the GitHub milestone for merged PRs, skips PRs already shipped on
      release, orders the rest by merge date, and outputs a JSON plan to stdout.
      The plan flags MIGRATIONS and SCHEDULER changes of the PRs to pick.
    HELP
    exit(version.nil? ? 1 : 0)
  end

  ReleaseHelpers.validate_version!(version)
  puts JSON.pretty_generate(build_result(version, fetch_milestone_prs(version)))
end
