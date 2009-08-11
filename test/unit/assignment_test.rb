require File.dirname(__FILE__) + '/../test_helper'

class AssignmentTest < ActiveSupport::TestCase
  
  fixtures :assignments, :users, :submissions, :groups
 
  def setup
    setup_group_fixture_repos
  end
  
  def teardown
    destroy_repos
  end
  
  # Test if assignments can fetch the group for a user
  def test_group_by
    a1 = assignments(:assignment_1)
    student1 = users(:student1)
    student5 = users(:student5)
    
    # student 5 is in group 3 with inviter status
    assert_equal groups(:group_1), a1.group_by(student1.id).group
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

  def test_no_groupings_student_list
    a = assignments(:assignment_1)
    assert_equal(3, a.no_grouping_students_list.count, "should be equal
    to 3")
  end

  def test_can_invite_for
    a = assignments(:assignment_1)
    g = groupings(:grouping_2)
    assert_equal(2, a.can_invite_for(g.id).count)
  end

  def test_add_group
    a = assignments(:assignment_1)
    number = a.groupings.count + 1
    a.add_group("new_group_name")
    assert_equal(number, a.groupings.count, "should have added one
    more grouping")
  end
  
  def test_add_group_with_already_existing_name_in_another_assignment_1
    a = assignments(:assignment_3)
    number = a.groupings.count + 1
    a.add_group("Titanic")
    assert_equal(number, a.groupings.count, "should have added one
    more grouping")
  end

  def test_add_group_with_already_existing_name_in_another_assignment_2
    a = assignments(:assignment_3)
    group = Group.all
    number = group.count
    a.add_group("Ukishima Maru")
    group2 = Group.all
    assert_equal(number, group2.count, "should NOT have added a new group")
  end


  def test_add_group_with_already_existing_name_in_this_same_assignment
    a = assignments(:assignment_3)
    a.add_group("Titanic")
    assert_raise RuntimeError do
      a.add_group("Titanic")
    end
  end

end
