#!/usr/bin/env ruby

require 'rubygems'  
require 'active_record'  
require 'yaml'
require 'logger'
require 'ruby-debug'

ActiveRecord::Base.logger = Logger.new("debug.log") 

# we default to using development enviroment if RAILS_ENV variable isn't set
ENV['RAILS_ENV'] ||= "development"

# get a database connection
dbconfig = YAML::load(File.open(File.dirname(__FILE__) + '/../config/database.yml'))[ENV['RAILS_ENV']]
ActiveRecord::Base.establish_connection(dbconfig)

# ActiveRecord class declarations for use when parsing
# class names must correspond to existing tables
class User < ActiveRecord::Base; end
class Student < User; end
class Ta < User; end
class Admin < User; end
class Assignment < ActiveRecord::Base; end
class AssignmentFile < ActiveRecord::Base; end
class Group < ActiveRecord::Base; end
class Grouping < ActiveRecord::Base; end
class Submission < ActiveRecord::Base; end
class SubmissionFile < ActiveRecord::Base; end
class Membership < ActiveRecord::Base; end
class StudentMembership < Membership; end
class TAMembership < Membership; end
class Result < ActiveRecord::Base; end

def load(configFile)
  a = YAML::load(File.open(configFile))
  a.each do |attr, value|
    yield(value)
  end
end

# Add admins from test fixtures setup_admins.yml
#puts User.count.to_s + " user(s) has been added to database."

load(File.dirname(__FILE__) + '/../config/setup_admins.yml') { |v| 
  
  # Bug on postgres 8.3/activerecord that the user number is being stored 
  # as string in psql but is being compared as integer when using activerecord 
  # find.
  
  # v is a hash holding information for one user; like { :user_name => 'bla', etc. }
  # branch for different types/roles
  Admin.find_or_create_by_user_name(v).save!
}

load(File.dirname(__FILE__) + '/../config/setup_tas.yml') { |v| 
  
  # Bug on postgres 8.3/activerecord that the user number is being stored 
  # as string in psql but is being compared as integer when using activerecord 
  # find.
  
  # v is a hash holding information for one user; like { :user_name => 'bla', etc. }
  # branch for different types/roles
  Ta.find_or_create_by_user_name(v).save!
}

load(File.dirname(__FILE__) + '/../config/setup_students.yml') { |v| 
  # Bug on postgres 8.3/activerecord that the user number is being stored 
  # as string in psql but is being compared as integer when using activerecord 
  # find.
  
  # v is a hash holding information for one user; like { :user_name => 'bla', etc. }
  # branch for different types/roles
 
  Student.find_or_create_by_user_name(v).save!
}

load('config/setup_assignments.yml') { |v| 
  # stub assignments to have a due date 3 weeks from now
  Assignment.find_or_create_by_name(v.merge({"due_date" => 3.weeks.from_now })).save!
}

load('config/setup_groups.yml') { |v| 
  Group.find_or_create_by_id(v).save!

}

load('config/setup_groupings.yml') { |v| 
  Grouping.find_or_create_by_id(v).save!
}

# create some student_membership records in database
load('config/setup_student_memberships.yml') { |v| 
  # find user_id for provided user_number
  # user_number is stored as a string in the database
  student = Student.find_by_user_number(v['user_number'].to_s) 
  new_record_hash = {}
  v.each do |k, v|
    if k != 'user_number'
     new_record_hash[k] = v
    end
  end
  new_record_hash["user_id"] = student.id
  StudentMembership.create(new_record_hash).save!
}

# create some ta_membership records in database
load('config/setup_ta_memberships.yml') { |v| 
  # find user_id for provided user_number
  ta = Ta.find_by_user_number(v['user_number'].to_s) # user_number is stored as a string in the database
  new_record_hash = {}
  v.each do |k, v|
    if k != 'user_number'
      new_record_hash[k] = v
    end
  end
  new_record_hash["user_id"] = ta.id  
  TAMembership.create(new_record_hash).save!
}

load('config/setup_assignments.yml') { |v| 
  # stub assignments to have a due date 3 weeks from now
  Assignment.find_or_create_by_name(v.merge({"due_date" => 3.weeks.from_now })).save!
}

#load('config/setup_submissions.yml') { |v| 
#  Submission.create(v.merge({"revision_timestamp" => 1.hour.ago})).save!
#}

#load('config/setup_submission_files.yml') { |v| 
#  SubmissionFile.create(v).save!
#}

#load('config/setup_results.yml') { |v| 
#  Result.create(v).save!
#}
