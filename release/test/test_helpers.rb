#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit tests for release helper pure functions.
# Run: ruby release/test/test_helpers.rb

require 'json'
require 'set'
require 'open3'

$LOAD_PATH.unshift File.expand_path('..', __dir__)
require 'common'

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
  if actual == expected
    $stdout.puts "  \e[32mPASS\e[0m  #{description}"
    TestState.pass += 1
  else
    $stdout.puts "  \e[31mFAIL\e[0m  #{description}"
    $stdout.puts "         expected: #{expected.inspect}"
    $stdout.puts "         actual:   #{actual.inspect}"
    TestState.errors << description
    TestState.fail_count += 1
  end
end

# ============================================================================
# Pure functions copied from scripts (avoids loading scripts with side effects)
# ============================================================================

def parse_version_header(line)
  return unless line =~ /^## \[(unreleased|v[\d.]+)\]/i

  Regexp.last_match(1).downcase == 'unreleased' ? 'unreleased' : Regexp.last_match(1)
end

def process_line(line, result, current)
  ver = parse_version_header(line)
  return init_ver(result, current, ver) if ver
  return init_cat(result, current, line) if line.start_with?('### ') && current[:ver]

  add_entry(result, current, line) if line.start_with?('- ') && current[:ver] && current[:cat]
end

def init_ver(result, current, ver)
  current[:ver] = ver
  result[:order] << ver
  result[:sections][ver] = {}
  current[:cat] = nil
end

def init_cat(result, current, line)
  current[:cat] = line
  result[:sections][current[:ver]][line] ||= []
end

def add_entry(result, current, line)
  result[:sections][current[:ver]][current[:cat]] << line
end

def parse_changelog(text)
  result = { sections: {}, order: [] }
  current = { ver: nil, cat: nil }
  text.each_line { |line| process_line(line.rstrip, result, current) }
  { 'sections' => result[:sections], 'version_order' => result[:order] }
end

