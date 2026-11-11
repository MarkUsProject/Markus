#!/usr/bin/env ruby
# frozen_string_literal: true

# Cherry-pick Verification: detects contamination after a cherry-pick.
#
# Usage:
#   ruby release/verify.rb <pr_number> <merge_sha> [<pick>]
#   ruby release/verify.rb --help
#
# Compares, file by file, the PR's diff (<merge_sha>^1..<merge_sha>, from local
# git; `gh pr diff` only when the commit is missing locally) with the pick's
# diff (<pick>~1..<pick>, default HEAD). Changelog.md is excluded.
# Lockfiles: version lines for packages the PR changed may differ after
# lockres resolution (WARN); every other line must match. A change with no text
# lines (binary, mode only) must leave the same mode and blob on both sides.
#
# Exit codes: 0 = PASS (WARN lines may print), 1 = FAIL (contamination), 2 = usage error

require 'set'
require_relative 'common'

EXCLUDE_FILES = Set['Changelog.md'].freeze
LOCKFILES = Set['Gemfile.lock', 'package.json', 'package-lock.json', 'yarn.lock'].freeze

# Key (indentation + name) of a version line, or nil.
def version_key(line)
  match = ReleaseHelpers::VERSION_LINE.match(line[1..])
  match && (match[1] + match[2])
end

# Exact-path chunk of a multi-file unified diff (for the gh fallback).
def extract_file_diff(full_diff, file)
  header = %r{\Adiff --git a/.* b/#{Regexp.escape(file)}\n\z}
  full_diff.lines
           .slice_before { |l| l.start_with?('diff --git') }
           .find { |chunk| header.match?(chunk.first) }
           &.join || ''
end

# :pass, :warn or :fail for one file, given the change lines of each side.
# A non-lockfile changed on one side only fails even with no text lines (binary).
def compare_file(file, pr_lines, pick_lines, in_both)
  return :fail unless in_both || LOCKFILES.include?(file)
  return :pass if pr_lines.sort == pick_lines.sort
  return :fail unless LOCKFILES.include?(file)

  keys = pr_lines.filter_map { |l| version_key(l) }.to_set
  other = ->(lines) { lines.reject { |l| keys.include?(version_key(l)) }.sort }
  other.call(pr_lines) == other.call(pick_lines) ? :warn : :fail
end

# Mode and blob id of +file+ at +commit+ ('' when absent). A binary or mode-only
# change has no text lines, so this is what both sides must agree on.
def tree_entry(commit, file)
  ReleaseHelpers.run_stripped('git', 'ls-tree', commit, '--', file).split("\t").first.to_s
end

# PR side: [files, ->(file) { diff text }], from local git or gh.
def pr_source(pr_number, sha)
  return [ReleaseHelpers.pr_files(sha), ->(f) { ReleaseHelpers.pr_diff(sha, f) }] if ReleaseHelpers.commit_exists?(sha)

  warn "WARN  #{sha} missing locally; using gh pr diff #{pr_number}"
  gh = ['gh', 'pr', 'diff', pr_number, '--repo', ReleaseHelpers::REPO]
  full = ReleaseHelpers.run(*gh)
  [ReleaseHelpers.run_stripped(*gh, '--name-only').split("\n"), ->(f) { extract_file_diff(full, f) }]
end

def label(file, pr_files, pick_files)
  return 'extra' unless pr_files.include?(file)
  return 'missing' unless pick_files.include?(file)

  'line mismatch'
end

def verify(pr_number, sha, pick)
  pr_files, pr_diff = pr_source(pr_number, sha)
  pick_files = ReleaseHelpers.run_stripped('git', 'diff', '--name-only', "#{pick}~1", pick).split("\n")
  files = ((pr_files | pick_files).to_set - EXCLUDE_FILES).sort
  files.to_h do |file|
    pr_lines = ReleaseHelpers.change_lines(pr_diff.call(file))
    pick_lines = ReleaseHelpers.change_lines(ReleaseHelpers.run('git', 'diff', "#{pick}~1", pick, '--', file))
    why = label(file, pr_files, pick_files)
    status = compare_file(file, pr_lines, pick_lines, why == 'line mismatch')
    status = :fail if status == :pass && pr_lines.empty? && tree_entry(sha, file) != tree_entry(pick, file)
    [file, [status, why]]
  end
end

# --- Main ---

if ARGV.intersect?(['-h', '--help']) || ARGV.length < 2 || ARGV.length > 3
  warn <<~HELP
    Usage: ruby release/verify.rb <pr_number> <merge_sha> [<pick>]
      e.g. ruby release/verify.rb 8204 041d7d968

    Compares the pick's diff (<pick>~1..<pick>, default HEAD) with the PR's
    diff (<merge_sha>^1..<merge_sha>) file by file and line by line.
    Detects contamination from Git's 3-way merge during cherry-pick.
    Excludes Changelog.md. Lockfile version lines resolved by lockres print WARN.
  HELP
  exit(ARGV.intersect?(['-h', '--help']) ? 0 : 2)
end

pr_number, sha, pick = ARGV
pick ||= 'HEAD'

begin
  results = verify(pr_number, sha, pick)
rescue ReleaseHelpers::CommandError => e
  puts "FAIL  PR ##{pr_number} — could not compare diffs"
  puts e.message.gsub(/^/, '        ')
  exit 1
end

warns = results.select { |_, (status, _)| status == :warn }
fails = results.select { |_, (status, _)| status == :fail }
warns.each_key { |f| puts "WARN  PR ##{pr_number} — #{f}: lockfile version lines differ (resolved by lockres)" }

unless fails.empty?
  puts "FAIL  PR ##{pr_number} — contamination detected"
  fails.each { |f, (_, why)| puts "        ~ #{f} (#{why})" }
  puts "      Compare: git diff #{sha}^1 #{sha} -- <file>  vs  git diff #{pick}~1 #{pick} -- <file>"
  exit 1
end

puts "PASS  PR ##{pr_number} — cherry-pick matches original diff"
puts "      Files: #{results.size} checked, #{EXCLUDE_FILES.to_a.join(', ')} excluded"
