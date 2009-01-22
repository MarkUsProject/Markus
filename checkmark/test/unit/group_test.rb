require File.dirname(__FILE__) + '/../test_helper'

class GroupTest < ActiveSupport::TestCase
  
  fixtures  :users, :groups, :assignments, :memberships
  
  # Test if assignments can fetch the group for a user
  def test_inviter
    a1 = assignments(:a1)
    group = groups(:group3)
    student5 = users(:student5)
    student2 = users(:student2)
    
    # assert student 5 and 2 are in the same group for a1
    assert_equal group, student5.group_for(a1)
    assert_equal group, student2.group_for(a1)
    
    # assert student 5 is the inviter from both student5 and student 2 groups
    assert_equal student5, student5.group_for(a1).inviter
    assert_equal student5, student2.group_for(a1).inviter
  end
  
  def test_pending?
  	group = groups(:group3)
  	student5 = users(:student5)
  	student2 = users(:student2)
  	
  	assert !group.pending?(student5)
  	assert group.pending?(student2)
  end
  
  # Test if status is correctly fetched for each user
  def test_status
    group = groups(:group3)
    assert_nil group.status(users(:student4))  # not in group
    assert_equal "inviter", group.status(users(:student5))
    assert_equal "pending", group.status(users(:student2))
  end
  
  # Test if accept changes user status from pending to accepted
  def test_accept
    group = groups(:group3)
    student2 = users(:student2)
    
    assert_equal "pending", group.status(student2)
    assert group.accept(student2)
    assert_equal "accepted", group.status(student2)
  end
  
  # Tests if accept raises an error if a user already in group accepts an invite
  def test_accept_ingroup
    group = groups(:group3)
    student = users(:student5)
    assert_raise RuntimeError do
      group.accept(student)  # student5 is already in group
    end
  end
  
  # Tests if accept raises an error if a user not invited accepts an invite
  def test_accept_uninvited
    group = groups(:group3)
    student = users(:student4)
    assert_raise RuntimeError do
      group.accept(student)  # student4 is not in group and is not invited
    end
  end
  
  # Test if reject removes the user from the group.
  def test_reject
    group = groups(:group3)
    student2 = users(:student2)
    
    assert group.members.include?(student2)
    assert group.reject(student2)
    assert !group.members.include?(student2)
  end
  
  # Tests if reject changes a user status to reject.
  def test_reject_status
  	group = groups(:group3)
    student2 = users(:student2)
    
    assert_equal "pending", group.status(student2)
    assert group.reject(student2)
    assert_equal "rejected", group.status(student2)

    assert "accepted", group.status(student2)
    assert "pending", group.status(student2)
  end
  
  # Test if reject raises an error if a user was not invited.
  def test_reject_invalid_no_user
  	group = groups(:group3)
  	student4 = users(:student4)
  	
  	assert_raise RuntimeError do
  		group.reject(student4) # Student 4 was not invited.
  	end
  end
  
  # Test if reject raises an error if rejecting a user who's status is not pending.
  def test_reject_invalid_status
  	group = groups(:group3)
  	student5 = users(:student5)
  	
  	assert_raise RuntimeError do
  		group.reject(student5) # Student 5 is not pending.
  	end
  end
  
  def test_add_member_valid
    group = groups(:group3)
    student = users(:student1)
    group.add_member(student)
    
    assert_nil group.errors.on_base, group.errors.on_base
    assert group.save, group.errors.on_base
    assert_equal "pending", group.status(student)
  end
  
  def test_add_member_invalid
    group = groups(:group3)
    student = users(:student4) # already in group
    
    group.add_member(student)
    assert !group.errors.on_base.empty?
  end
  
  def test_invite_invalid
    group = groups(:group3)
    
    group.invite(['student4']) # already in group
    assert !group.errors.on_base.empty?
    
    group.invite(['asdfafa']) # user doesn't exists
    assert !group.errors.on_base.empty?
    
    group.invite(['admin']) # not a student
    assert !group.errors.on_base.empty?
  end
  
  # Test if a user can be removed from a group.
  def test_remove_member_in_group
  	group = groups(:group3)
  	student = users(:student5) # In group 3.
  	m = memberships(:student5_group3)
  	group.remove_member(m)
  	
  	assert !group.members.include?(student)
  end
  
  def test_individual
  	group = groups(:group3)
  end
  
  
  
end