def entry_matches_prs?(entry, pr_numbers)
  pr_numbers.any? { |num| entry.match?(/\##{num}(?!\d)/) }
end

def find_ready(remaining, by_num, placed)
  ready = remaining.select { |n| (by_num[n]['dependencies'] - placed).empty? }
  ready = [remaining.min_by { |n| by_num[n]['mergedAt'] }] if ready.empty?
  ready.sort_by { |n| by_num[n]['mergedAt'] }
end

def build_order(remaining, by_num)
  placed = []
  order = []
  while remaining.any?
    ready = find_ready(remaining, by_num, placed)
    ready.each { |n| order << { 'order' => order.length + 1, 'number' => n, 'ref' => by_num[n]['merge_commit'] } }
    placed.concat(ready)
    remaining -= ready
  end
  order
end

def topological_sort(pending_prs)
  by_num = pending_prs.index_by { |pr| pr['number'] }
  remaining = pending_prs.pluck('number')
  build_order(remaining, by_num)
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

def format_cmd(json, flag)
  script = File.expand_path('../recon-format.rb', __dir__)
  stdout, _, status = Open3.capture3('ruby', script, flag, stdin_data: json)
  [stdout.strip, status.success?]
end

# ============================================================================
# Tests
# ============================================================================

puts "\n\e[1m--- parse_changelog ---\e[0m"

changelog = <<~MD
  # Changelog

  ## [unreleased]

  ### ✨ New features and improvements
  - Feature A (#100)
  - Feature B (#101)

  ### 🐛 Bug fixes
  - Fix C (#102)

  ## [v2.9.5]

  ### 🛡️ Security
  - Security fix (#90)

  ### ✨ New features and improvements
  - Old feature (#80)

  ## [v2.9.4]

  ### 🐛 Bug fixes
  - Old bug fix (#70)
MD

parsed = parse_changelog(changelog)
assert_eq 'version_order count', parsed['version_order'].length, 3
assert_eq 'version_order values', parsed['version_order'], %w[unreleased v2.9.5 v2.9.4]
assert_eq 'unreleased features', parsed['sections']['unreleased']['### ✨ New features and improvements'].length, 2
assert_eq 'unreleased bug fixes', parsed['sections']['unreleased']['### 🐛 Bug fixes'].length, 1
assert_eq 'v2.9.5 security', parsed['sections']['v2.9.5']['### 🛡️ Security'].length, 1
assert_eq 'v2.9.4 bug fixes', parsed['sections']['v2.9.4']['### 🐛 Bug fixes'].length, 1

empty = parse_changelog("# Changelog\n")
assert_eq 'empty changelog', empty['version_order'], []

# --- entry_matches_prs? ---

puts "\n\e[1m--- entry_matches_prs? ---\e[0m"

assert 'matches single PR', entry_matches_prs?('- Feature A (#100)', ['100'])
assert 'matches in list', entry_matches_prs?('- Feature A (#100)', %w[99 100 101])
assert 'no match for missing PR', !entry_matches_prs?('- Feature A (#100)', ['200'])
assert 'no false-match on substring', !entry_matches_prs?('- Feature (#1001)', ['100'])
assert 'matches multi-PR entry', entry_matches_prs?('- Fix (#100, #200)', ['200'])
assert 'matches PR at end of line', entry_matches_prs?('- Fix #100', ['100'])

# --- partition ---

puts "\n\e[1m--- partition_entries ---\e[0m"

entries = {
  'features' => ['- A (#100)', '- B (#101)', '- C (#200)'],
  'fixes' => ['- D (#100)']
}
pr_list = %w[100 200]

matched = {}
unmatched = {}
entries.each do |cat, ents|
  matched[cat], unmatched[cat] = ents.partition { |e| entry_matches_prs?(e, pr_list) }
end

assert_eq 'matched features', matched['features'].length, 2
assert_eq 'unmatched features', unmatched['features'], ['- B (#101)']
assert_eq 'matched fixes', matched['fixes'].length, 1

# --- topological_sort ---

puts "\n\e[1m--- topological_sort ---\e[0m"

linear = [
  { 'number' => 1, 'mergedAt' => '2026-01-01', 'merge_commit' => 'a', 'dependencies' => [] },
  { 'number' => 2, 'mergedAt' => '2026-01-02', 'merge_commit' => 'b', 'dependencies' => [1] },
  { 'number' => 3, 'mergedAt' => '2026-01-03', 'merge_commit' => 'c', 'dependencies' => [2] }
]
assert_eq 'linear: 1,2,3', topological_sort(linear).pluck('number'), [1, 2, 3]

diamond = [
  { 'number' => 1, 'mergedAt' => '2026-01-01', 'merge_commit' => 'a', 'dependencies' => [] },
  { 'number' => 2, 'mergedAt' => '2026-01-02', 'merge_commit' => 'b', 'dependencies' => [1] },
  { 'number' => 3, 'mergedAt' => '2026-01-03', 'merge_commit' => 'c', 'dependencies' => [1] },
  { 'number' => 4, 'mergedAt' => '2026-01-04', 'merge_commit' => 'd', 'dependencies' => [2, 3] }
]
nums = topological_sort(diamond).pluck('number')
assert_eq 'diamond: first is 1', nums[0], 1
assert_eq 'diamond: last is 4', nums[3], 4
assert 'diamond: 2 before 4', nums.index(2) < nums.index(4)
assert 'diamond: 3 before 4', nums.index(3) < nums.index(4)

independent = [
  { 'number' => 3, 'mergedAt' => '2026-01-03', 'merge_commit' => 'c', 'dependencies' => [] },
  { 'number' => 1, 'mergedAt' => '2026-01-01', 'merge_commit' => 'a', 'dependencies' => [] },
  { 'number' => 2, 'mergedAt' => '2026-01-02', 'merge_commit' => 'b', 'dependencies' => [] }
]
assert_eq 'independent: date order', topological_sort(independent).pluck('number'), [1, 2, 3]

cycle = [
  { 'number' => 1, 'mergedAt' => '2026-01-01', 'merge_commit' => 'a', 'dependencies' => [2] },
  { 'number' => 2, 'mergedAt' => '2026-01-02', 'merge_commit' => 'b', 'dependencies' => [1] }
]
result = topological_sort(cycle)
assert_eq 'cycle: 2 items', result.length, 2
assert_eq 'cycle: chronological fallback', result.pluck('number'), [1, 2]

single = [{ 'number' => 1, 'mergedAt' => '2026-01-01', 'merge_commit' => 'a', 'dependencies' => [] }]
assert_eq 'single PR', topological_sort(single).pluck('number'), [1]

assert_eq 'empty input', topological_sort([]), []

# --- extract_file_diff ---

puts "\n\e[1m--- extract_file_diff ---\e[0m"

diff = <<~DIFF
  diff --git a/file1.rb b/file1.rb
  --- a/file1.rb
  +++ b/file1.rb
  @@ -1,3 +1,4 @@
   line1
  +added
   line2
  diff --git a/file2.rb b/file2.rb
  --- a/file2.rb
  +++ b/file2.rb
  @@ -1,2 +1,2 @@
  -old
  +new
DIFF

assert 'file1 extraction', extract_file_diff(diff, 'file1.rb').include?('+added')
assert 'file1 excludes file2', extract_file_diff(diff, 'file1.rb').exclude?('+new')
assert 'file2 extraction', extract_file_diff(diff, 'file2.rb').include?('+new')
assert_eq 'missing file', extract_file_diff(diff, 'nope.rb'), ''

# --- change_lines ---

puts "\n\e[1m--- change_lines ---\e[0m"

cl = change_lines("--- a/f.rb\n+++ b/f.rb\n context\n-removed\n+added\n context\n")
assert_eq 'change_lines count', cl.length, 2
assert('includes -removed', cl.any? { |l| l.strip == '-removed' })
assert('includes +added', cl.any? { |l| l.strip == '+added' })
assert('excludes ---', cl.none? { |l| l.start_with?('---') })

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
  'dependency_changes' => { 'summary' => 'No dependency changes',
                            'settings' => 'No settings changes' }
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

# --- validate_version! ---

puts "\n\e[1m--- validate_version! ---\e[0m"

v = /\Av\d+\.\d+\.\d+\z/
assert 'v2.9.6 valid', 'v2.9.6'.match?(v)
assert 'v0.0.1 valid', 'v0.0.1'.match?(v)
assert 'no v prefix invalid', !'2.9.6'.match?(v)
assert 'two parts invalid', !'v2.9'.match?(v)
assert 'verbose invalid', !'verbose'.match?(v)
assert 'rc suffix invalid', !'v2.9.6-rc1'.match?(v)

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
