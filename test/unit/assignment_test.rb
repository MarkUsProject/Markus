require File.dirname(__FILE__) + '/../test_helper'
require File.join(File.dirname(__FILE__),'/../blueprints/blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'

class AssignmentTest < ActiveSupport::TestCase
  
  fixtures :all
  set_fixture_class :rubric_criteria => RubricCriterion
  
  should_validate_presence_of :marking_scheme_type
  # Should_validate_presence_of does not work for boolean value false.
  # Using should_allow_values_for instead
  should_allow_values_for :allow_web_submits, true, false
  
  def setup
    setup_group_fixture_repos
  end
  
  context "An assignment" do
    context "as a noteable" do
      should "display for note without seeing an exception" do
        assignment = assignments(:assignment_4)
        assert_nothing_raised do
          assignment.display_for_note
        end
      end
    end # end noteable context
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
    assert_equal(7, a.no_grouping_students_list.size, "should be equal to 5")
  end

  def test_can_invite_for
    a = assignments(:assignment_1)
    g = groupings(:grouping_2)
    assert_equal(6, a.can_invite_for(g.id).size)
  end

  def test_add_group
    a = assignments(:assignment_3)
    number = a.groupings.count + 1
    a.add_group("new_group_name")
    assert_equal(number, a.groupings.count, "should have added one
    more grouping")
  end

  def test_add_group_1
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
    number = group.size
    a.add_group("Ukishima Maru")
    group2 = Group.all
    assert_equal(number, group2.size, "should NOT have added a new group")
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
    number = Student.all.size
    a.create_groupings_when_students_work_alone
    number_of_groupings = a.groupings.size
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
     oa_number = weed_out_hidden_member_groupings(oa.groupings).size
     a = assignments(:assignment_build_on_top_of_1)
     a.clone_groupings_from(oa.id)
     assert_equal(oa_number, a.groupings.size)
   end
   
   def test_clone_groupings_from_04
     oa = assignments(:assignment_1)
     number = StudentMembership.all.size + TAMembership.all.size
     a = assignments(:assignment_build_on_top_of_1)
     a.clone_groupings_from(oa.id)
     assert_not_equal(number, StudentMembership.all.size + TAMembership.all.size)
   end
   
   # One student in a grouping is hidden, so that membership should
   # not be cloned
   context "a group with 3 accepted students" do
     setup do
       # Let's tweak student3 so that their membership_status makes them
       # an accepted part of the group
       memberships(:membership3).membership_status = 'accepted'
       memberships(:membership3).save
       @source = assignments(:assignment_1)
       @target = assignments(:assignment_build_on_top_of_1)
       @group = users(:student1).accepted_grouping_for(@source.id).group
     end

     should "clone all three members if none are hidden" do
       # clone the groupings
       @target.clone_groupings_from(@source.id)
       # and let's make sure that the memberships were cloned
       assert users(:student1).has_accepted_grouping_for?(@target.id)
       assert users(:student2).has_accepted_grouping_for?(@target.id)
       assert users(:student3).has_accepted_grouping_for?(@target.id)
       @group.reload
       assert !@group.groupings.find_by_assignment_id(@target.id).nil?
     end

     should "ignore a blocked student during cloning" do
       student = users(:student1)
       # hide the student
       student.hidden = true
       student.save
       # clone the groupings
       @target.clone_groupings_from(@source.id)
       # make sure the membership wasn't created for the hidden
       # student
       assert !student.has_accepted_grouping_for?(@target.id)
       # and let's make sure that the other memberships were cloned
       assert users(:student2).has_accepted_grouping_for?(@target.id)
       assert users(:student3).has_accepted_grouping_for?(@target.id)
       @group.reload
       assert !@group.groupings.find_by_assignment_id(@target.id).nil?
     end
     
     should "ignore two blocked students during cloning" do
       # hide the students
       users(:student1).hidden = true
       users(:student1).save
       users(:student2).hidden = true
       users(:student2).save
       # clone the groupings
       @target.clone_groupings_from(@source.id)
       # make sure the membership wasn't created for the hidden
       # student
       assert !users(:student1).has_accepted_grouping_for?(@target.id)
       assert !users(:student2).has_accepted_grouping_for?(@target.id)
       # and let's make sure that the other membership was cloned
       assert users(:student3).has_accepted_grouping_for?(@target.id)
       # and that the proper grouping was created
       @group.reload
       assert !@group.groupings.find_by_assignment_id(@target.id).nil?       
     end
     
     should "ignore grouping if all students hidden" do
       # hide the students
       users(:student1).hidden = true
       users(:student1).save
       users(:student2).hidden = true
       users(:student2).save
       users(:student3).hidden = true
       users(:student3).save
       
       # Get the Group that these students blong to for assignment_1
       assert users(:student1).has_accepted_grouping_for?(@source.id)
       # clone the groupings
       @target.clone_groupings_from(@source.id)
       # make sure the membership wasn't created for the hidden
       # student
       assert !users(:student1).has_accepted_grouping_for?(@target.id)
       assert !users(:student2).has_accepted_grouping_for?(@target.id)
       assert !users(:student3).has_accepted_grouping_for?(@target.id)
       # and let's make sure that the grouping wasn't cloned
       @group.reload
       assert @group.groupings.find_by_assignment_id(@target.id).nil?
     end     

   end
   
   context "an assignment with previously existing groups" do
     setup do
       # Let's tweak student3 so that their membership_status makes them
       # an accepted part of the group
       memberships(:membership3).membership_status = 'accepted'
       memberships(:membership3).save
       @source = assignments(:assignment_1)
       @target = assignments(:assignment_2)
       @group = users(:student1).accepted_grouping_for(@source.id).group     
       assert @source.groupings.size > 0
     end
     should "destroy all previous groupings if cloning was successful" do
       old_groupings = @target.groupings
       @target.clone_groupings_from(@source.id)
       @target.reload
       old_groupings.each do |old_grouping|
         assert !@target.groupings.include?(old_grouping)
       end
     end
   end

   def test_grouped_students
     a = assignments(:assignment_1)
     assert_equal(6, a.grouped_students.size)
   end

   def test_ungrouped_students
     a = assignments(:assignment_1)
     assert_equal(5, a.ungrouped_students.size)
   end

   def test_valid_groupings
     a = assignments(:assignment_1)
     assert_equal(2, a.valid_groupings.size)
   end

   def test_invalid_groupings
     a = assignments(:assignment_1)
     assert_equal(2, a.invalid_groupings.size)
   end

   def test_assigned_groupings
     a = assignments(:assignment_1)
     assert_equal(1, a.assigned_groupings.size)
   end

   def test_unassigned_groupings
     a = assignments(:assignment_1)
     assert_equal(3, a.unassigned_groupings.size)
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
   
   def test_get_svn_export_commands
     a = assignments(:assignment_2)
     expected_array = []
          
     a.submissions.each do |submission|
       grouping = submission.grouping
       group = grouping.group
       expected_array.push("svn export -r #{submission.revision_number} #{REPOSITORY_EXTERNAL_BASE_URL}/group_#{group.id} \"#{group.group_name}\"")
     end
     assert_equal expected_array, a.get_svn_export_commands
   end

  def test_get_svn_export_commands_with_spaces_in_group_name
    a = assignments(:assignment_2)
    # Put " Test" after every group name"
    Group.all.each do |group|
      group.group_name = group.group_name + " Test"
      group.save
    end
    expected_array = []
          
    a.submissions.each do |submission|
      grouping = submission.grouping
      group = grouping.group
      expected_array.push("svn export -r #{submission.revision_number} #{REPOSITORY_EXTERNAL_BASE_URL}/group_#{group.id} \"#{group.group_name}\"")
    end
    assert_equal expected_array, a.get_svn_export_commands
  end
  
  context "An assignment instance" do
    should "be able to generate a detailed CSV report of marks (including criteria)" do
      a = assignments(:assignment_1) # we require assignment_1 here
      assert_equal "Captain Nemo", a.short_identifier, "We need assignment 1 for this test!"
      out_of = a.total_mark
      rubric_criteria = a.rubric_criteria
      expected_string = ""
      Student.all.each do |student|
        fields = []
        fields.push(student.user_name)
        grouping = student.accepted_grouping_for(a.id)
        if grouping.nil? || !grouping.has_submission?
          fields.push('')
          rubric_criteria.each do |rubric_criterion|
            fields.push('')
            fields.push(rubric_criterion.weight)
          end
          fields.push('')
          fields.push('')
        else
          submission = grouping.get_submission_used
          fields.push(submission.result.total_mark / out_of * 100)
          rubric_criteria.each do |rubric_criterion|
            mark = submission.result.marks.find_by_markable_id_and_markable_type(rubric_criterion.id, "RubricCriterion")
            if mark.nil?
              fields.push('')
            else
              fields.push(mark.mark || '')
            end 
            fields.push(rubric_criterion.weight)
          end
          fields.push(submission.result.get_total_extra_points)
          fields.push(submission.result.get_total_extra_percentage)
        end
        # push grace credits info
        grace_credits_data = student.remaining_grace_credits.to_s + "/" + student.grace_credits.to_s
        fields.push(grace_credits_data)
     
        expected_string += fields.to_csv
      end
      assert_equal expected_string, a.get_detailed_csv_report, "Detailed CSV report is wrong!"
    end
    
    should "be able to generate a simple CSV report of marks" do
      a = assignments(:assignment_6) # we require assignment_6 here
      assert_equal "A6", a.short_identifier, "We need assignment 6 for this test!"
      expected_string = ""
      Student.all.each do |student|
        fields = []
        fields.push(student.user_name)         
        grouping = student.accepted_grouping_for(a.id)
        if grouping.nil? || !grouping.has_submission?
          fields.push('')
        else
          submission = grouping.get_submission_used
          fields.push(submission.result.total_mark / a.total_mark * 100)                    
        end
        expected_string += fields.to_csv
      end
      assert_equal expected_string, a.get_simple_csv_report, "Simple CSV report is wrong!"
    end
    
    should "be able to get a list of repository access URLs for each group" do
      expected_string = ''
      assignment = assignments(:assignment_6)
      assignment.groupings.each do |grouping|
        group = grouping.group
        expected_string += [group.group_name,group.repository_external_access_url].to_csv
      end
      assert_equal expected_string, assignment.get_svn_repo_list, "Repo access url list string is wrong!"
    end
    
  end # end assignment instance context
  
  private
  def weed_out_hidden_member_groupings(groupings)
    result = []
    groupings.each do |grouping|
      unhidden = grouping.accepted_student_memberships.select do |m|
        !m.user.hidden
      end
      if !unhidden.empty?
        result << grouping
      end
    end
    return result
  end
end
