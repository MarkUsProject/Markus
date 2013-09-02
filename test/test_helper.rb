if RUBY_VERSION > '1.9'
  require 'simplecov'
  SimpleCov.coverage_dir('test/coverage')
  SimpleCov.start 'rails' if ENV['COVERAGE']
end

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/setup'
require 'sham'

class ActiveSupport::TestCase

  # Add more helper methods to be used by all tests here...

  setup {
    Sham.reset
  }

  def destroy_repos
    conf = Hash.new
    conf['IS_REPOSITORY_ADMIN'] = true
    conf['REPOSITORY_PERMISSION_FILE'] = 'dummyfile'
    Repository.get_class(REPOSITORY_TYPE, conf).purge_all
  end

  def destroy_converted_pdfs
    FileUtils.rm_rf("#{MarkusConfigurator.markus_config_pdf_storage}/*")
  end

  def equal_dates(date_1, date_2)
    date_1 = Time.parse(date_1.to_s)
    date_2 = Time.parse(date_2.to_s)
    return date_1.eql?(date_2)
  end
end

class ActiveRecord::Base
  unless defined? ANSI_BOLD
    ANSI_BOLD       = "\033[1m"
  end
  unless defined? ANSI_RESET
    ANSI_RESET      = "\033[0m"
  end
  unless defined? ANSI_LGRAY
    ANSI_LGRAY    = "\033[0;37m"
  end
  unless defined? ANSI_GRAY
    ANSI_GRAY     = "\033[1;30m"
  end

  def print_attributes
    max_value = 0
    attributes.each do |name, value|
      max_name = [max_name, name.size].max
      max_value = [max_value, value.to_s.size].max
    end
    attributes.each do |name, value|
      print "    #{ANSI_BOLD}#{name.ljust(max_name)}#{ANSI_RESET}"
      print ':'
      print "#{ANSI_GRAY}#{value.to_s.ljust(max_value)}#{ANSI_RESET}"
      print "\n"
    end
  end

end
