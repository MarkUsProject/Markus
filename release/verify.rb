#!/usr/bin/env ruby
# frozen_string_literal: true

# Cherry-pick Verification — Detects contamination after a cherry-pick.
#
# Usage:
#   ruby release/verify.rb <pr_number>
#   ruby release/verify.rb --help
#
# Exit codes: 0 = PASS, 1 = FAIL (contamination), 2 = usage error

require 'set'
require_relative 'common'

EXCLUDE_FILES = Set['Changelog.md'].freeze
# Files where only additions (+lines) are compared, not deletions.
# Gemfile.lock base versions differ between release and master, so removed lines always mismatch.
ADDITIONS_ONLY_FILES = Set['Gemfile.lock'].freeze

def file_set(*cmd)
  ReleaseHelpers.run(*cmd).strip.split("\n").to_set - EXCLUDE_FILES
end

def extract_file_diff(full_diff, filename)
  full_diff.lines
           .slice_before { |l| l.start_with?('diff --git') }
           .find { |chunk| chunk.first.include?("b/#{filename}") }
           &.join || ''
end

def change_lines(diff_text)
  diff_text.lines
           .select { |l| l.start_with?('+', '-') }
           .reject { |l| l.start_with?('+++', '---') }
end

# --- Main ---

pr_number = ARGV[0]

if pr_number.nil? || ['-h', '--help'].include?(pr_number)
  warn <<~HELP
    Usage: ruby release/verify.rb <pr_number>
      e.g. ruby release/verify.rb 7851

    Compares the last commit's diff against the original PR diff.
    Detects contamination from Git's 3-way merge during cherry-pick.
    Excludes Changelog.md by default.
  HELP
  exit(pr_number.nil? ? 2 : 0)
end

cherry_files = file_set('git', 'diff', 'HEAD~1..HEAD', '--name-only')
pr_files = file_set('gh', 'pr', 'diff', pr_number, '--repo', ReleaseHelpers::REPO, '--name-only')

extra = cherry_files - pr_files
missing = pr_files - cherry_files
shared = cherry_files & pr_files

pr_full_diff = ReleaseHelpers.run('gh', 'pr', 'diff', pr_number, '--repo', ReleaseHelpers::REPO)
comparable_lines = ->(lines, file) do
  return lines.select { |l| l.start_with?('+') } if ADDITIONS_ONLY_FILES.include?(file)

  lines
end

mismatched = shared.reject do |file|
  cherry = change_lines(ReleaseHelpers.run('git', 'diff', 'HEAD~1..HEAD', '--', file))
  original = change_lines(extract_file_diff(pr_full_diff, file))
  comparable_lines.call(cherry, file).sort == comparable_lines.call(original, file).sort
end

if [extra, missing, mismatched].any? { |s| !s.empty? }
  puts "FAIL  PR ##{pr_number} — contamination detected"
  extra.each { |f| puts "        + #{f} (extra)" }
  missing.each { |f| puts "        - #{f} (missing)" }
  mismatched.each { |f| puts "        ~ #{f} (line mismatch)" }
  exit 1
end

puts "PASS  PR ##{pr_number} — cherry-pick matches original diff"
puts "      Files: #{shared.size} checked, #{EXCLUDE_FILES.to_a.join(', ')} excluded"
