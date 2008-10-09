require File.dirname(__FILE__) + '/../test_helper'

# Unit test for user-group relationships
class MembershipTest < ActiveSupport::TestCase
  
  fixtures  :memberships, :users, :groups, :assignments
  
  # test if relationships between user and groups are correct
  def test_user_group_single
    m = memberships(:student4_group2)
    user = users(:student4)
    group = groups(:group2)
    
    assert_equal user, m.user
    assert_equal group, m.group
    
    # test relationships
    assert_equal user.groups.find(:first), group  # user only has one group
    assert_equal group.members.find(:first), user  # group has only one member
  end
  
  # test if relationships between user and groups are correct
  def test_user_group_multiple
    user = users(:student5)
    a1 = assignments(:a1)
    a2 = assignments(:a2)
    
    groups = user.groups
    assigns = groups.map { |g| g.assignments }
    assigns.flatten!.uniq!  # assigns has unique assignments associated with the groups
    
    # user has group for A1 and A2
    assert_equal 2, groups.length
    assert assigns.include?(a1)
    assert assigns.include?(a2)
    
    a1_group = user.group_for(a1.id)
    assert 2, a1_group.members.length
    assert user, a1_group.joined_members.find(:first) # only user has joined a1 group
  end
  
  # Test if fetching a single group of a user for a given assignment works
  def test_group_for_single
    user = users(:student4)
    group = groups(:group2)
    aid = assignments(:a1).id
    
    assert_equal group, user.group_for(aid)
  end
  
  # test if fetching multiple groups of a user works for a given assignment
  def test_group_for_multiple
    user = users(:student5)
    group_a1 = groups(:group3)
    group_a2 = groups(:group4)
    
    a1_id = assignments(:a1).id
    a2_id = assignments(:a2).id
    
    assert_equal group_a1, user.group_for(a1_id)
    assert_equal group_a2, user.group_for(a2_id)
  end
  
end
