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
end

