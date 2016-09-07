require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class AssignmentTest < ActiveSupport::TestCase

  should have_many :rubric_criteria
  should have_many :flexible_criteria
  should have_many :assignment_files
  should have_many :test_scripts
  should have_many :test_support_files
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

  should validate_presence_of :submission_rule

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
    a = Assignment.new(group_min: 3,group_max: 2)
    assert !a.valid?
  end

  should 'catch an invalid date' do
    a = Assignment.new(due_date: '2020/02/31')  #31st day of february
    assert !a.valid?
  end

  should 'catch a zero group_min' do
    a = Assignment.new(group_min: 0)
    assert !a.valid?
  end

  should 'catch a negative group_min' do
    a = Assignment.new(group_min: -5)
    assert !a.valid?
  end

  should 'catch a nil group_min' do
    a = Assignment.new(group_min: nil)
    assert !a.valid?
  end

  should 'catch a negative tokens_per_period value' do
    a = Assignment.new(enable_test: true, enable_student_tests: true, tokens_per_period: '-10', unlimited_tokens: false)
    assert !a.valid?, 'assignment expected to be invalid when student tests are enabled without unlimited tokens and
                       tokens_per_period is < 0'
  end

  context 'A past due assignment w/ No Late submission rule' do
    context 'without sections' do
      setup do
        @assignment = Assignment.make(due_date: 2.days.ago)
      end

      should 'return the last due date' do
        assert_equal 2.days.ago.day(), @assignment.latest_due_date.day()
      end

      should 'return true on past_collection_date? call' do
        assert @assignment.past_collection_date?
      end
    end

    context 'with a section' do
      setup do
        @assignment = Assignment.make(due_date: 2.days.ago, section_due_dates_type: true)
        @section = Section.make(name: 'section_name')
        SectionDueDate.make(section: @section, assignment: @assignment,
                            due_date: 1.day.ago)
        student = Student.make(section: @section)
        @grouping = Grouping.make(assignment: @assignment)
        StudentMembership.make(grouping: @grouping,
                  user: student,
                  membership_status: StudentMembership::STATUSES[:inviter])
      end

      should 'return the normal due date for section due date' do
        assert @assignment.section_due_date(@section)
      end

      context 'and another' do
        setup do
          @section = Section.make(name: 'section_name2')
          SectionDueDate.make(section: @section, assignment: @assignment,
                              due_date: 1.day.ago)
          student = Student.make(section: @section)
          @grouping = Grouping.make(assignment: @assignment)
          StudentMembership.make(grouping: @grouping,
                                 user: student,
                                 membership_status: StudentMembership::STATUSES[:inviter])
        end
      end
    end
  end

  context 'A before due assignment w/ No Late submission rule' do
    setup do
      @assignment = Assignment.make({due_date: 2.days.from_now})
    end

    should 'return false on past_collection_date? call' do
      assert !@assignment.past_collection_date?
    end
  end

  context 'after remarks are due assignment' do
    setup do
      @assignment = Assignment.make({remark_due_date: 2.days.ago})
    end

    should 'return true on past_remark_due_date? call' do
      assert @assignment.past_remark_due_date?
    end
  end

  context 'before remarks are due assignment' do
    setup do
      @assignment = Assignment.make({remark_due_date: 2.days.from_now})
    end

    should 'return false on past_remark_due_date? call' do
      assert !@assignment.past_remark_due_date?
    end
  end

  context 'An Assignment' do
    setup do
      @assignment = Assignment.make(group_name_autogenerated: false)
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
        @membership = StudentMembership.make(grouping: Grouping.make(assignment: @assignment),membership_status: StudentMembership::STATUSES[:accepted])
        sub = Submission.make(grouping: @membership.grouping)
        @result = sub.get_latest_result

        @sum = 0
        [2,2.7,2.2,2].each do |weight|
          Mark.make({mark: 4, result: @result, markable: RubricCriterion.make({assignment: @assignment, max_mark: weight * 4})})
          @sum += weight
        end
        @total = @sum * 4
      end

      should 'return the correct maximum mark for rubric criteria' do
        assert_equal(@total, @assignment.max_mark)
      end

      # Test if assignments can fetch the group for a user
      should 'return the correct group for a given student' do
        assert_equal @membership.grouping.group, @assignment.group_by(@membership.user).group
      end
    end

    context "with some groupings with students and ta's assigned " do
      setup do
        (1..5).each do
          grouping = Grouping.make(assignment: @assignment)
          (1..3).each do
            StudentMembership.make({grouping: grouping, membership_status: StudentMembership::STATUSES[:accepted]})
          end
          TaMembership.make({grouping: grouping, membership_status: StudentMembership::STATUSES[:accepted]})
        end
      end

      should "be able to have it's groupings cloned correctly" do
        clone = Assignment.make({group_min: 1, group_max: 1})
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
        @grouping = Grouping.make(assignment: @assignment)
        @members = []
        (1..3).each do
          @members.push StudentMembership.make({membership_status: StudentMembership::STATUSES[:accepted],grouping: @grouping})
        end
        @source = @assignment
        @group =  @grouping.group
      end

      context 'with another fresh assignment' do
        setup do
          @target = Assignment.make({group_min: 1, group_max: 1})
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
          @target = Assignment.make({group_min: 1, group_max: 1})
          3.times do
            target_grouping = Grouping.make(assignment: @target)
            StudentMembership.make(
              membership_status: StudentMembership::STATUSES[:accepted],
              grouping: target_grouping)
          end
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
          @target = Assignment.make({allow_web_submits: false, group_min: 1, group_max: 1})
          # And for this test, let's make sure all groupings cloned have admin approval
          3.times do
            target_grouping = Grouping.make(
              assignment: @target,
              admin_approved: true)
            StudentMembership.make(
              membership_status: StudentMembership::STATUSES[:accepted],
              grouping: target_grouping)
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
    end

    context 'with a students in groupings setup with marking complete (rubric marking)' do
      setup do
        # create the required files for the assignment
        AssignmentFile.make(assignment: @assignment)
        AssignmentFile.make(assignment: @assignment)

        # create the marking criteria
        criteria = []
        (1..4).each do |index|
          criteria.push RubricCriterion.make({assignment: @assignment, position: index})
        end

        # create the groupings and associated marks
        (1..4).each do
          g = Grouping.make(assignment: @assignment)
          (1..3).each do
            StudentMembership.make({grouping: g, membership_status: StudentMembership::STATUSES[:accepted]})
          end
          s = Submission.make(grouping: g)
          r = s.get_latest_result
          r.marks.each do |mark|
            mark.mark = 0
          end
          r.reload
          r.marking_state = Result::MARKING_STATES[:complete]
          r.save
        end
      end

      should 'be able to generate a detailed CSV report of rubric_criteria based marks (including criteria)' do
        a = @assignment
        out_of = a.max_mark
        rubric_criteria = a.get_criteria(:all, :rubric)
        expected_string = ''
        Student.all.each do |student|
          fields = []
          fields.push(student.user_name)
          grouping = student.accepted_grouping_for(a.id)
          if grouping.nil? || !grouping.has_submission?
            fields.push('')
            rubric_criteria.each do |rubric_criterion|
              fields.push('')
              fields.push(rubric_criterion.max_mark)
            end
            fields.push('')
            fields.push('')
          else
            submission = grouping.current_submission_used
            fields.push(submission.get_latest_result.total_mark / out_of * 100)
            fields.push(submission.get_latest_result.total_mark)
            rubric_criteria.each do |rubric_criterion|
              mark = submission.get_latest_result.marks.find_by_markable_id_and_markable_type(rubric_criterion.id, 'RubricCriterion')
              if mark.nil?
                fields.push('')
              else
                fields.push(mark.mark || '')
              end
              fields.push(rubric_criterion.max_mark)
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
        @assignment = Assignment.make
        # create the required files for the assignment
        AssignmentFile.make(assignment: @assignment)
        AssignmentFile.make(assignment: @assignment)

        # create 4 flexible marking criteria
        criteria = []
        (1..4).each do |index|
          criteria.push FlexibleCriterion.make({assignment: @assignment, position: index})
        end

        # create the groupings and associated marks
        (1..4).each do
          g = Grouping.make(assignment: @assignment)
          (1..3).each do
            StudentMembership.make({grouping: g, membership_status: StudentMembership::STATUSES[:accepted]})
          end
          s = Submission.make(grouping: g)
          r = s.get_latest_result
          r.marks.each do |mark|
            mark.mark = 0
          end
          r.reload
          r.marking_state = Result::MARKING_STATES[:complete]
          r.save
        end
      end

      should 'be able to generate a detailed CSV report of flexible based marks (including criteria)' do
        a = @assignment
        out_of = a.max_mark
        flexible_criteria = a.get_criteria(:all, :flexible)
        expected_string = ''
        Student.all.each do |student|
          fields = []
          fields.push(student.user_name)
          grouping = student.accepted_grouping_for(a.id)
          if grouping.nil? || !grouping.has_submission?
            fields.push('')
            flexible_criteria.each do |criterion|
              fields.push('')
              fields.push(criterion.max_mark)
            end
            fields.push('')
            fields.push('')
          else
            submission = grouping.current_submission_used
            fields.push(submission.get_latest_result.total_mark / out_of * 100)
            fields.push(submission.get_latest_result.total_mark)
            flexible_criteria.each do |criterion|
              mark = submission.get_latest_result.marks.find_by_markable_id_and_markable_type(criterion.id, 'FlexibleCriterion')
              if mark.nil?
                fields.push('')
              else
                fields.push(mark.mark || '')
              end
              fields.push(criterion.max_mark)
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
  end

  context 'An assignment instance' do
    setup do
      @assignment = Assignment.make({group_min: 1,
                                     group_max: 1,
                                     student_form_groups: false,
                                     invalid_override: true,
                                     due_date: 2.days.ago,
                                     created_at: 42.days.ago })
    end

    context 'with a grouping that has a submission and a TA assigned ' do
      setup do
        @grouping = Grouping.make(assignment: @assignment)
        @tamembership = TaMembership.make(grouping: @grouping)
        @studentmembership = StudentMembership.make(grouping: @grouping, membership_status: StudentMembership::STATUSES[:inviter])
        @submission = Submission.make(grouping: @grouping)
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
            g = Grouping.make(assignment: @assignment)
            # StudentMembership.make({grouping: g,membership_status: StudentMembership::STATUSES[:inviter] } )
            s = Submission.make(grouping: g)
            r = s.get_latest_result
            (1..2).each do
              Mark.make(result: r)
            end
            r.reload
            r.marking_state = Result::MARKING_STATES[:complete]
            r.save
          end
        end

        should 'be able to get_svn_checkout_commands' do
          expected_array = []

          @assignment.groupings.each do |grouping|
            submission = grouping.current_submission_used
            if submission
              group = grouping.group
              expected_array.push("svn checkout -r #{submission.revision_number} #{REPOSITORY_EXTERNAL_BASE_URL}/#{group.repository_name}/#{@assignment.repository_folder} \"#{group.group_name}\"")
            end
          end
          assert_equal expected_array, @assignment.get_svn_checkout_commands
        end

        should 'be able to get_svn_checkout_commands with spaces in group name ' do
          Group.all.each do |group|
            group.group_name = group.group_name + ' Test'
            group.save
          end
          expected_array = []

          @assignment.groupings.each do |grouping|
            submission = grouping.current_submission_used
            if submission
              group = grouping.group
              expected_array.push("svn checkout -r #{submission.revision_number} #{REPOSITORY_EXTERNAL_BASE_URL}/#{group.repository_name}/#{@assignment.repository_folder} \"#{group.group_name}\"")
            end
          end
          assert_equal expected_array, @assignment.get_svn_checkout_commands
        end
      end

      context 'with two groups of a single student each with multiple submission' do
        setup do
          (1..2).each do
            g = Grouping.make(assignment: @assignment)
            # create 2 submission for each group
            (1..2).each do
              s = Submission.make(grouping: g)
              r = s.get_latest_result
              (1..2).each do
                Mark.make(result: r)
              end
              r.reload
              r.marking_state = Result::MARKING_STATES[:complete]
              r.save
            end
            g.save
          end
        end

        should 'be able to get_svn_checkout_commands' do
          expected_array = []

          @assignment.groupings.each do |grouping|
            submission = grouping.current_submission_used
            if submission
              group = grouping.group
              expected_array.push("svn checkout -r #{submission.revision_number} #{REPOSITORY_EXTERNAL_BASE_URL}/#{group.repository_name}/#{@assignment.repository_folder} \"#{group.group_name}\"")
            end
          end
          assert_equal expected_array, @assignment.get_svn_checkout_commands
        end
      end
    end
  end # end assignment instance context
end
