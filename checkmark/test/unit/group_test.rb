require File.dirname(__FILE__) + '/../test_helper'

class GroupTest < ActiveSupport::TestCase
  
  fixtures  :users, :groups, :assignments
  
  def setup
    @assignment = assignments(:a1)
    @inviter = users(:student5) # user with invite privileges
    @pending = users(:student2) # user invited by inviter_user
    @non_member = users(:student3)
  end
  
  # Test for group membership for users not in a group
  def test_get_group_nil
    assignment_id = @assignment.id
    user_id = users(:admin).id
    
    no_group = Group.find_group(user_id, assignment_id)
    assert_nil no_group
  end
  
  # Test for group membership for users in a group
  def test_get_group_not_nil
    inviter = Group.find_group(@inviter.id, @assignment.id)
    invited = Group.find_group(@pending.id, @assignment.id)
    
    assert_equal 1, inviter.group_number
    assert_equal 1, invited.group_number
    assert_equal 'inviter', inviter.status
    assert_equal 'pending', invited.status
  end
  
  # Test for querying members in the group
  def test_members
    group = Group.find_group(@inviter.id, @assignment.id)
    members = group.members
    
    assert_equal 2, members.length
    members.each do |m|
      assert_equal group.group_number, m.group_number
    end
    
    # don't really belong here but what the heck...
    member_ids = members.map { |m| m.user_id }
    users = User.find(member_ids)
    assert_equal 2, users.length
  end
  
  # Test for rejecting an invite
  def test_reject
    group = Group.find_group(@pending.id, @assignment.id)
    assert_equal 'pending', group.status
    
    group.reject_invite  # no longer in any group
    assert_nil Group.find_group(@pending.id, @assignment.id)
  end
  
  # Test for unallowed invite rejection
  def test_reject_in_group
    group = Group.find_group(@inviter.id, @assignment.id)
    assert_equal 'inviter', group.status
    
    assert_raise RuntimeError do
      group.reject_invite  # cannot drop group
    end
  end
  
  # Test when a user accepts an invite
  def test_accept
    group = Group.find_group(@pending.id, @assignment.id)
    assert_equal 'pending', group.status
    
    group.accept_invite  # joined group
    group.save!
    assert group.in_group?
  end
  
  # Test for invite for a user not in a group
  def test_invite
    group = Group.find_group(@inviter.id, @assignment.id)
    assert_equal 'inviter', group.status
    assert_nil Group.find_group(@non_member.id, @assignment.id)
    
    assert group.invite(@non_member.id)
    non_member_group = Group.find_group(@non_member.id, @assignment.id)
    assert_not_nil non_member_group
    assert_equal group.group_number, non_member_group.group_number
    assert_equal 'pending', non_member_group.status
  end
  
  # Test to see if inviting a user already in a group fails
  def test_invite_in_group
    group = Group.find_group(@inviter.id, @assignment.id)
    assert !group.invite(@pending.id), "Member already in group"
  end
  
  # Test to see if a user inviting someone without invite privileges fail
  def test_invite_not_inviter
    group = Group.find_group(@pending.id, @assignment.id)
    assert !group.invite(@non_member.id)
  end
  
  # Test if users are not allowed to invite users other than students
  def test_invite_invalid
    admin = users(:admin)
    group = Group.find_group(@inviter.id, @assignment.id)
    assert !group.invite(admin.id)
  end
  
  # Test formation of new group
  def test_form_new
    assert_nil Group.find_group(@non_member.id, @assignment.id)
    Group.form_new(@non_member.id, @assignment.id)
    
    group = Group.find_group(@non_member.id, @assignment.id)
    assert_equal 1, group.members.length
    assert_equal 'inviter', group.status
    assert_equal group.user, @non_member
  end
  
  # Test forming a group is invalid if user is in a group already
  def test_form_new_invalid_user
    # TODO check if there's error msgs on the model
    group = Group.find_group(@pending.id, @assignment.id)
    assert_not_nil group
    
    assert_nil Group.form_new(@pending.id, @assignment.id)
    assert_nil Group.form_new(1375, @assignment.id), "invalid user id"
  end
  
  # Test if forming group is not allowed on an individual assignment
  def test_form_new_invalid_assignment
    # TODO check if there's errors on the model
    @assignment2 = assignments(:a2) # an individual assignment
    assert_nil Group.find_group(@non_member.id, @assignment2.id)
    assert_nil Group.form_new(@non_member.id, @assignment2.id)
  end
  
end

