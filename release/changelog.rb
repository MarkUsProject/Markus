#!/usr/bin/env ruby
# frozen_string_literal: true

# Changelog Rebuild: produces a clean Changelog.md after cherry-picks.
#
# Usage:
#   ruby release/changelog.rb --mode=release --version=v2.9.6 --prs=7783,7851,7858
#   ruby release/changelog.rb --mode=master-sync --version=v2.9.6 --prs=7783,7851,7858 --bots=7858
#   ruby release/changelog.rb --help
#
# Modes:
#   release      Empty [unreleased] + new version section + old sections from origin/release
#   master-sync  Move cherry-picked entries from [unreleased] to new version section on master
#
# An existing [version] section on either branch is merged in, so a rerun gives the same
# output. Each picked PR (minus --bots) with no entry in the section prints a warning.

require_relative 'common'

CATEGORIES = [
  "### \u{1F6E1}\u{FE0F} Security",
  "### \u{1F6A8} Breaking changes",
  "### \u{2728} New features and improvements",
  "### \u{1F41B} Bug fixes",
  "### \u{1F4DA} Documentation changes",
  "### \u{1F527} Internal changes"
].freeze

def parse_version_header(line)
  return unless line =~ /^## \[(unreleased|v[\d.]+)\]/i

  Regexp.last_match(1).downcase == 'unreleased' ? 'unreleased' : Regexp.last_match(1)
end

def process_changelog_line(line, sections, current)
  ver = parse_version_header(line)
  return init_version_section(sections, current, ver) if ver
  return init_category(sections, current, line) if line.start_with?('### ') && current[:ver]

  append_entry(sections, current, line) if line.start_with?('- ') && current[:ver] && current[:cat]
end

def init_version_section(sections, current, ver)
  current[:ver] = ver
  sections[ver] = {}
  current[:cat] = nil
end

def init_category(sections, current, line)
  current[:cat] = line
  sections[current[:ver]][line] ||= []
end

def append_entry(sections, current, line)
  sections[current[:ver]][current[:cat]] << line
end

def warn_unknown_categories(sections)
  unknown = sections.flat_map(&:keys).uniq - CATEGORIES
  unknown.each { |c| warn "Warning: unknown category '#{c}' — entries may be dropped" }
end

# Parses Changelog.md into { version => { category => [entries] } }.
def parse_changelog(text)
  sections = {}
  current = { ver: nil, cat: nil }
  text.each_line { |line| process_changelog_line(line.rstrip, sections, current) }
  sections
end

# Whether +text+ cites PR +number+ as #number (and not as the start of a longer number).
def cites_pr?(text, number)
  text.match?(/\##{number}(?!\d)/)
end

# Joins { category => [entries] } hashes in order; the first copy of an entry wins.
def merge_entries(*sections)
  CATEGORIES.to_h { |cat| [cat, sections.flat_map { |s| s[cat] || [] }.uniq] }
end

def missing_prs(entries, pr_list)
  text = entries.values.flatten.join("\n")
  pr_list.reject { |n| cites_pr?(text, n) }
end

def emit_categories(out, entries_by_cat, skip_empty: false)
  CATEGORIES.each do |cat|
    entries = entries_by_cat[cat] || []
    next if skip_empty && entries.empty?

    out << cat
    entries.each { |e| out << e }
    out << ''
  end
end

def emit_old_sections_verbatim(out, raw_text, skip:)
  emitting = false
  raw_text.each_line do |line|
    line = line.chomp
    ver = parse_version_header(line)
    emitting = !skip.include?(ver) if ver
    out << line if emitting
  end
end

def partition_entries(unreleased, pr_list)
  matched = {}
  unmatched = {}
  unreleased.each do |cat, entries|
    matched[cat], unmatched[cat] = entries.partition { |e| pr_list.any? { |n| cites_pr?(e, n) } }
  end
  [matched, unmatched]
end

def build_changelog_sections(mode, version, matched, unmatched)
  out = ['# Changelog', '', '## [unreleased]', '']
  emit_categories(out, mode == 'release' ? {} : unmatched)
  out << "## [#{version}]"
  out << ''
  emit_categories(out, matched, skip_empty: true)
  out
end

# The version section joins any existing [version] section (from the branch being
# built first, then the other branch) with the picked [unreleased] entries, so a
# rerun or a later batch of picks keeps what is already there.
def build_changelog(mode, version, pr_list, bots: [])
  release_raw = ReleaseHelpers.run('git', 'show', 'origin/release:Changelog.md')
  master_raw = ReleaseHelpers.run('git', 'show', 'origin/master:Changelog.md')
  release = parse_changelog(release_raw)
  master = parse_changelog(master_raw)
  unreleased = master['unreleased'] || {}
  existing = (mode == 'release' ? [release, master] : [master, release]).map { |s| s[version] || {} }
  warn_unknown_categories([unreleased, *existing])

  matched, unmatched = partition_entries(unreleased, pr_list)
  entries = merge_entries(*existing, matched)
  missing_prs(entries, pr_list - bots).each { |n| warn "Warning: picked PR ##{n} has no entry in [#{version}]" }

  out = build_changelog_sections(mode, version, entries, unmatched)
  emit_old_sections_verbatim(out, mode == 'release' ? release_raw : master_raw, skip: ['unreleased', version])
  "#{out.join("\n")}\n"
end

# --- Main ---

if ARGV.empty? || ARGV.intersect?(['-h', '--help'])
  warn <<~HELP
    Usage: ruby release/changelog.rb --mode=MODE --version=VERSION --prs=N,N,N [--bots=N,N]

    Modes:
      release      Build changelog for release branch (empty unreleased + new version)
      master-sync  Build changelog for master (move entries from unreleased to version)

    Options:
      --mode=MODE        release or master-sync (required)
      --version=VERSION  Target version, e.g. v2.9.6 (required)
      --prs=N,N,N        Comma-separated PR numbers (required)
      --bots=N,N         Bot PRs among --prs; no warning when they have no entry
  HELP
  exit(ARGV.empty? ? 1 : 0)
end

args = {}
ARGV.each do |arg|
  next unless (match = arg.match(/^--(\w[\w-]*)=(.+)$/))

  args[match[1]] = match[2]
end

mode = args['mode']
version = args['version']
pr_list, bots = %w[prs bots].map { |k| (args[k] || '').split(',').map(&:strip).reject(&:empty?) }

unless mode && version && pr_list.any?
  warn 'Error: --mode, --version, and --prs are all required. Run with --help.'
  exit 1
end
unless %w[release master-sync].include?(mode)
  warn "Error: --mode must be 'release' or 'master-sync', got '#{mode}'"
  exit 1
end
ReleaseHelpers.validate_version!(version)

puts build_changelog(mode, version, pr_list, bots: bots)
