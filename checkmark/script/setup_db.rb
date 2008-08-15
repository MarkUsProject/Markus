#!/usr/bin/env ruby

require 'rubygems'  
require 'active_record'  
require 'yaml'  

# TODO how do I hook this up to RAILS_ENV of config/environment.db?
RAILS_ENV = "development"

# get a database connection
dbconfig = YAML::load(File.open('config/database.yml'))[RAILS_ENV]
ActiveRecord::Base.establish_connection(dbconfig)

# ActiveRecord class declarations for use when parsing
# class names must correspond to existing tables
class User < ActiveRecord::Base; end
class Assignment < ActiveRecord::Base; end
class AssignmentFile < ActiveRecord::Base; end

def load(configFile)
  a = YAML::load(File.open(configFile))
  a.each do |attr, value| 
    yield(value)
  end
end

# Add users from test fixtures users.yml
#load('../test/fixtures/users.yml') { |v| User.new(v).save! }
#puts User.count.to_s + " user(s) has been added to database."

load('config/setup_users.yml') { |v| 
  # Bug on postgres 8.3/activerecord that the user number is being stored 
  # as string in psql but is being compared as integer when using activerecord 
  # find.
  v['user_number'] = v['user_number'].to_s
  User.find_or_create_by_user_number(v).save!
}

load('config/setup_assignments.yml') { |v| 
  # stub assignments to have a due date 3 weeks from now
  Assignment.find_or_create_by_name(v.merge({"due_date" => 3.weeks.from_now })).save!
}