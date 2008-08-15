require File.dirname(__FILE__) + '/../test_helper'
require 'assignment_file'
require 'submission'

class SubmissionTest < ActiveSupport::TestCase
  
  fixtures :users, :assignments
  fixtures :groups, :assignment_files, :submissions
  
  def setup
    @assignment = assignments(:a1)
    @student = users(:student5) # user with invite privileges
  end
  
  def test_get_group_submissions
    group = Group.find_group(@student.id, @assignment.id)
  end
  
end
