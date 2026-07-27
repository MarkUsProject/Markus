#!/usr/bin/env ruby
# frozen_string_literal: true

# Recon Format — Extracts fields from recon JSON for bash consumption.
#
# Usage (reads JSON from stdin):
#   ruby recon-format.rb --summary      # PR counts and dependency info
#   ruby recon-format.rb --plan         # Cherry-pick plan table
#   ruby recon-format.rb --order        # number:ref pairs (one per line)
#   ruby recon-format.rb --pr-list      # Comma-separated PR numbers
#   ruby recon-format.rb --pr-body      # Markdown PR body for gh pr create
#   ruby recon-format.rb --release-notes # Bulleted PR list for gh release create

require 'json'

data = JSON.parse($stdin.read)
prs = data['milestone_prs'].index_by { |p| p['number'] }
order = data['proposed_cherry_pick_order']
skipped = data['skipped']

case ARGV[0]
when '--summary'
  puts "Milestone PRs:      #{data['milestone_prs'].length}"
  puts "To cherry-pick:     #{order.length}"
  puts "Already on release: #{skipped.length}"
  puts ''
  puts data['dependency_changes']['summary']
  puts data['dependency_changes']['settings']

when '--plan'
  order.each do |item|
    pr = prs[item['number']]
    deps = (pr['dependencies'] || []).empty? ? '--' : pr['dependencies'].map { |d| "##{d}" }.join(', ')
    printf "  %<order>2d. #%<number>-5d %<title>-50s deps: %<deps>s\n",
           order: item['order'], number: item['number'], title: pr['title'][0..49], deps: deps
  end

when '--skipped'
  skipped.each { |s| puts "  ##{s['number']} — #{s['reason']}" }

when '--order'
  order.each { |item| puts "#{item['number']}:#{item['ref']}" }

when '--pr-list'
  puts order.pluck('number').join(',')

when '--pr-body'
  puts "## Release #{data['version']}"
  puts ''
  puts '### Cherry-picked PRs'
  order.each { |item| puts "- ##{item['number']} — #{prs[item['number']]['title']}" }
  puts ''
  puts '### Notes'
  puts "- Dependencies: #{data['dependency_changes']['summary']}"
  puts "- Settings: #{data['dependency_changes']['settings']}"

when '--release-notes'
  order.each { |item| puts "- ##{item['number']} — #{prs[item['number']]['title']}" }

else
  warn 'Usage: echo JSON | ruby recon-format.rb COMMAND'
  warn 'Commands: --summary --plan --skipped --order --pr-list --pr-body --release-notes'
  exit 1
end
