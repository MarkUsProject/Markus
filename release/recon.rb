#!/usr/bin/env ruby
# frozen_string_literal: true

# Release Recon — Discovers milestone PRs and builds a cherry-pick plan.
#
# Usage:
#   ruby release/recon.rb <version>
#   ruby release/recon.rb --help
#
# Output: JSON to stdout with milestone PRs, cherry-pick order, and skipped items.

require 'json'
require 'time'
require_relative 'common'

def fetch_pr_files(number)
  ReleaseHelpers.run_stripped(
    'gh', 'pr', 'diff', number.to_s,
    '--repo', ReleaseHelpers::REPO, '--name-only'
  ).split("\n")
end

def ancestor_of_release?(sha)
  ReleaseHelpers.command_succeeds?(
    'git', 'merge-base', '--is-ancestor', sha, 'origin/release'
  )
end

def enrich_pr(pull)
  pull['files_changed'] = fetch_pr_files(pull['number'])
  sha = pull.dig('mergeCommit', 'oid')
  pull['merge_commit'] = sha
  pull['already_in_release'] = sha.present? && ancestor_of_release?(sha)
end

def fetch_milestone_prs(version)
  raw = ReleaseHelpers.run_stripped(
    'gh', 'pr', 'list', '--repo', ReleaseHelpers::REPO,
    '--state', 'merged', '--search', "milestone:#{version}",
    '--json', 'number,title,mergedAt,mergeCommit,author',
    '--jq', 'sort_by(.mergedAt)', '--limit', '100'
  )
  prs = JSON.parse(raw)
  warn "Warning: No merged PRs found in milestone #{version}" if prs.empty?
  prs.each { |pr| enrich_pr(pr) }
end

# Heuristic: lines containing "(#" are PR merge commits; others are direct pushes
def find_non_pr_commits
  ReleaseHelpers.run_stripped('git', 'log', 'origin/release..origin/master', '--oneline')
                .split("\n")
                .reject { |l| l.include?('(#') || l.strip.empty? }
                .map do |line|
                  hash, *msg = line.split
                  { 'hash' => hash, 'message' => msg.join(' ') }
  end
end

def earlier_prs(prs, current, timestamps)
  prs.select do |o|
    o['number'] != current['number'] &&
      timestamps[o['number']] < timestamps[current['number']]
  end
end

def detect_dependencies(pending_prs)
  timestamps = pending_prs.to_h { |pr| [pr['number'], Time.zone.parse(pr['mergedAt'])] }
  pending_prs.each do |pr|
    earlier = earlier_prs(pending_prs, pr, timestamps)
    overlapping = earlier.select { |o| pr['files_changed'].intersect?(o['files_changed']) }
    pr['dependencies'] = overlapping.map { |o| o['number'] }
  end
end

def find_ready(remaining, by_num, placed)
  ready = remaining.select { |n| (by_num[n]['dependencies'] - placed).empty? }
  ready = [remaining.min_by { |n| by_num[n]['mergedAt'] }] if ready.empty?
  ready.sort_by { |n| by_num[n]['mergedAt'] }
end

def build_order_entry(position, number, pull)
  { 'order' => position, 'ref' => pull['merge_commit'],
    'type' => 'milestone_pr', 'number' => number }
end

def build_order(remaining, by_num)
  placed = []
  order = []
  while remaining.any?
    ready = find_ready(remaining, by_num, placed)
    ready.each { |n| order << build_order_entry(order.length + 1, n, by_num[n]) }
    placed.concat(ready)
    remaining -= ready
  end
  order
end

def topo_sort(pending_prs)
  by_num = pending_prs.index_by { |pr| pr['number'] }
  remaining = pending_prs.pluck('number')
  build_order(remaining, by_num)
end

# Resolves file-overlap dependencies and returns topologically sorted cherry-pick order.
def build_cherry_pick_order(pending_prs)
  detect_dependencies(pending_prs)
  topo_sort(pending_prs)
end

# --- Main ---

version = ARGV[0]

if version.nil? || ['-h', '--help'].include?(version)
  warn <<~HELP
    Usage: ruby release/recon.rb <version>
      e.g. ruby release/recon.rb v2.9.6

    Queries the GitHub milestone for merged PRs, checks ancestry,
    resolves cherry-pick order, and outputs a JSON plan to stdout.
  HELP
  exit(version.nil? ? 1 : 0)
end

prs = fetch_milestone_prs(version)
pending = prs.reject { |pr| pr['already_in_release'] }
order = build_cherry_pick_order(pending)

dep_diff = ReleaseHelpers.run_stripped(
  'git', 'diff', 'origin/release..origin/master', '--',
  'Gemfile', 'Gemfile.lock', 'package.json', 'package-lock.json'
)
settings_diff = ReleaseHelpers.run_stripped(
  'git', 'diff', 'origin/release..origin/master', '--',
  'markus.control', 'config/settings.yml'
)

dep_line_count = dep_diff.lines.count { |l| l.start_with?('+', '-') }

result = {
  'version' => version,
  'timestamp' => Time.now.utc.iso8601,
  'release_branch_tip' => ReleaseHelpers.run_stripped('git', 'log', 'origin/release', '--oneline', '-1'),
  'milestone_prs' => prs.map do |pr|
    { 'number' => pr['number'], 'title' => pr['title'], 'author' => pr.dig('author', 'login'),
      'merged_at' => pr['mergedAt'], 'merge_commit' => pr['merge_commit'],
      'files_changed' => pr['files_changed'], 'already_in_release' => pr['already_in_release'],
      'dependencies' => pr['dependencies'] || [] }
  end,
  'non_pr_commits' => find_non_pr_commits,
  'proposed_cherry_pick_order' => order,
  'skipped' => prs.select { |pr| pr['already_in_release'] }.map do |pr|
    { 'ref' => pr['merge_commit'], 'number' => pr['number'], 'reason' => 'Already ancestor of release branch' }
  end,
  'dependency_changes' => {
    'summary' => dep_diff.empty? ? 'No dependency changes' : "Dependency files changed (#{dep_line_count} lines)",
    'settings' => settings_diff.empty? ? 'No settings changes' : 'Settings files changed — notify sysadmin'
  }
}

puts JSON.pretty_generate(result)
