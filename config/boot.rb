require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path(File.join('..', '..', 'Gemfile'), __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

# Required to avoid Psych::SyntaxError
# on Ruby 1.9
if RUBY_VERSION > "1.9"
  require 'yaml'
  YAML::ENGINE.yamler = 'syck' if (defined?(Syck) || defined?(YAML::Syck)) && defined?(YAML::ENGINE)
end
