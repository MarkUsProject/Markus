#!/usr/bin/env ruby
# frozen_string_literal: true

# Changelog Rebuild — Produces a clean Changelog.md after cherry-picks.
#
# Usage:
#   ruby release/changelog.rb --mode=release --version=v2.9.6 --prs=7783,7851,7858
#   ruby release/changelog.rb --mode=master-sync --version=v2.9.6 --prs=7783,7851,7858
#   ruby release/changelog.rb --help
#
# Modes:
#   release      — Empty [unreleased] + new version section + old sections from origin/release
#   master-sync  — Move cherry-picked entries from [unreleased] to new version section on master

require_relative 'common'

CATEGORIES = [
  "### \u{1F6E1}\u{FE0F} Security",
  "### \u{1F6A8} Breaking changes",
  "### \u{2728} New features and improvements",
  "### \u{1F41B} Bug fixes",
  "### \u{1F527} Internal changes"
].freeze

def parse_version_header(line)
  return unless line =~ /^## \[(unreleased|v[\d.]+)\]/i

  Regexp.last_match(1).downcase == 'unreleased' ? 'unreleased' : Regexp.last_match(1)
end

def process_changelog_line(line, result, current)
  ver = parse_version_header(line)
  return init_version_section(result, current, ver) if ver
  return init_category(result, current, line) if line.start_with?('### ') && current[:ver]

  append_entry(result, current, line) if line.start_with?('- ') && current[:ver] && current[:cat]
end

def init_version_section(result, current, ver)
  current[:ver] = ver
  result[:order] << ver
  result[:sections][ver] = {}
  current[:cat] = nil
end

def init_category(result, current, line)
  current[:cat] = line
  result[:sections][current[:ver]][line] ||= []
end

def append_entry(result, current, line)
  result[:sections][current[:ver]][current[:cat]] << line
end

def warn_unknown_categories(sections)
  unknown = sections.values.flat_map(&:keys).uniq - CATEGORIES
  unknown.each { |c| warn "Warning: unknown category '#{c}' — entries may be dropped" } if unknown.any?
end

# Parses Changelog.md into { "sections" => { version => { category => [entries] } }, "version_order" => [...] }
def parse_changelog(text)
  result = { sections: {}, order: [] }
  current = { ver: nil, cat: nil }
  text.each_line { |line| process_changelog_line(line.rstrip, result, current) }
  warn_unknown_categories(result[:sections])
  { 'sections' => result[:sections], 'version_order' => result[:order] }
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
    if line =~ /^## \[(unreleased|v[\d.]+)\]/i
      ver = Regexp.last_match(1).downcase == 'unreleased' ? 'unreleased' : Regexp.last_match(1)
      emitting = skip.exclude?(ver)
    end
    out << line if emitting
  end
end

def partition_entries(unreleased, pr_list)
  matched = {}
  unmatched = {}
  unreleased.each do |cat, entries|
    matched[cat], unmatched[cat] = entries.partition { |e| pr_list.any? { |n| e.match?(/\##{n}(?!\d)/) } }
  end
  [matched, unmatched]
end

def build_changelog_sections(mode, version, matched, unmatched)
  out = ['# Changelog', '', '## [unreleased]', '']
  emit_categories(out, mode == 'release' ? {} : unmatched, skip_empty: false)
  out << "## [#{version}]"
  out << ''
  emit_categories(out, matched, skip_empty: true)
  out
end

def build_changelog(mode, version, pr_list)
  release_raw = ReleaseHelpers.run('git', 'show', 'origin/release:Changelog.md')
  master_raw = ReleaseHelpers.run('git', 'show', 'origin/master:Changelog.md')
  unreleased = parse_changelog(master_raw)['sections']['unreleased'] || {}
  matched, unmatched = partition_entries(unreleased, pr_list)

  out = build_changelog_sections(mode, version, matched, unmatched)
  source_raw = mode == 'release' ? release_raw : master_raw
  emit_old_sections_verbatim(out, source_raw, skip: ['unreleased', version])
  "#{out.join("\n")}\n"
end

# --- Main ---

if ARGV.empty? || ARGV.intersect?(['-h', '--help'])
  warn <<~HELP
    Usage: ruby release/changelog.rb --mode=MODE --version=VERSION --prs=N,N,N

    Modes:
      release      Build changelog for release branch (empty unreleased + new version)
      master-sync  Build changelog for master (move entries from unreleased to version)

    Options:
      --mode=MODE        release or master-sync (required)
      --version=VERSION  Target version, e.g. v2.9.6 (required)
      --prs=N,N,N        Comma-separated PR numbers (required)
  HELP
  exit(ARGV.empty? ? 1 : 0)
end

args = {}
ARGV.each { |a| args[Regexp.last_match(1)] = Regexp.last_match(2) if a =~ /^--(\w[\w-]*)=(.+)$/ }

mode = args['mode']
version = args['version']
pr_list = (args['prs'] || '').split(',').map(&:strip).reject(&:empty?)

unless mode && version && pr_list.any?
  warn 'Error: --mode, --version, and --prs are all required. Run with --help.'
  exit 1
end
unless %w[release master-sync].include?(mode)
  warn "Error: --mode must be 'release' or 'master-sync', got '#{mode}'"
  exit 1
end
ReleaseHelpers.validate_version!(version)

puts build_changelog(mode, version, pr_list)
