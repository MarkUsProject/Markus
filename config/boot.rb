require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path(File.join('..', '..', 'Gemfile'), __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
