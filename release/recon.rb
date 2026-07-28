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
  pull['already_in_release'] = !sha.to_s.empty? && ancestor_of_release?(sha)
end

# Query the milestone's PRs directly from GitHub's database via GraphQL rather
# than `gh pr list --search`, whose backing search index can lag hours behind
# milestone edits. Shape mirrors the old gh output: number, title, mergedAt,
# mergeCommit{oid}, author{login}.
MILESTONE_QUERY = <<~GRAPHQL
  query($owner: String!, $name: String!, $milestone: String!) {
    repository(owner: $owner, name: $name) {
      milestones(query: $milestone, first: 10) {
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
  pr_nodes = milestone&.dig('pullRequests', 'nodes') || []
  warn "Warning: milestone #{version} hit the 100-PR query cap — some PRs may be missing" if pr_nodes.length >= 100
  prs = pr_nodes.sort_by { |pr| pr['mergedAt'] }
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
  timestamps = pending_prs.to_h { |pr| [pr['number'], Time.parse(pr['mergedAt'])] }
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
  by_num = pending_prs.to_h { |pr| [pr['number'], pr] }
  remaining = pending_prs.map { |pr| pr['number'] }
  build_order(remaining, by_num)
end

# Resolves file-overlap dependencies and returns topologically sorted cherry-pick order.
def build_cherry_pick_order(pending_prs)
  detect_dependencies(pending_prs)
  topo_sort(pending_prs)
end

def diff_release_to_master(*paths)
  ReleaseHelpers.run_stripped('git', 'diff', 'origin/release..origin/master', '--', *paths)
end

def dependency_changes
  dep_diff = diff_release_to_master('Gemfile', 'Gemfile.lock', 'package.json', 'package-lock.json')
  settings_diff = diff_release_to_master('markus.control', 'config/settings.yml')
  dep_line_count = dep_diff.lines.count { |l| l.start_with?('+', '-') }
  {
    'summary' => dep_diff.empty? ? 'No dependency changes' : "Dependency files changed (#{dep_line_count} lines)",
    'settings' => settings_diff.empty? ? 'No settings changes' : 'Settings files changed — notify sysadmin'
  }
end

def pr_summary(pull)
  { 'number' => pull['number'], 'title' => pull['title'], 'author' => pull.dig('author', 'login'),
    'merged_at' => pull['mergedAt'], 'merge_commit' => pull['merge_commit'],
    'files_changed' => pull['files_changed'], 'already_in_release' => pull['already_in_release'],
    'dependencies' => pull['dependencies'] || [] }
end

def skipped_entry(pull)
  { 'ref' => pull['merge_commit'], 'number' => pull['number'], 'reason' => 'Already ancestor of release branch' }
end

def build_result(version, prs, order)
  {
    'version' => version,
    'timestamp' => Time.now.utc.iso8601,
    'release_branch_tip' => ReleaseHelpers.run_stripped('git', 'log', 'origin/release', '--oneline', '-1'),
    'milestone_prs' => prs.map { |pr| pr_summary(pr) },
    'non_pr_commits' => find_non_pr_commits,
    'proposed_cherry_pick_order' => order,
    'skipped' => prs.select { |pr| pr['already_in_release'] }.map { |pr| skipped_entry(pr) },
    'dependency_changes' => dependency_changes
  }
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

puts JSON.pretty_generate(build_result(version, prs, order))
