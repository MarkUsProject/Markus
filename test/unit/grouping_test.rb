require 'test_helper'
require 'shoulda'

class GroupingTest < ActiveSupport::TestCase
  fixtures :groups
  fixtures :assignments
  fixtures :groupings
  should_belong_to :group
  should_belong_to :assignment
  should_have_many :memberships
  should_have_many :submissions

  def test_grouping_should_not_save_without_assignment
    grouping = Grouping.new
    grouping.group = groups(:group_1)
    assert !grouping.save, "Saved the grouping without assignment"
  end

  def test_should_not_save_without_group
    grouping = Grouping.new
    grouping.assignment = assignments(:assignment_1)
    assert !grouping.save, "Saved the grouping without group"
  end


  def test_save_grouping
    grouping = Grouping.new
    grouping.assignment = assignments(:assignment_2)
    grouping.group = groups(:group_5)
    # assert grouping.save, "Save the grouping"
  end

  def test_if_has_ta_for_marking_true
    grouping = groupings(:grouping_2)
    assert grouping.has_ta_for_marking?
  end

  def test_if_has_ta_for_marking_false
     grouping = groupings(:grouping_1)
     assert !grouping.has_ta_for_marking?
  end

  def test_get_ta_names
     grouping = groupings(:grouping_2)
     ta = users(:ta1)
     assert_equal(ta.user_name, grouping.get_ta_names[0], "Doesn't return the right name!")
  end

  def test_if_has_ta_for_marking_false
     grouping = groupings(:grouping_1)
     assert !grouping.has_ta_for_marking?
  end

  def test_should_return_inviter
    grouping = groupings(:grouping_1)
    invite = users(:student1)
    assert_equal(grouping.inviter.user_name, invite.user_name, "should
    return inviter" )
  end

  def test_is_inviter_true
     grouping = groupings(:grouping_1)
     student = users(:student1)
     assert grouping.is_inviter?(student), "should return true as student
     is the inviter"
  end

  def test_is_inviter_false
     grouping = groupings(:grouping_1)
     student = users(:student2)
     assert !grouping.is_inviter?(student), "should return false as student
     is NOT the inviter"
  end


  def test_should_return_true_for_pending
     grouping = groupings(:grouping_2)
     student = users(:student5)
     assert grouping.pending?(student)
  end

  def test_should_return_false_for_pending
     grouping = groupings(:grouping_2)
     student = users(:student4)
     assert !grouping.pending?(student)
  end

  def test_should_return_inviter
     grouping = groupings(:grouping_2)
     student = users(:student4)
     assert_equal(grouping.membership_status(student), "inviter", "should
     return inviter")
  end

  def test_should_return_pending
     grouping = groupings(:grouping_2)
     student = users(:student5)
     assert_equal(grouping.membership_status(student), "pending", "should
     return pending")
  end

  def test_should_return_accepted
     grouping = groupings(:grouping_1)
     student = users(:student2)
     assert_equal(grouping.membership_status(student), "accepted",
     "should return accepted")
  end

  def test_should_return_rejected
     grouping = groupings(:grouping_1)
     student = users(:student3)
     assert_equal(grouping.membership_status(student), "rejected",
     "should return rejected")
  end

  def test_should_return_nil_for_membership_status
    grouping = groupings(:grouping_1)
    student = users(:student5)
    assert_nil(grouping.membership_status(student), "Student is not a
    member of this group - should return nil")
  end

  def test_student_membership_number
    grouping = groupings(:grouping_1)
    assert_equal(grouping.student_membership_number, 2, "There are
    three members of this group, one is rejected -- should return 2")
  end

  def test_if_grouping_is_valid
    grouping = groupings(:grouping_1)
    assert grouping.valid?, "This grouping has the right amount of
    memberships. It should be valid"
  end

  ############################################
  #
  # TODO: create other fixtures for the case:
  # Group not valid by number pf memberships
  # group valid by instructors validation
  #
  ###########################################

  def test_if_grouping_has_submissions
    grouping = groupings(:grouping_1)
    assert !grouping.has_submission?
  end

  ####################################################
  #
  # TODO: create other fixtures for grouping having submissions
  #
  # TODO:test method get_submission_used
  #
  ####################################################

  def test_decline_invitation
     grouping = groupings(:grouping_2)
     student = users(:student5)
     grouping.decline_invitation(student)
     assert !grouping.pending?(student), "student has just decline this invitation. Membership_status should be 'rejected'"
  end

  def test_remove_rejected_member
     grouping = groupings(:grouping_1)
     student = users(:student3)
     membership = memberships(:membership3)
     grouping.remove_rejected(membership)
     assert_nil(grouping.membership_status(student), "This student has
     just been deleted. He's not part of this group anymore -
     membership_status should be nil")
  end

  def test_remove_member
     grouping = groupings(:grouping_1)
     membership = memberships(:membership2)
     student = users(:student2)
     grouping.remove_member(membership)
     assert_nil(grouping.membership_status(student), "This student has
     just been deleted from this group. His membership status should be
     nil")
  end

  def test_remove_member_when_member_inviter
     grouping = groupings(:grouping_1)
     membership = memberships(:membership1)
     student = users(:student1)
     grouping.remove_member(membership)
     assert_nil(grouping.membership_status(student), "This student has
     just been deleted from this group. His membership status should be
     nil")
  end

  def test_remove_member_when_member_inviter2
     grouping = groupings(:grouping_1)
     membership = memberships(:membership2)
     student = users(:student2)
     grouping.remove_member(membership)
     assert_not_nil grouping.inviter 
  end
  
  def test_cant_invite_hidden_student
    grouping = groupings(:grouping_1)
    hidden = users(:hidden_student)
    original_number_of_members = grouping.memberships.count
    grouping.invite(hidden.user_name)
    assert_equal original_number_of_members, grouping.memberships.count
  end
  
  def test_cant_add_member_hidden_student
    grouping = groupings(:grouping_1)
    hidden = users(:hidden_student)
    original_number_of_members = grouping.memberships.count
    grouping.add_member(hidden)
    assert_equal original_number_of_members, grouping.memberships.count
  end
  
  # TA Assignment tests
  def test_assign_tas_to_grouping
    grouping = groupings(:grouping_1)
    ta = users(:ta1)
    assert_equal 0, grouping.ta_memberships.count, "Got unexpected TA membership count"
    grouping.add_ta_by_id(ta.id)
    assert_equal 1, grouping.ta_memberships.count, "Got unexpected TA membership count"  
  end
  
  def test_cant_assign_tas_multiple_times
    grouping = groupings(:grouping_1)
    ta = users(:ta1)
    assert_equal 0, grouping.ta_memberships.count, "Got unexpected TA membership count"
    grouping.add_ta_by_id(ta.id)
    grouping.add_ta_by_id(ta.id)
    assert_equal 1, grouping.ta_memberships.count, "Got unexpected TA membership count"  
  end
  
  def test_unassign_tas_to_grouping
    grouping = groupings(:grouping_1)
    ta = users(:ta1)
    assert_equal 0, grouping.ta_memberships.count, "Got unexpected TA membership count"
    grouping.add_ta_by_id(ta.id)
    assert_equal 1, grouping.ta_memberships.count, "Got unexpected TA membership count"
    grouping.remove_ta_by_id(ta.id)
    assert_equal 0, grouping.ta_memberships.count, "Got unexpected TA membership count"  
  end
  
  def test_assign_tas_to_grouping_by_user_name_array
    grouping = groupings(:grouping_1)
    user_name_array = ['ta1', 'ta2']
    assert_equal 0, grouping.ta_memberships.count, "Got unexpected TA membership count"
    grouping.add_tas_by_user_name_array(user_name_array)
    assert_equal 2, grouping.ta_memberships.count, "Got unexpected TA membership count"  
  end
  
  def test_ta_assignment_by_csv_file
    assignment = assignments(:assignment_1)
    
    grouping_1 = Group.find_by_group_name('Titanic').grouping_for_assignment(assignment.id)
    grouping_1_orig_count = grouping_1.ta_memberships.count
    
    grouping_2 = Group.find_by_group_name('Ukishima Maru').grouping_for_assignment(assignment.id)
    grouping_2_orig_count = grouping_2.ta_memberships.count
        
    grouping_3 = Group.find_by_group_name('Blanche Nef').grouping_for_assignment(assignment.id)
    grouping_3_orig_count = grouping_3.ta_memberships.count
    
    csv_file_data = 
'''Titanic,ta1
Ukishima Maru,ta1,ta2
Blanche Nef,ta2'''
    failures = Grouping.assign_tas_by_csv(csv_file_data, assignment.id)

    assert_equal grouping_1_orig_count + 1, grouping_1.ta_memberships.count, "Got unexpected TA membership count"
    
    # This should be +1 ta_memberships, because one of those TAs is already
    # assigned to Ukishima Maru in the fixtures
    assert_equal grouping_2_orig_count + 1, grouping_2.ta_memberships.count, "Got unexpected TA membership count"

    assert_equal grouping_3_orig_count + 1, grouping_3.ta_memberships.count, "Got unexpected TA membership count"
    
    assert_equal 0, failures.count, "Received unexpected failures"

  end

  def test_ta_assignment_by_bad_csv_file
    assignment = assignments(:assignment_1)
    
    grouping_1 = Group.find_by_group_name('Titanic').grouping_for_assignment(assignment.id)
    grouping_1_orig_count = grouping_1.ta_memberships.count
    
    grouping_2 = Group.find_by_group_name('Ukishima Maru').grouping_for_assignment(assignment.id)
    grouping_2_orig_count = grouping_2.ta_memberships.count
        
    grouping_3 = Group.find_by_group_name('Blanche Nef').grouping_for_assignment(assignment.id)
    grouping_3_orig_count = grouping_3.ta_memberships.count
    
    csv_file_data = 
'''Titanic,ta1
Uk125125ishima Maru,ta1,ta2
Blanche Nef,ta2'''
    failures = Grouping.assign_tas_by_csv(csv_file_data, assignment.id)
    
    assert_equal grouping_1_orig_count + 1, grouping_1.ta_memberships.count, "Got unexpected TA membership count"

    assert_equal grouping_2_orig_count + 0, grouping_2.ta_memberships.count, "Got unexpected TA membership count"

    assert_equal grouping_3_orig_count + 1, grouping_3.ta_memberships.count, "Got unexpected TA membership count"
    
    assert_equal failures[0], "Uk125125ishima Maru", "Didn't return correct failure"

  end

  #########################################################
  #
  # TODO: create test for create_grouping_repository_factory
  #
  #########################################################"
end
