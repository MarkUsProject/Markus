require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class AssignmentTest < ActiveSupport::TestCase

  should have_many :rubric_criteria
  should have_many :flexible_criteria
  should have_many :assignment_files
  should have_many :test_files
  should have_many :criterion_ta_associations
  should have_one  :submission_rule

  should have_many :annotation_categories

  should have_many :groupings
  should have_many(:ta_memberships).through(:groupings)
  should have_many(:student_memberships).through(:groupings)
  should have_many(:tokens).through(:groupings)

  should have_many(:submissions).through(:groupings)
  should have_many(:groups).through(:groupings)

  should have_many :notes

  should have_many :section_due_dates
  should have_one  :assignment_stat

  should validate_presence_of :repository_folder
  should validate_presence_of :group_min

  should validate_numericality_of :group_min
  should validate_numericality_of :group_max
  should validate_numericality_of :tokens_per_day

  should validate_presence_of :submission_rule

  should validate_presence_of :marking_scheme_type

  # since allow_web_submits is a boolean, should validate_presence_of does
  # not work: see the Rails API documentation for should validate_presence_of
  # (Model validations)
  # should validate_presence_of does not work for boolean value false.
  # Using should allow_value instead
  should allow_value(true).for(:allow_web_submits)
  should allow_value(false).for(:allow_web_submits)
  should allow_value(true).for(:display_grader_names_to_students)
  should allow_value(false).for(:display_grader_names_to_students)

  def teardown
    destroy_repos
  end

  context 'validate' do
    setup do
      @a = Assignment.make
    end

    should validate_presence_of     :short_identifier
    should validate_uniqueness_of   :short_identifier

    should 'work' do
      assert @a.valid?
    end
  end


  should 'catch max group size less than min group size' do
    a = Assignment.new(:group_min => 3,:group_max=> 2)
    assert !a.valid?
  end

  should 'catch an invalid date' do
    a = Assignment.new(:due_date => '2020/02/31')  #31st day of february
    assert !a.valid?
  end

  should 'catch a zero group_min' do
    a = Assignment.new(:group_min => 0)
    assert !a.valid?
  end

  should 'catch a negative group_min' do
    a = Assignment.new(:group_min => -5)
    assert !a.valid?
  end

  should 'catch a nil group_min' do
    a = Assignment.new(:group_min => nil)
    assert !a.valid?
  end

  should 'catch a negative tokens_per_day value' do
    a = Assignment.new(:tokens_per_day => '-10')
    assert !a.valid?, 'assignment expected to be invalid when tokens_per_day is < 0'
  end

  context 'A past due assignment w/ No Late submission rule' do
    context 'without sections' do
      setup do
        @assignment = Assignment.make(:due_date => 2.days.ago)
      end

      should 'return true on past_due_date? call' do
        assert @assignment.past_due_date?
      end
      should 'return the last due date' do
        assert_equal 2.days.ago.day(), @assignment.latest_due_date.day()
      end

      should 'return true on past_collection_date? call' do
        assert @assignment.past_collection_date?
      end

      should 'return an array with only "Due Date"' do
        assert_equal @assignment.what_past_due_date, ['Due Date']
      end
    end

    context 'with a section' do
      setup do
        @assignment = Assignment.make(:due_date => 2.days.ago, :section_due_dates_type => true)
        @section = Section.make(:name => 'section_name')
        SectionDueDate.make(:section => @section, :assignment => @assignment,
                            :due_date => 1.day.ago)
        student = Student.make(:section => @section)
        @grouping = Grouping.make(:assignment => @assignment)
        StudentMembership.make(:grouping => @grouping,
                  :user => student,
                  :membership_status => StudentMembership::STATUSES[:inviter])
      end

      should 'return the normal due date for section due date' do
        assert @assignment.section_due_date(@section)
      end

      should 'return true on section_past_due_date? call' do
        assert @assignment.section_past_due_date?(@grouping)
      end

      should 'return an array with the section name past' do
        assert_equal @assignment.what_past_due_date, %w(section_name)
      end

      context 'and another' do
        setup do
          @section = Section.make(:name => 'section_name2')
          SectionDueDate.make(:section => @section, :assignment => @assignment,
                              :due_date => 1.day.ago)
          student = Student.make(:section => @section)
          @grouping = Grouping.make(:assignment => @assignment)
          StudentMembership.make(:grouping => @grouping,
                                 :user => student,
                                 :membership_status => StudentMembership::STATUSES[:inviter])
        end

        should 'return an array with the sections name past' do
          assert_equal @assignment.what_past_due_date, %w(section_name section_name2)
        end
      end
    end
  end

  context 'A before due assignment w/ No Late submission rule' do
    setup do
      @assignment = Assignment.make({:due_date => 2.days.from_now})
    end

    should 'return false on past_due_date? call' do
      assert !@assignment.past_due_date?
    end

    should 'return false on past_collection_date? call' do
      assert !@assignment.past_collection_date?
    end

    should 'return an array with nothing inside' do
      assert_equal @assignment.what_past_due_date, []
    end

  end

  context 'after remarks are due assignment' do
    setup do
      @assignment = Assignment.make({:remark_due_date => 2.days.ago})
    end

    should 'return true on past_remark_due_date? call' do
      assert @assignment.past_remark_due_date?
    end
  end

  context 'before remarks are due assignment' do
    setup do
      @assignment = Assignment.make({:remark_due_date => 2.days.from_now})
    end

    should 'return false on past_remark_due_date? call' do
      assert !@assignment.past_remark_due_date?
    end
  end

  context 'An Assignment' do
    setup do
      @assignment = Assignment.make(:group_name_autogenerated => false)
    end

    should "return false if a student hasn't submitted" do
      student = Student.make
      assert !@assignment.submission_by(student)
    end

    should 'return 0 if no tas have been assigned' do
      assert @assignment.tas.size == 0
    end

    context 'with multiple tas assigned' do
      setup do
        ta1 = Ta.make
        grouping = Grouping.make(:assignment => @assignment)
        StudentMembership.make({:grouping => grouping, :membership_status => StudentMembership::STATUSES[:accepted]})
        TaMembership.make({:user_id => ta1.id, :grouping => grouping, :membership_status => StudentMembership::STATUSES[:accepted]})

        ta2 = Ta.make
        grouping = Grouping.make(:assignment => @assignment)
        StudentMembership.make(
              {:grouping => grouping,
               :membership_status => StudentMembership::STATUSES[:accepted]})
        TaMembership.make(
              {:user_id => ta2.id,
               :grouping => grouping,
               :membership_status => StudentMembership::STATUSES[:accepted]})
      end

      should 'return 2 tas assigned' do
        assert @assignment.tas.size == 2
      end
    end

    should 'return 0 if no submissions have been graded' do
      assert @assignment.graded_submissions.size == 0
    end

    context 'with some assignments submitted once' do
      setup do
        grouping = Grouping.make(:assignment => @assignment)
        2.times do
          grouping = Grouping.make(:assignment => @assignment)
          sub = Submission.make(:grouping => grouping)
        end
      end

      should 'have 2 groups submitted' do
        assert @assignment.groups_submitted.size == 2
        assert @assignment.submissions.size == 2
      end
    end

    context 'with some assignments submitted multiple times' do
      setup do
        grouping = Grouping.make(:assignment => @assignment)
        2.times do
          grouping = Grouping.make(:assignment => @assignment)
          2.times do
            sub = Submission.make(:grouping => grouping)
          end
        end
      end

      should 'have 2 groups, each submitted 2 times' do
        assert @assignment.groups_submitted.size == 2
        assert @assignment.submissions.size == 4
      end
    end

    context 'with some assignments graded' do
      setup do
        grouping = Grouping.make(:assignment => @assignment)
        sub = Submission.make(:grouping => grouping)

        2.times do
          grouping = Grouping.make(:assignment => @assignment)

          sub = Submission.make(:grouping => grouping)
          result = sub.get_latest_result
          result.marking_state = Result::MARKING_STATES[:complete]
          result.save
        end
      end

      should 'have 5 result completed' do
        assert @assignment.graded_submissions.size == 2
      end
    end

    context 'with all assignments graded' do
      setup do
        2.times do
          grouping = Grouping.make(:assignment => @assignment)
          sub = Submission.make(:grouping => grouping)
          result = sub.get_latest_result
          result.marking_state = Result::MARKING_STATES[:complete]
          result.save
        end
      end

      should 'have 5 result completed' do
        assert @assignment.graded_submissions.size == 2
      end
    end

    context 'as a noteable' do
      should 'display for note without seeing an exception' do
        assignment = Assignment.make
        assert_nothing_raised do
          assignment.display_for_note
        end
      end
    end # end noteable context

    context 'with a student in a group with a marked submission' do
      setup do
        @membership = StudentMembership.make(:grouping => Grouping.make(:assignment => @assignment),:membership_status => StudentMembership::STATUSES[:accepted])
        sub = Submission.make(:grouping => @membership.grouping)
        @result = sub.get_latest_result

        @sum = 0
        [2,2.7,2.2,2].each do |weight|
          Mark.make({:mark => 4, :result => @result, :markable => RubricCriterion.make({:assignment => @assignment,:weight => weight})})
          @sum += weight
        end
        @total = @sum * 4
      end

      should 'return true if a student has submitted' do
        assert @assignment.submission_by(@membership.user)
      end

      should 'return the correct results average mark' do
        @result.marking_state = Result::MARKING_STATES[:complete]
        @result.released_to_students = true
        @result.save
        assert @assignment.set_results_statistics
        assert_equal(100, @assignment.results_average)
      end

      should 'return the correct total mark for rubric criteria' do
        assert_equal(@total, @assignment.total_mark)
      end

      should 'return the correct total criteria weight' do
        assert_equal(@sum, @assignment.total_criteria_weight)
      end

      # Test if assignments can fetch the group for a user
      should 'return the correct group for a given student' do
        assert_equal @membership.grouping.group, @assignment.group_by(@membership.user).group
      end
    end

    should 'know how many ungrouped students are left' do
      assert_equal(0, @assignment.no_grouping_students_list.size)
      (1..2).each do
        Student.make
      end
      assert_equal(2, @assignment.no_grouping_students_list.size)
    end

    should 'know how many grouped students exist' do
      assert_equal(0, @assignment.grouped_students.size)
      (1..2).each do
        Student.make
      end
      assert_equal(0, @assignment.grouped_students.size)
      g = Grouping.make(:assignment => @assignment)
      (1..2).each do
        StudentMembership.make(:grouping => g)
      end
      @assignment.reload
      assert_equal(2, @assignment.grouped_students.size)
    end

    should 'know how many ungrouped students exist' do
      assert_equal(0, @assignment.ungrouped_students.size)
      (1..2).each do
        Student.make
      end
      @assignment.reload
      assert_equal(2, @assignment.ungrouped_students.size)
      g = Grouping.make(:assignment => @assignment)
      (1..2).each do
        StudentMembership.make(:grouping => g)
      end
      @assignment.reload
      assert_equal(2, @assignment.ungrouped_students.size)
    end

    should 'know how many valid and invalid groupings exist' do
      assert_equal(0, @assignment.valid_groupings.size)
      assert_equal(0, @assignment.invalid_groupings.size)
      groupings = []
      (1..3).each do
        groupings.push Grouping.make(:assignment => @assignment)
      end
      @assignment.reload
      assert_equal(0, @assignment.valid_groupings.size)
      assert_equal(3, @assignment.invalid_groupings.size)
      (0..2).each do |index|
        StudentMembership.make(:grouping => groupings[index])
      end
      @assignment.reload
      assert_equal(0, @assignment.valid_groupings.size) # invalid since group_min = 2
      assert_equal(3, @assignment.invalid_groupings.size)
      groupings[0].admin_approved = true
      groupings[0].save
      assert_equal(1, @assignment.valid_groupings.size)
      assert_equal(2, @assignment.invalid_groupings.size)
      (1..2).each do |index|
        StudentMembership.make(:grouping => groupings[index])
      end
      @assignment.reload
      assert_equal(3, @assignment.valid_groupings.size)
      assert_equal(0, @assignment.invalid_groupings.size)
    end

    should 'know how many groupings have TAs assigned' do
      assert_equal(0, @assignment.assigned_groupings.size)
      assert_equal(0, @assignment.unassigned_groupings.size)
      groupings = []
      (1..3).each do
        groupings.push Grouping.make(:assignment => @assignment)
      end
      @assignment.reload
      (0..2).each do |index|
        assert_equal(index, @assignment.assigned_groupings.size)
        assert_equal(3 - index, @assignment.unassigned_groupings.size)
        TaMembership.make(:grouping => groupings[index])
      end
      assert_equal(3, @assignment.assigned_groupings.size)
      assert_equal(0, @assignment.unassigned_groupings.size)
    end

    should 'be able to add a new group when there are none already' do
      @assignment.add_group('new_group_name')
      assert_equal 1, @assignment.groupings.count
    end

    should 'be able to add a group with already existing name in another assignment' do
      a = Assignment.make
      old_grouping = Grouping.make(:assignment => a)
      old_group_count = Group.all.size

      @assignment.add_group(old_grouping.group.group_name)

      assert_equal 1,
                   @assignment.groupings.count,
                   'should have added one more grouping'

      assert_equal old_group_count,
                   Group.all.size,
                   'should NOT have added a new group'
    end

    should 'raise when adding a group with an existing name in this assignment' do
      @assignment.add_group('Titanic')
      assert_raise RuntimeError do
        @assignment.add_group('Titanic')
      end
    end

    should 'be able to create groupings when students work alone' do
      (1..5).each do
        Student.make
      end

      assert_equal(0, @assignment.groupings.count)
      assert @assignment.create_groupings_when_students_work_alone
      assert_equal(5, @assignment.groupings.count)
    end

    context "with some groupings with students and ta's assigned " do
      setup do
        (1..5).each do
          grouping = Grouping.make(:assignment => @assignment)
          (1..3).each do
            StudentMembership.make({:grouping => grouping, :membership_status => StudentMembership::STATUSES[:accepted]})
          end
          TaMembership.make({:grouping => grouping, :membership_status => StudentMembership::STATUSES[:accepted]})
        end
      end

      should 'be able to add a new group when there are some already' do
        @assignment.add_group('new_group_name')
        assert_equal(6, @assignment.groupings.count)
      end

      should "be able to have it's groupings cloned correctly" do
        clone = Assignment.make({:group_min => 1, :group_max => 1})
        number = StudentMembership.all.size + TaMembership.all.size
        clone.clone_groupings_from(@assignment.id)
        assert_equal(@assignment.group_min, clone.group_min)
        assert_equal(@assignment.group_max, clone.group_max)
        assert_equal(@assignment.groupings.size, clone.groupings.size)
        # Since we clear between each test, there should be twice as much as previously
        assert_equal(2 * number, StudentMembership.all.size + TaMembership.all.size)
      end
    end

    # One student in a grouping is hidden, so that membership should
    # not be cloned
    context 'with a group with 3 accepted students' do
      setup do
        @grouping = Grouping.make(:assignment => @assignment)
        @members = []
        (1..3).each do
          @members.push StudentMembership.make({:membership_status => StudentMembership::STATUSES[:accepted],:grouping => @grouping})
        end
        @source = @assignment
        @group =  @grouping.group
      end

      context 'with another fresh assignment' do
        setup do
          @target = Assignment.make({:group_min => 1, :group_max => 1})
        end

        should 'clone all three members if none are hidden' do
          # clone the groupings
          @target.clone_groupings_from(@source.id)
          # and let's make sure that the memberships were cloned
          (0..2).each do |index|
            assert @members[index].user.has_accepted_grouping_for?(@target.id)
          end
          @group.reload
          assert !@group.groupings.find_by_assignment_id(@target.id).nil?
        end

        should 'ignore a blocked student during cloning' do
          student = @members[0].user
          # hide the student
          student.hidden = true
          student.save
          # clone the groupings
          @target.clone_groupings_from(@source.id)
          # make sure the membership wasn't created for the hidden
          # student
          assert !student.has_accepted_grouping_for?(@target.id)
          # and let's make sure that the other memberships were cloned
          assert @members[1].user.has_accepted_grouping_for?(@target.id)
          assert @members[2].user.has_accepted_grouping_for?(@target.id)
          @group.reload
          assert !@group.groupings.find_by_assignment_id(@target.id).nil?
        end

        should 'ignore two blocked students during cloning' do
          # hide the students
          @members[0].user.hidden = true
          @members[0].user.save
          @members[1].user.hidden = true
          @members[1].user.save
          # clone the groupings
          @target.clone_groupings_from(@source.id)
          # make sure the membership wasn't created for the hidden
          # student
          assert !@members[0].user.has_accepted_grouping_for?(@target.id)
          assert !@members[1].user.has_accepted_grouping_for?(@target.id)
          # and let's make sure that the other membership was cloned
          assert @members[2].user.has_accepted_grouping_for?(@target.id)
          # and that the proper grouping was created
          @group.reload
          assert !@group.groupings.find_by_assignment_id(@target.id).nil?
        end

        should 'ignore grouping if all students hidden' do
          # hide the students
          (0..2).each do |index|
            @members[index].user.hidden = true
            @members[index].user.save
          end

          # Get the Group that these students belong to for assignment_1
          assert @members[0].user.has_accepted_grouping_for?(@source.id)
          # clone the groupings
          @target.clone_groupings_from(@source.id)
          # make sure the membership wasn't created for the hidden
          # student
          (0..2).each do |index|
            assert !@members[index].user.has_accepted_grouping_for?(@target.id)
          end
          # and let's make sure that the grouping wasn't cloned
          @group.reload
          assert @group.groupings.find_by_assignment_id(@target.id).nil?
        end
      end

      context 'with an assignment with other groupings' do
        setup do
          @target = Assignment.make({:group_min => 1, :group_max => 1})
          @target.create_groupings_when_students_work_alone
        end
        should 'destroy all previous groupings if cloning was successful' do
          old_groupings = @target.groupings
          @target.clone_groupings_from(@source.id)
          @target.reload
          old_groupings.each do |old_grouping|
            assert !@target.groupings.include?(old_grouping)
          end
        end
      end

      context 'an assignment with external commits only and previous groups' do
        setup do
          @assignment.allow_web_submits = false
          @assignment.save
          @target = Assignment.make({:allow_web_submits => false, :group_min => 1, :group_max => 1})
          @target.create_groupings_when_students_work_alone
          # And for this test, let's make sure all groupings cloned have admin approval
          @assignment.groupings.each do |grouping|
            grouping.admin_approved = true
            grouping.save
          end
          assert @assignment.groupings.size > 0
        end

        should 'ensure that all students have appropriate permissions on the cloned groupings' do
          @target.clone_groupings_from(@assignment.id)
          @target.reload
          @target.groupings.each do |grouping|
            grouping.accepted_students.each do |student|
              grouping.group.access_repo do |repo|
                assert_equal repo.get_permissions(student.user_name), Repository::Permission::READ_WRITE, "student should have read-write permissions on their group's repository"
              end
            end
          end
        end
      end
    end

    should 'not add csv group with empty row' do
      assert !@assignment.add_csv_group([])
    end

    context 'with existing students' do
      setup do
        @student1 = Student.make
        @student2 = Student.make
      end

      should 'be able to add a group by CSV row' do
        group = ['groupname', 'CaptainSparrow' ,@student1.user_name, @student2.user_name]
        old_groupings_count = @assignment.groupings.length
        assert_nil @assignment.add_csv_group(group)
        @assignment.reload
        assert_equal old_groupings_count + 1, @assignment.groupings.length
      end

      should 'be able to add a group by CSV row with existing group name' do
        Group.make(:group_name => 'groupname')
        group = ['groupname', 'CaptainSparrow' , @student1.user_name, @student2.user_name]
        old_group_count = Group.all.length
        assert_nil @assignment.add_csv_group(group)
        assert_equal old_group_count, Group.all.length
      end

    end

    context 'with a students in groupings setup with marking complete (rubric marking)' do
      setup do
        # create the required files for the assignment
        AssignmentFile.make(:assignment => @assignment)
        AssignmentFile.make(:assignment => @assignment)

        # create the marking criteria
        criteria = []
        (1..4).each do |index|
          criteria.push RubricCriterion.make({:assignment => @assignment, :position => index})
        end

        # create the groupings and associated marks
        (1..4).each do
          g = Grouping.make(:assignment => @assignment)
          (1..3).each do
            StudentMembership.make({:grouping => g, :membership_status => StudentMembership::STATUSES[:accepted]})
          end
          s = Submission.make(:grouping => g)
          r = s.get_latest_result
          (0..3).each do |index|
            Mark.make({:result => r, :markable => criteria[index] })
          end
          r.reload
          r.marking_state = Result::MARKING_STATES[:complete]
          r.save
        end
      end

      should 'be able to generate a detailed CSV report of rubrics based marks (including criteria)' do
        a = @assignment
        out_of = a.total_mark
        rubric_criteria = a.rubric_criteria
        expected_string = ''
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
            submission = grouping.current_submission_used
            fields.push(submission.get_latest_result.total_mark / out_of * 100)
            rubric_criteria.each do |rubric_criterion|
              mark = submission.get_latest_result.marks.find_by_markable_id_and_markable_type(rubric_criterion.id, 'RubricCriterion')
              if mark.nil?
                fields.push('')
              else
                fields.push(mark.mark || '')
              end
              fields.push(rubric_criterion.weight)
            end
            fields.push(submission.get_latest_result.get_total_extra_points)
            fields.push(submission.get_latest_result.get_total_extra_percentage)
          end
          # push grace credits info
          grace_credits_data = student.remaining_grace_credits.to_s + '/' + student.grace_credits.to_s
          fields.push(grace_credits_data)

          expected_string += fields.to_csv
        end
        assert_equal expected_string, a.get_detailed_csv_report, 'Detailed CSV report is wrong!'
      end
    end

    context 'with a students in groupings setup with marking complete (flexible marking)' do
      setup do
        # Want an assignment with flexible criteria as marking scheme.
        @flexible_assignment = Assignment.make(:marking_scheme_type =>
                                               Assignment::MARKING_SCHEME_TYPE[:flexible])
        # create the required files for the assignment
        AssignmentFile.make(:assignment => @flexible_assignment)
        AssignmentFile.make(:assignment => @flexible_assignment)

        # create 4 flexible marking criteria
        criteria = []
        (1..4).each do |index|
          criteria.push FlexibleCriterion.make({:assignment => @flexible_assignment, :position => index})
        end

        # create the groupings and associated marks
        (1..4).each do
          g = Grouping.make(:assignment => @flexible_assignment)
          (1..3).each do
            StudentMembership.make({:grouping => g, :membership_status => StudentMembership::STATUSES[:accepted]})
          end
          s = Submission.make(:grouping => g)
          r = s.get_latest_result
          (0..3).each do |index|
            Mark.make({:result => r, :markable => criteria[index] })
          end
          r.reload
          r.marking_state = Result::MARKING_STATES[:complete]
          r.save
        end
      end

      should 'be able to generate a detailed CSV report of flexible based marks (including criteria)' do
        a = @flexible_assignment
        out_of = a.total_mark
        flexible_criteria = a.flexible_criteria
        expected_string = ''
        Student.all.each do |student|
          fields = []
          fields.push(student.user_name)
          grouping = student.accepted_grouping_for(a.id)
          if grouping.nil? || !grouping.has_submission?
            fields.push('')
            flexible_criteria.each do |criterion|
              fields.push('')
              fields.push(criterion.max)
            end
            fields.push('')
            fields.push('')
          else
            submission = grouping.current_submission_used
            fields.push(submission.get_latest_result.total_mark / out_of * 100)
            flexible_criteria.each do |criterion|
              mark = submission.get_latest_result.marks.find_by_markable_id_and_markable_type(criterion.id, 'FlexibleCriterion')
              if mark.nil?
                fields.push('')
              else
                fields.push(mark.mark || '')
              end
              fields.push(criterion.max)
            end
            fields.push(submission.get_latest_result.get_total_extra_points)
            fields.push(submission.get_latest_result.get_total_extra_percentage)
          end
          # push grace credits info
          grace_credits_data = student.remaining_grace_credits.to_s + '/' + student.grace_credits.to_s
          fields.push(grace_credits_data)

          expected_string += fields.to_csv
        end
        assert_equal expected_string, a.get_detailed_csv_report, 'Detailed CSV report is wrong!'
      end
    end

    context 'which is graded, with all grades under 100%' do
      setup do
        totals = [16.5, 10, 19.5, 27.0, 0]

        # create rubric creteria
        rubric_criteria = [{:rubric_criterion_name => 'Uses Conditionals', :weight => 1},
          {:rubric_criterion_name => 'Code Clarity', :weight => 2},
          {:rubric_criterion_name => 'Code Is Documented', :weight => 3},
          {:rubric_criterion_name => 'Uses For Loop', :weight => 1}]
        default_levels = {:level_0_name => 'Quite Poor',
          :level_0_description => 'This criterion was not satisifed whatsoever',
          :level_1_name => 'Satisfactory',
          :level_1_description => 'This criterion was satisfied',
          :level_2_name => 'Good',
          :level_2_description => 'This criterion was satisfied well',
          :level_3_name => 'Great',
          :level_3_description => 'This criterion was satisfied really well!',
          :level_4_name => 'Excellent',
          :level_4_description => 'This criterion was satisfied excellently'}

        rubric_criteria.each do |rubric_criteria|
          rc = RubricCriterion.new
          rc.update_attributes(rubric_criteria)
          rc.update_attributes(default_levels)
          rc.assignment = @assignment
          rc.save
        end

        # create the groupings for each student in the assignment
        (1..5).each do |index|
          g = Grouping.make(:assignment => @assignment)
          s = Submission.make(:grouping => g)
          r = s.get_latest_result
          r.total_mark = totals[index - 1]
          r.marking_state = Result::MARKING_STATES[:complete]
          r.save
        end
      end

      should 'generate a correct grade distribution as percentage' do
        a = @assignment
        expected_distribution = [1,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,0,0,1]
        expected_distribution_ten_intervals = [1, 0, 0, 1, 0, 1, 1, 0, 0, 1]
        assert_equal expected_distribution,
                     a.grade_distribution_as_percentage,
                     'Default grade distribution is wrong!'
        assert_equal expected_distribution_ten_intervals,
                     a.grade_distribution_as_percentage(10),
                     'Grade distribution for ten intervals is wrong!'
      end
    end

    context 'which is graded, with some grades over 100%' do
      setup do
        totals = [16.1, 15.5, 5.0, 37.0, 0]

        # create rubric criteria
        rubric_criteria = [{:rubric_criterion_name => 'Uses Conditionals', :weight => 1},
          {:rubric_criterion_name => 'Code Clarity', :weight => 2},
          {:rubric_criterion_name => 'Code Is Documented', :weight => 3},
          {:rubric_criterion_name => 'Uses For Loop', :weight => 1}]
        default_levels = {:level_0_name => 'Quite Poor',
          :level_0_description => 'This criterion was not satisifed whatsoever',
          :level_1_name => 'Satisfactory',
          :level_1_description => 'This criterion was satisfied',
          :level_2_name => 'Good',
          :level_2_description => 'This criterion was satisfied well',
          :level_3_name => 'Great',
          :level_3_description => 'This criterion was satisfied really well!',
          :level_4_name => 'Excellent',
          :level_4_description => 'This criterion was satisfied excellently'}

        rubric_criteria.each do |rubric_criteria|
          rc = RubricCriterion.new
          rc.update_attributes(rubric_criteria)
          rc.update_attributes(default_levels)
          rc.assignment = @assignment
          rc.save
        end

        # create the groupings for each student in the assignment
        (1..5).each do |index|
          g = Grouping.make(:assignment => @assignment)
          s = Submission.make(:grouping => g)
          r = s.get_latest_result
          r.total_mark = totals[index - 1]
          r.marking_state = Result::MARKING_STATES[:complete]
          r.save
        end
      end

      should 'generate a correct grade distribution as percentage' do
        a = @assignment
        expected_distribution = [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0,
                                 0, 0, 0, 0, 0, 1]
        expected_distribution_ten_intervals = [1, 1, 0, 0, 0, 2, 0, 0, 0, 1]
        assert_equal expected_distribution, a.grade_distribution_as_percentage, 'Default grade distribution is wrong!'
        assert_equal expected_distribution_ten_intervals, a.grade_distribution_as_percentage(10), 'Grade distribution for ten intervals is wrong!'
      end
    end
  end

  context 'An assignment instance' do
    setup do
      @assignment = Assignment.make({:group_min => 1,
                                     :group_max => 1,
                                     :student_form_groups => false,
                                     :invalid_override => true,
                                     :due_date => 2.days.ago,
                                     :created_at => 42.days.ago })
    end

    context 'with a grouping that has a submission and a TA assigned ' do
      setup do
        @grouping = Grouping.make(:assignment => @assignment)
        @tamembership = TaMembership.make(:grouping => @grouping)
        @studentmembership = StudentMembership.make(:grouping => @grouping, :membership_status => StudentMembership::STATUSES[:inviter])
        @submission = Submission.make(:grouping => @grouping)
      end

      should 'be in the past' do
        assert @assignment.section_past_due_date?(@grouping)
      end

      should 'be able to generate a simple CSV report of marks' do
        expected_string = ''
        Student.all.each do |student|
          fields = []
          fields.push(student.user_name)
          grouping = student.accepted_grouping_for(@assignment.id)
          if grouping.nil? || !grouping.has_submission?
            fields.push('')
          else
            submission = grouping.current_submission_used
            fields.push(submission.get_latest_result.total_mark / @assignment.total_mark * 100)
          end
          expected_string += fields.to_csv
        end
        assert_equal expected_string, @assignment.get_simple_csv_report, 'Simple CSV report is wrong!'
      end

      should 'be able to get a list of repository access URLs for each group' do
        expected_string = ''
        @assignment.groupings.each do |grouping|
          group = grouping.group
          expected_string += [group.group_name,group.repository_external_access_url].to_csv
        end
        assert_equal expected_string, @assignment.get_svn_repo_list, 'Repo access url list string is wrong!'
      end

      context 'with two groups of a single student each' do
        setup do
          (1..2).each do
            g = Grouping.make(:assignment => @assignment)
            # StudentMembership.make({:grouping => g,:membership_status => StudentMembership::STATUSES[:inviter] } )
            s = Submission.make(:grouping => g)
            r = s.get_latest_result
            (1..2).each do
              Mark.make(:result => r)
            end
            r.reload
            r.marking_state = Result::MARKING_STATES[:complete]
            r.save
          end
        end

        should 'be able to get_svn_export_commands' do
          expected_array = []

          @assignment.groupings.each do |grouping|
            submission = grouping.current_submission_used
            if submission
              group = grouping.group
              expected_array.push("svn export -r #{submission.revision_number} #{REPOSITORY_EXTERNAL_BASE_URL}/#{group.repository_name}/#{@assignment.repository_folder} \"#{group.group_name}\"")
            end
          end
          assert_equal expected_array, @assignment.get_svn_export_commands
        end

        should 'be able to get_svn_export_commands with spaces in group name ' do
          Group.all.each do |group|
            group.group_name = group.group_name + ' Test'
            group.save
          end
          expected_array = []

          @assignment.groupings.each do |grouping|
            submission = grouping.current_submission_used
            if submission
              group = grouping.group
              expected_array.push("svn export -r #{submission.revision_number} #{REPOSITORY_EXTERNAL_BASE_URL}/#{group.repository_name}/#{@assignment.repository_folder} \"#{group.group_name}\"")
            end
          end
          assert_equal expected_array, @assignment.get_svn_export_commands
        end
      end
        
      context 'with two groups of a single student each with multiple submission' do
        setup do
          (1..2).each do
            g = Grouping.make(:assignment => @assignment)
            # create 2 submission for each group
            (1..2).each do
              s = Submission.make(:grouping => g)
              r = s.get_latest_result
              (1..2).each do
                Mark.make(:result => r)
              end
              r.reload
              r.marking_state = Result::MARKING_STATES[:complete]
              r.save
            end
            g.save
          end
        end

        should 'be able to get_svn_export_commands' do
          expected_array = []

          @assignment.groupings.each do |grouping|
            submission = grouping.current_submission_used
            if submission
              group = grouping.group
              expected_array.push("svn export -r #{submission.revision_number} #{REPOSITORY_EXTERNAL_BASE_URL}/#{group.repository_name}/#{@assignment.repository_folder} \"#{group.group_name}\"")
            end
          end
          assert_equal expected_array, @assignment.get_svn_export_commands
        end
      end
    end
  end # end assignment instance context

  context 'An assignment' do
    setup do
      @assignment = Assignment.make(:section_due_dates_type => true,
                                    :section_groups_only => true,
                                    :due_date => 3.days.ago)
      @section_01 = Section.make
      @section_02 = Section.make
      @section_due_date = SectionDueDate.make(:section => @section_01,
                                                :assignment => @assignment,
                                                :due_date => 3.days.from_now)


    end


    should 'return the section due date for a specific section that has not section due date' do
      assert_equal (3.days.ago).day(),
                   @assignment.section_due_date(@section_02).day()
    end

    context 'with section due dates' do
      setup do
        student_01 = Student.make(:section => @section_01)
        student_02 = Student.make(:section => @section_02)

        @grouping_1 = Grouping.make(:assignment => @assignment)
        @grouping_2 = Grouping.make(:assignment => @assignment)
        StudentMembership.make(:grouping => @grouping_1,
                    :user => student_01,
                    :membership_status => StudentMembership::STATUSES[:inviter])
        StudentMembership.make(:grouping => @grouping_2,
                    :user => student_02,
                    :membership_status => StudentMembership::STATUSES[:inviter])


      end

      should 'return the section due date for a specific section' do
        assert_equal (3.days.from_now).day(),
                    @assignment.section_due_date(@section_01).day()
      end

      should 'differentiate section due dates to normal due date' do
        assert !@assignment.section_past_due_date?(@grouping_1)
        assert @assignment.section_past_due_date?(@grouping_2)
      end

    end

    should 'not be past due date as there is one section not past due date' do
      assert !@assignment.past_due_date?
    end

    should 'return latest due date' do
      assert_equal 3.days.from_now.day(), @assignment.latest_due_date.day()
    end

    context 'With all section due dates past now' do
      setup do
        @section_due_date.due_date = 2.days.ago
        @section_due_date.save
      end

      should 'be past due date as all the sections are past due date' do
        assert @assignment.past_due_date?
      end
    end
  end
end
