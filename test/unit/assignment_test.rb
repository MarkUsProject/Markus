require File.dirname(__FILE__) + '/../test_helper'

class AssignmentTest < ActiveSupport::TestCase
  
  fixtures :assignments, :users, :submissions
  
  # Test if assignments can fetch the group for a user
  def test_group_by
    a1 = assignments(:assignment_1)
    student1 = users(:student1)
    student5 = users(:student5)
    
    # student 5 is in group 3 with inviter status
    assert_equal groups(:group_1), a1.group_by(student1.id).group
  end
  
  # Test if an individual assignment will give us a newly created
  # UserSubmission instance
#  def test_empty_submission_by_user
#    indiv_assignment = assignments(:assignment_1)
#    user = users(:student5)
#   
#    submission = indiv_assignment.submission_by(user)
#    assert submission.is_a?(UserSubmission)
#    assert_nil submission.grouping_id
#    assert_equal user, submission.user
#  end
  
  
  # Test if an individual assignment will give us an existing
  # UserSubmission instance
  def test_existing_submission_by_group
    group_assignment = assignments(:assignment_2)
    user = users(:student5)
    # group = user.group_for(group_assignment.id)
    
    # submission = group_assignment.submission_by(user)
    # assert submission.is_a?(GroupSubmission)
    # assert_nil submission.user_id
    # assert_equal group, submission.grouping
  end
  
  
  # Validation Tests -------------------------------------------------------
  
  # Tests if group limit validations are met
  def test_group_limit
    a1 = assignments(:assignment_1)
    
    a1.group_min = 0
    assert !a1.valid?, "group_min cannot be 0"
    
    a1.group_min = -5
    assert !a1.valid?, "group_min cannot be a negative number"
    
    a1.group_max = 4 # must be > group_min
    a1.group_min = nil
    assert !a1.valid?, "group_min cannot be nil"
    
    a1.group_min = 2
    assert a1.valid?, "group_min < group_max"
  end
end
