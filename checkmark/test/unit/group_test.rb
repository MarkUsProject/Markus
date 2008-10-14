require File.dirname(__FILE__) + '/../test_helper'

class GroupTest < ActiveSupport::TestCase
  
  fixtures  :users, :groups, :assignments
  
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
  
  # Test if status is correctly fetched for each user
  def test_status
    group = groups(:group3)
    assert_nil group.status(users(:student4))  # not in group
    assert "inviter", group.status(users(:student5))
    assert "pending", group.status(users(:student2))
  end
  
  # Test if accept changes user status from pending to accepted
  def test_accept
    group = groups(:group3)
    student2 = users(:student2)
    
    assert "pending", group.status(student2)
    assert group.accept(student2)
    assert "accepted", group.status(student2)
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
  
  # Test if accept changes user status from pending to accepted
  def test_reject
    group = groups(:group3)
    student2 = users(:student2)
    
    assert "pending", group.status(student2)
    assert group.members.include?(student2)
    assert group.reject(student2)
    assert !group.members.include?(student2)
  end
  
  def test_add_member_admin
    
  end
  
end

