#!/usr/bin/env ruby
# frozen_string_literal: true

# Lockfile Conflict Resolver: resolves conflict blocks in Gemfile.lock,
# package.json, and package-lock.json during release cherry-picks.
#
# Usage: ruby release/lockres.rb <conflicted_file> [...]
#
# Policy: both sides of a conflict block must be version lines for the same
# keys; the higher version wins per key (a release branch can be ahead of a
# PR's base. In v2.10.2, release had jwt 3.2.0 while PRs expected 2.10.x.
# Anything else exits 1 with the block printed, so a human resolves it.
# Every decision prints. The caller's contamination check (verify.rb) runs
# after. For version-level intent, read the printed decisions.
#
# Plain Ruby, zero gems: Gem::Version is stdlib.

KEY_RE = /^(\s*)"?([^"(:]+?)"?\s*[:(]\s*"?[\^~><=\s]*([0-9][^",)\s]*)/
BLOCK_RE = /^<{7} [^\n]*\n(.*?)^={7}\n(.*?)^>{7} [^\n]*\n/m

def parse_line(line)
  match = KEY_RE.match(line)
  return unless match

  { key: match[1] + match[2], version: match[3], line: line }
end

def refuse(path, text)
  warn "REFUSE #{path}:\n#{text}"
  exit 1
end

def pick_line(path, ours, theirs)
  refuse(path, "#{ours[:line]}\nvs\n#{theirs[:line]}") unless ours[:key] == theirs[:key]
  winner = Gem::Version.new(ours[:version]) >= Gem::Version.new(theirs[:version]) ? ours : theirs
  puts "  #{path}: #{ours[:key].strip} #{ours[:version]} | #{theirs[:version]} -> #{winner[:version]}"
  winner[:line]
rescue ArgumentError
  refuse(path, "#{ours[:line]}\nvs\n#{theirs[:line]}")
end

def resolve_block(path, ours_text, theirs_text)
  ours = ours_text.lines.map { |l| parse_line(l) }
  theirs = theirs_text.lines.map { |l| parse_line(l) }
  refuse(path, ours_text + theirs_text) if ours.length != theirs.length || (ours + theirs).any?(&:nil?)

  ours.zip(theirs).map { |o, t| pick_line(path, o, t) }.join
end

if ARGV.empty? || ARGV.intersect?(['-h', '--help'])
  warn 'Usage: ruby release/lockres.rb <conflicted_file> [...]'
  exit ARGV.empty? ? 1 : 0
end

ARGV.each do |path|
  content = File.read(path)
  resolved = content.gsub(BLOCK_RE) { resolve_block(path, Regexp.last_match(1), Regexp.last_match(2)) }
  File.write(path, resolved)
end
