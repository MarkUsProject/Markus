require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class AssignmentTest < ActiveSupport::TestCase
  
  fixtures :assignments, :users, :submissions, :groups, :rubric_criteria, :marks
  set_fixture_class :rubric_criteria => RubricCriterion
 
  def setup
    setup_group_fixture_repos
  end
  
  def teardown
    destroy_repos
  end
  
  def test_validate
    a = Assignment.new
    a.group_min = 3
    a.group_max = 2
    a.short_identifier = "hahaha"
    a.due_date = 30.days.from_now
    assert !a.valid?
  end

  def test_past_due_date?
    assignment = assignments(:assignment_4)
    assert assignment.past_due_date?
  end

  def test_not_past_due_date?
    assignment = assignments(:assignment_3)
    assert !assignment.past_due_date?
  end

  def test_past_collection_date?
    assignment = assignments(:assignment_4)
    assert assignment.past_collection_date?
  end

  def test_not_past_collection_date?
    assignment = assignments(:assignment_3)
    assert !assignment.past_collection_date?
  end

  def test_submission_by
     user = users(:student1)
     assignment = assignments(:assignment_1)
     assert !assignment.submission_by(user)
  end

  def test_total_mark
    assignment = assignments(:assignment_1)
    assert_equal(35.6, assignment.total_mark)
  end

   def test_set_results_average
    assignment = assignments(:assignment_2)
    assignment.set_results_average
    assert_equal(100, assignment.results_average)
   end

  def test_total_criteria_weight
     assignment = assignments(:assignment_2)
     assert_equal(4, assignment.total_criteria_weight)
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
    assert_equal(3, a.no_grouping_students_list.length, "should be equal
    to 3")
  end

  def test_can_invite_for
    a = assignments(:assignment_1)
    g = groupings(:grouping_2)
    assert_equal(2, a.can_invite_for(g.id).length)
  end

  def test_add_group
    a = assignments(:assignment_3)
    number = a.groupings.length + 1
    a.add_group("new_group_name")
    assert_equal(number, a.groupings.length, "should have added one
    more grouping")
  end

  def test_add_group_1
    a = assignments(:assignment_1)
    number = a.groupings.length + 1
    a.add_group("new_group_name")
    assert_equal(number, a.groupings.length, "should have added one
    more grouping")
  end


  def test_add_group_with_already_existing_name_in_another_assignment_1
    a = assignments(:assignment_3)
    number = a.groupings.length + 1
    a.add_group("Titanic")
    assert_equal(number, a.groupings.length, "should have added one
    more grouping")
  end

  def test_add_group_with_already_existing_name_in_another_assignment_2
    a = assignments(:assignment_3)
    group = Group.all
    number = group.length
    a.add_group("Ukishima Maru")
    group2 = Group.all
    assert_equal(number, group2.length, "should NOT have added a new group")
  end

  def test_add_group_with_already_existing_name_in_this_same_assignment
    a = assignments(:assignment_3)
    a.add_group("Titanic")
    assert_raise RuntimeError do
      a.add_group("Titanic")
    end
  end

  def test_create_groupings_when_students_work_alone
    a = assignments(:assignment_2)
    number = Student.all.length
    a.create_groupings_when_students_work_alone
    number_of_groupings = a.groupings.length
    assert_equal(number, number_of_groupings)
   end

   def test_clone_groupings_from_01
     oa = assignments(:assignment_1)
     a = assignments(:assignment_build_on_top_of_1)
     a.clone_groupings_from(oa.id)
     assert_equal(oa.group_min, a.group_min)
   end

   def test_clone_groupings_from_02
     oa = assignments(:assignment_1)
     a = assignments(:assignment_build_on_top_of_1)
     a.clone_groupings_from(oa.id)
     assert_equal(oa.group_max, a.group_max)
   end

   def test_clone_groupings_from_03
     oa = assignments(:assignment_1)
     oa_number = oa.groupings.length
     a = assignments(:assignment_build_on_top_of_1)
     a.clone_groupings_from(oa.id)
     assert_equal(oa_number, a.groupings.length)
   end

   def test_clone_groupings_from_04
     oa = assignments(:assignment_1)
     number = Membership.all.length
     a = assignments(:assignment_build_on_top_of_1)
     a.clone_groupings_from(oa.id)
     assert_not_equal(number, Membership.all.length)
   end

   # TODO create a test for cloning group, when groups already exist

   def test_grouped_students
     a = assignments(:assignment_1)
     assert_equal(5, a.grouped_students.length)
   end

   def test_ungrouped_students
     a = assignments(:assignment_1)
     assert_equal(2, a.ungrouped_students.length)
   end

   def test_valid_groupings
     a = assignments(:assignment_1)
     assert_equal(2, a.valid_groupings.length)
   end

   def test_invalid_groupings
     a = assignments(:assignment_1)
     assert_equal(2, a.invalid_groupings.length)
   end

   def test_assigned_groupings
     a = assignments(:assignment_1)
     assert_equal(1, a.assigned_groupings.length)
   end

   def test_unassigned_groupings
     a = assignments(:assignment_1)
     assert_equal(3, a.unassigned_groupings.length)
   end

   def test_add_csv_group_1
     group = []
     group.push("groupname", "CaptainSparrow" ,"student4", "student5")
     a = assignments(:assignment_3)
     assert a.add_csv_group(group)
   end

   def test_add_csv_group_with_nil_group
     group = []
     a = assignments(:assignment_3)
     assert !a.add_csv_group(group)
   end

   def test_add_csv_group_with_already_existing_name
     group = []
     group.push("Titanic", "CaptainSparrow" ,"student4", "student5")
     a = assignments(:assignment_3)
     assert a.add_csv_group(group)
   end


end
