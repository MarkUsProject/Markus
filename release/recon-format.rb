#!/usr/bin/env ruby
# frozen_string_literal: true

# Recon Format: extracts fields from recon JSON for bash consumption.
#
# Usage (reads JSON from stdin):
#   ruby recon-format.rb --summary      # PR counts and dependency info
#   ruby recon-format.rb --plan         # Cherry-pick plan table
#   ruby recon-format.rb --skipped      # Skipped PRs with reasons
#   ruby recon-format.rb --order        # number:ref pairs (one per line)
#   ruby recon-format.rb --pr-list      # Comma-separated PR numbers
#   ruby recon-format.rb --pr-body      # Markdown PR body for gh pr create
#   ruby recon-format.rb --release-notes # Bulleted PR list for gh release create
#   ruby recon-format.rb --help

require 'json'

COMMANDS = %w[--summary --plan --skipped --order --pr-list --pr-body --release-notes].freeze

def migration_note(migrations)
  return 'No migrations' if migrations.empty?

  "MIGRATIONS: #{migrations.map { |m| "##{m['number']} (#{m['files'].join(', ')})" }.join('; ')}. " \
    'Send the migration notice and run the staging checks on ben before production'
end

# Picks before the release PR merges; after it merges they show as shipped in this version.
def release_note_numbers(data)
  shipped_here = data['milestone_prs'].select { |p| p['already_released_in'] == data['version'] }
  (data['proposed_cherry_pick_order'].map { |o| o['number'] } +
   shipped_here.sort_by { |p| p['merged_at'].to_s }.map { |p| p['number'] }).uniq
end

unless COMMANDS.include?(ARGV[0])
  warn 'Usage: echo JSON | ruby recon-format.rb COMMAND'
  warn "Commands: #{COMMANDS.join(' ')}"
  exit(['-h', '--help'].include?(ARGV[0]) ? 0 : 1)
end

data = JSON.parse($stdin.read)
# An older recon.rb emits no migrations field; formatting its output would hide them.
abort 'Error: recon JSON has no "migrations" field (older recon.rb). Run recon.rb from this copy of release/.' \
  unless data.key?('migrations')

prs = data['milestone_prs'].to_h { |p| [p['number'], p] }
order = data['proposed_cherry_pick_order']
changes = data['dependency_changes']

case ARGV[0]
when '--summary'
  puts "Milestone PRs:      #{data['milestone_prs'].length}"
  puts "To cherry-pick:     #{order.length}"
  puts "Skipped:            #{data['skipped'].length}"
  puts ''
  puts changes['summary']
  puts changes['settings']
  puts changes['scheduler']
  puts migration_note(data['migrations'])

when '--plan'
  order.each do |item|
    pr = prs[item['number']]
    deps = (pr['dependencies'] || []).empty? ? '--' : pr['dependencies'].map { |d| "##{d}" }.join(', ')
    printf "  %<order>2d. #%<number>-5d %<title>-50s deps: %<deps>s\n",
           order: item['order'], number: item['number'], title: pr['title'][0..49], deps: deps
  end

when '--skipped'
  data['skipped'].each { |s| puts "  ##{s['number']} — #{s['reason']}" }

when '--order'
  order.each { |item| puts "#{item['number']}:#{item['ref']}" }

when '--pr-list'
  puts order.map { |o| o['number'] }.join(',')

when '--pr-body'
  puts "## Release #{data['version']}"
  puts ''
  puts '### Cherry-picked PRs'
  order.each { |item| puts "- ##{item['number']} — #{prs[item['number']]['title']}" }
  puts ''
  puts '### Notes'
  puts "- Dependencies: #{changes['summary']}"
  puts "- Settings: #{changes['settings']}"
  puts "- Scheduler: #{changes['scheduler']}"
  puts "- Migrations: #{migration_note(data['migrations'])}"

when '--release-notes'
  release_note_numbers(data).each { |num| puts "- ##{num} — #{prs[num]['title']}" }
end
