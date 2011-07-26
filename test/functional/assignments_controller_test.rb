require File.join(File.dirname(__FILE__), 'authenticated_controller_test')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')

require 'fastercsv'
require 'shoulda'
require 'machinist'
require 'mocha'
require 'time-warp'

class AssignmentsControllerTest < AuthenticatedControllerTest

  fixtures  :all
  set_fixture_class :rubric_criteria => RubricCriterion

  def setup
    @controller = AssignmentsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new

    # login before testing
    @admin = users(:olm_admin_1)
    @request.session['uid'] = @admin.id

    # stub assignment
    @new_assignment = {
      'name'          => '',
      'message'       => '',
      'group_min'     => '',
      'group_max'     => '',
      'due_date(1i)'  => '',
      'due_date(2i)'  => ''
    }
    setup_group_fixture_repos

  end

  def teardown
    destroy_repos
  end

  context "An admin" do
    setup do
      @admin = Admin.make
    end

    context "with an assignment" do
      setup do
        @assignment = Assignment.make
      end

      should "get edit form if not post" do
        get_as @admin,
              :edit,
              :id => @assignment.id
        assert_response :success
        assert assigns :assignment
      end

      should "bounced off from student interface" do
        get_as @admin,
               :student_interface,
               :id => @assignment.id
        assert_response :missing
      end

      should "update group properties on persist" do
        get_as  @admin,
                :update_group_properties_on_persist,
                :assignment_id => @assignment.id
        assert assigns(:assignment)
        assert_equal @assignment, assigns(:assignment)
      end

      should "edit basic paramaters" do
        post_as @admin,
                :edit,
                :id => @assignment.id,
                :assignment => {
                  :short_identifier => 'New SI',
                  :description => 'New Description',
                  :message => 'New Message',
                  :due_date => 3.days.from_now,
                  :submission_rule_attributes => {
                    :type => @assignment.submission_rule.type.to_s,
                    :id => @assignment.submission_rule.id
                  }
                }
        @assignment.reload
        assert_equal 'New SI', @assignment.short_identifier
        assert_equal 'New Description', @assignment.description
        assert_equal 'New Message', @assignment.message
        assert ((3.days.from_now - @assignment.due_date).abs < 5)
      end

      should "not be able to edit with invalid assignment" do
        post_as @admin,
                :edit,
                :id => @assignment.id,
                :assignment => {
                  :short_identifier => '',
                  :description => 'New Description',
                  :message => 'New Message',
                  :due_date => 3.days.from_now,
                  :submission_rule_attributes => {
                    :type => @assignment.submission_rule.type.to_s,
                    :id => @assignment.submission_rule.id}}
        a = Assignment.find(@assignment.id)
        assert_equal @assignment.short_identifier, a.short_identifier
        assert_equal @assignment.description, a.description
        assert_equal @assignment.message, a.message
        assert_equal @assignment.due_date, a.due_date
        assert_not_nil assigns(:assignment)
        assert !assigns(:assignment).errors.empty?
      end

      should "not be able to edit with invalid submission rules" do
        post_as @admin,
                :edit,
                :id => @assignment.id,
                :assignment => {
                  :short_identifier => 'New SI',
                  :description => 'New Description',
                  :message => 'New Message',
                  :due_date => 3.days.from_now,
                  :submission_rule_attributes => {
                    :type => 'UnknownClass',
                    :id => @assignment.submission_rule.id}}
        a = Assignment.find(@assignment.id)
        assert_equal @assignment.short_identifier, a.short_identifier
        assert_equal @assignment.description, a.description
        assert_equal @assignment.message, a.message
        assert_equal @assignment.due_date, a.due_date
        assert_equal @assignment.submission_rule.type.to_s,
                     a.submission_rule.type.to_s
        assert_not_nil assigns(:assignment)
        assert !assigns(:assignment).errors.empty?
      end

      should "be able to add periods to submission rule class" do
        post_as @admin,
                :edit,
                {:id => @assignment.id,
                 :assignment => {
                   :short_identifier => 'New SI',
                   :description => 'New Description',
                   :message => 'New Message',
                   :due_date => 3.days.from_now,
                   :submission_rule_attributes => {
                     :type => 'PenaltyPeriodSubmissionRule',
                     :id => @assignment.submission_rule.id,
                     :periods_attributes => [
                       {:deduction => '10', :hours => '24'},
                       {:deduction => '20', :hours => '24'}
                     ]}}}
        @assignment.reload
        assert_equal 'New SI', @assignment.short_identifier
        assert_equal 'New Description', @assignment.description
        assert_equal 'New Message', @assignment.message
        assert_equal "PenaltyPeriodSubmissionRule",
                     @assignment.submission_rule.type.to_s
        assert_equal 2, @assignment.submission_rule.periods.length
        first_period = @assignment.submission_rule.periods.first
        last_period = @assignment.submission_rule.periods.last
        assert_equal 10, first_period.deduction
        assert_equal 24, first_period.hours
        assert_equal 20, last_period.deduction
        assert_equal 24, last_period.hours

        assert_not_nil assigns(:assignment)
        assert assigns(:assignment).errors.empty?
      end

      should "be able to set instructor forms groups" do
        post_as @admin,
                :edit,
                {:id => @assignment.id,
                 :assignment => {
                   :description => 'New Description',
                   :message => 'New Message',
                   :due_date => 3.days.from_now,
                   :student_form_groups => false,
                   :submission_rule_attributes => {
                     :type => 'NoLateSubmissionRule',
                     :id => @assignment.submission_rule.id}},
                   :is_group_assignment => true}

        a = Assignment.find(@assignment.id)
        assert_equal 'New Description', a.description
        assert_equal 'New Message', a.message
        assert_equal @assignment.submission_rule.type.to_s,
                     a.submission_rule.type.to_s
        assert !a.student_form_groups
        assert_not_nil assigns(:assignment)
        assert assigns(:assignment).errors.empty?
      end

      should "be able to set students to form groups" do
        post_as @admin,
                :edit,
                {:id => @assignment.id,
                 :assignment => {
                   :description => 'New Description',
                   :message => 'New Message',
                   :due_date => 3.days.from_now,
                   :student_form_groups => "true",
                   :submission_rule_attributes => {
                     :type => 'NoLateSubmissionRule',
                     :id => @assignment.submission_rule.id}},
                   :is_group_assignment => "true"}

        @assignment.reload
        assert I18n.t("assignment.update_success"),
               flash[:success]

        assert_not_nil assigns(:assignment)
        assert assigns(:assignment).errors.empty?
        assert @assignment.student_form_groups, true
      end

      should "get assignments list" do
        submission_rule = NoLateSubmissionRule.make
        submission_rule.stubs(:can_collect_now?).returns(false)
        Assignment.any_instance.stubs(
            :submission_rule).returns(submission_rule)
        get_as @admin, :index
        assert assigns(:assignments)
        assert_response :success
      end

      should "be able to get a csv grade report" do
        student = Student.make
        response_csv = get_as(@admin, :download_csv_grades_report).body
        csv_rows = FasterCSV.parse(response_csv)
        assert_equal Student.all.size, csv_rows.size
        assignments = Assignment.all(:order => 'id')
        csv_rows.each do |csv_row|
          student_name = csv_row.shift
          student = Student.find_by_user_name(student_name)
          assert_not_nil student
          assert_equal assignments.size, csv_row.size

          csv_row.each_with_index do |final_mark,index|
            if final_mark.blank?
              if student.has_accepted_grouping_for?(assignments[index])
                grouping = student.accepted_grouping_for(assignments[index])
                assert (!grouping.has_submission? ||
                        assignments[index].total_mark == 0)
              end
            else
              out_of = assignments[index].total_mark
              grouping = student.accepted_grouping_for(assignments[index])
              assert_not_nil grouping
              assert grouping.has_submission?
              submission = grouping.current_submission_used
              assert_not_nil submission.result
              assert_equal final_mark.to_f.round,
                           (submission.result.total_mark / out_of * 100
                           ).to_f.round
            end
          end
        end
        assert_response :success
      end
    end  # -- with an assignment
  end  # -- an Admin

  context "An grader" do
    setup do
      @grader = Ta.make
    end

    should "not be able to CSV graders report" do
      get_as @grader, :download_csv_grades_report
      assert_response :missing
    end

    context "with an assignment" do
      setup do
        @assignment = Assignment.make
      end

      should "not be able to edit" do
          get_as @grader,
                 :edit,
                 :id => @assignment.id
          assert_response :missing
      end

      should "bounced from student interface" do
        get_as @grader,
               :student_interface,
               :id => @assignment.id
        assert_response :missing
      end

      should "not be able to get group properties" do
        get_as @grader,
               :update_group_properties_on_persist,
               :assignment_id => @assignment.id
        assert_response :missing
      end

      should "gets assignment list on the graders" do
        submission_rule = NoLateSubmissionRule.make
        submission_rule.stubs(:can_collect_now?).returns(false)
        Assignment.any_instance.stubs(:submission_rule).returns(
                submission_rule)
        get_as @grader, :index
        assert assigns(:assignments)
        assert_response :success
      end

    end  # -- with an Assignment
  end  # -- with a Grader

  context "A student" do
    setup do
      @student = Student.make
    end

    context "with an assignment" do
      setup do
        @assignment = Assignment.make(:group_min => 2)
      end

      should "get assignment's index" do
        get_as @student, :index
        assert assigns(:a_id_results)
        assert assigns(:assignments)
        assert_response :success
      end

      should "not be able to get group properties" do
        get_as @student,
               :update_group_properties_on_persist,
               :assignment_id => @assignment.id
        assert_response :missing
      end

      should "not be able to access grades report" do
        get_as @student, :download_csv_grades_report
        assert_response :missing
      end

      should "not be able to edit assignment" do
        get_as @student, :edit, :id => @assignment.id
        assert_response :missing
      end

      should "be able to get the student interface" do
        get_as @student,
               :student_interface,
               :id => @assignment.id
        assert assigns(:assignment)
        assert assigns(:pending_grouping).nil?
        assert_response :success
      end

      should "be able to create a group" do
        post_as(@student, :creategroup, {:id => @assignment.id})
        assert_redirected_to :action => "student_interface",
                             :id => @assignment.id
        assert @student.has_accepted_grouping_for?(@assignment.id)
      end

      should "not be able to invite without a group" do
        students = [Student.make, Student.make]
        user_names = students.collect{ 
                          |student| student.user_name
                        }.join(', ')
        assert_raise RuntimeError do
          post_as(@student,
                  :invite_member,
                  {:id => @assignment.id,
                   :invite_member => user_names})  
        end
      end

      should "not be able to work alone" do
        post_as @student,
                :creategroup,
                {:id => @assignment.id, :workalone => 'true'}

        assert_redirected_to :action => "student_interface",
                             :id => @assignment.id
        assert_equal I18n.t("create_group.fail.can_not_work_alone",
                            :group_min => @assignment.group_min),
                     flash[:fail_notice]
        assert !@student.has_accepted_grouping_for?(@assignment.id)
      end

      context "invited in several group" do
        setup do
          @grouping = Grouping.make(:assignment => @assignment)
          StudentMembership.make(
              :grouping => @grouping,
              :user => @student,
              :membership_status => StudentMembership::STATUSES[:pending])
          StudentMembership.make(
              :grouping => @grouping,
              :membership_status => StudentMembership::STATUSES[:inviter])

          g = Grouping.make(:assignment => @assignment)
          StudentMembership.make(
              :grouping => g,
              :user => @student,
              :membership_status => StudentMembership::STATUSES[:pending])
          StudentMembership.make(
              :grouping => g,
              :membership_status => StudentMembership::STATUSES[:inviter])

        end

        should "be able to join a group" do
          post_as @student, :join_group, {:id => @assignment.id,
                                          :grouping_id => @grouping.id}
          assert @student.has_accepted_grouping_for?(@assignment.id),
                "should have accepted grouping for this assignment"
          assert_redirected_to :action => 'student_interface',
                               :id => @assignment.id
        end

        should "see all the pending invitations" do
          get_as @student, :student_interface, :id => @assignment.id
          assert_response :success
          assert assigns(:pending_grouping)
          assert_equal 2, assigns(:pending_grouping).length
        end

        should "be able to decline an invitation" do
          post_as(@student,
                  :decline_invitation,
                  {:id => @assignment.id,
                   :grouping_id => @grouping.id} )
          assert !@student.has_accepted_grouping_for?(@assignment.id),
                 "should not have accepted groupings for this assignment"
        end
      end

      context ", inviter of a group" do
        setup do
          @grouping = Grouping.make(:assignment => @assignment)
          StudentMembership.make(
              :user => @student,
              :grouping => @grouping,
              :membership_status => StudentMembership::STATUSES[:inviter])
        end

        should "be able to invite a student" do
          student = Student.make
          post_as(@student,
                  :invite_member,
                  {:id => @assignment.id,
                   :invite_member => student.user_name})
          assert_equal(I18n.t('invite_student.success'), flash[:success])
          assert_redirected_to :action => "student_interface",
                               :id => @assignment.id
        end

        should "not be able to invite a student that doesn't exist" do
          post_as(@student,
                  :invite_member,
                  {:id => @assignment.id,
                   :invite_member => "zhfbdjhzkyfg"})
          assert_redirected_to :action => "student_interface",
                               :id => @assignment.id
          assert_equal(I18n.t('invite_student.fail.dne',
                              :user_name => 'zhfbdjhzkyfg'),
                       flash[:fail_notice])
        end

        should "not be able to invite a hidden student" do
          student = Student.make(:hidden => true)
          post_as(@student,
                  :invite_member,
                  {:id => @assignment.id,
                   :invite_member => student.user_name})
          assert_redirected_to :action => "student_interface",
                               :id => @assignment.id
          assert_equal(I18n.t('invite_student.fail.hidden',
                              :user_name => student.user_name),
                       flash[:fail_notice])
        end

        should "not be able to invite an already invited student" do
          sm = StudentMembership.make(:grouping => @grouping)
          post_as(@student,
                  :invite_member,
                  {:id => @assignment.id,
                  :invite_member => sm.user.user_name})
          assert_redirected_to :action => "student_interface",
                               :id => @assignment.id
          assert_equal(I18n.t('invite_student.fail.already_pending',
                              :user_name => sm.user.user_name),
                       flash[:fail_notice])
        end

        should "be able to invite multiple students" do
          students = [Student.make, Student.make]
          user_names = students.collect{
                |student| student.user_name
              }.join(',')
          post_as(@student,
                  :invite_member,
                  {:id => @assignment.id, :invite_member => user_names})
          assert_redirected_to :action => "student_interface",
                               :id => @assignment.id
          assert_equal 2, @grouping.pending_students.size
        end

        should "be able to invite multiple students with malformed string" do
          students = [Student.make, Student.make]
          invalid_users = ['%(*&@#$(*#$EJDF',
                           'falsj asdlfkjasdl aslkdjasd,dasflk(*!@*@*@!!!',
                           'lkjsdlkfjsdfsdlkfjsfsdf']
          user_names = ((students.collect{
                          |student| student.user_name
                         }) + invalid_users).join(',')
          post_as(@student,
                  :invite_member,
                  {:id => @assignment.id,
                   :invite_member => user_names})
          assert_redirected_to :action => "student_interface",
                               :id => @assignment.id
          assert_equal 2, @grouping.pending_students.size
        end

        should "be able to invite students with spacing" do
          students = [Student.make, Student.make]
          user_names = students.collect{
                          |student| student.user_name 
                        }.join(' ,  ')
          post_as(@student,
                  :invite_member,
                  {:id => @assignment.id,
                   :invite_member => user_names})  
          assert_redirected_to :action => "student_interface",
                               :id => @assignment.id
          assert_equal 2, @grouping.pending_students.size
        end

        should "not be able to invite self to a group" do
          post_as(@student,
                  :invite_member,
                  {:id => @assignment.id,
                   :invite_member => @student.user_name})
          assert_equal(I18n.t('invite_student.fail.inviting_self'),
                       flash[:fail_notice].first)
        end

        should "not be able to invite admins" do
          admin = Admin.make
          post_as(@student,
                  :invite_member,
                  {:id => @assignment.id,
                   :invite_member => admin.user_name})
          assert_redirected_to :action => "student_interface",
                               :id => @assignment.id
          assert_equal 0, @grouping.pending_students.size
          assert_equal(I18n.t('invite_student.fail.dne',
                              :user_name => admin.user_name),
                      flash[:fail_notice])
        end

        should "not be able to invite graders" do
          grader = Ta.make
          post_as(@student,
                  :invite_member,
                  {:id => @assignment.id,
                   :invite_member => grader.user_name})
          assert_redirected_to :action => "student_interface",
                               :id => @assignment.id
          assert_equal 0, @grouping.pending_students.size
          assert_equal(I18n.t('invite_student.fail.dne',
                              :user_name => grader.user_name),
                       flash[:fail_notice])
        end

        should "not be able to create another group" do
          post_as(@student,
                  :creategroup,
                  {:id => @assignment.id})
          assert_redirected_to :action => "student_interface",
                               :id => @assignment.id
          assert_equal I18n.t("create_group.fail.already_have_a_group"),
                       flash[:fail_notice]
          assert @student.has_accepted_grouping_for?(@assignment.id)
          assert_equal @grouping,
                       @student.accepted_grouping_for(@assignment.id)
        end

        should "be able to delete rejected membership" do
          sm = StudentMembership.make(
                  :grouping => @grouping,
                  :membership_status => StudentMembership::STATUSES[:pending])

          assert_nothing_raised do
            post_as(@student,
                    :delete_rejected,
                    {:id => @assignment.id,
                     :membership => sm.id})
          end

          assert_raise ActiveRecord::RecordNotFound do
            StudentMembership.find(sm.id)
          end
          assert_redirected_to :controller => 'assignments',
                               :action => 'student_interface',
                               :id => @assignment.id
          assert_response :redirect
        end

        should "be able to disinvite someone" do
          sm = StudentMembership.make(
                  :grouping => @grouping,
                  :membership_status => StudentMembership::STATUSES[:rejected])
          post_as @student,
                  :disinvite_member,
                  {:id => @assignment.id,
                   :membership => sm.id}

          assert_response :success
          assert_equal I18n.t("student.member_disinvited"),
                       flash[:edit_notice]
          assert_equal 1,
                       @grouping.memberships.length
        end

        should "be able to delete an not valid group " do
          assert !@grouping.is_valid?
          post_as @student,
                  :deletegroup,
                  {:id => @assignment.id, :grouping_id => @grouping.id}

          assert_redirected_to :action => "student_interface",
                               :id => @assignment.id

          assert_equal(I18n.t("assignment.group.deleted"), flash[:edit_notice])
          assert !@student.has_accepted_grouping_for?(@assignment.id)
        end

        context "with pending invitations" do
          setup do
            @invited = Student.make
            sm = StudentMembership.make(
                  :grouping => @grouping,
                  :membership_status => StudentMembership::STATUSES[:pending],
                  :user => @invited)

          end

          should "not be able to invite someone already invited" do
            post_as @student,
                    :invite_member,
                    {:id => @assignment.id,
                     :invite_member => @invited.user_name}
            assert_redirected_to :action => 'student_interface',
                                 :id => @assignment.id
            assert flash[:fail_notice].include?(
                      I18n.t('invite_student.fail.already_pending',
                             :user_name => @invited.user_name))
          end
        end  # -- with pending invitations

        context "with a submission" do
          setup do
            submission = Submission.make(:grouping => @grouping)
          end

          should "not be able to delete a group" do
            post_as @student,
                    :deletegroup,
                    {:id => @assignment.id}
            assert_equal I18n.t('groups.cant_delete_already_submitted'),
                        flash[:fail_notice]
            assert @student.has_accepted_grouping_for?(@assignment.id)
          end
        end  # -- with pending invitations
      end  # -- Inviter of a group

      context "in a group" do
        setup do
          @grouping = Grouping.make(:assignment => @assignment)
          @sm = StudentMembership.make(
                 :grouping => @grouping,
                 :membership_status => StudentMembership::STATUSES[:accepted],
                 :user => @student)
        end

        should "not be able to delete rejected membership" do
          assert_raise RuntimeError do
            post_as @student,
                    :delete_rejected,
                    {:id => @assignment.id, :membership => @sm.id}
          end
          assert_nothing_raised do
            membership = StudentMembership.find(@sm.id)
          end
          assert !@sm.nil?
          assert_response :success
        end

        should "not be able to delete group" do
          post_as @student,
                  :deletegroup, {:id => @assignment.id}
          assert_equal I18n.t('groups.cant_delete'), flash[:fail_notice]
          assert @student.has_accepted_grouping_for?(@assignment.id)
        end
      end  # -- in a group
    end  # -- with an assignment

    context "with an assignment with group = 1" do
      setup do
        @assignment = Assignment.make(:group_min => 1)
      end

      should "be able to work alone" do
        post_as @student,
                :creategroup,
                {:id => @assignment.id,
                 :workalone => 'true'}
        assert_redirected_to :action => "student_interface",
                             :id => @assignment.id
        assert @student.has_accepted_grouping_for?(@assignment.id)
        grouping = @student.accepted_grouping_for(@assignment.id)
        assert grouping.is_valid?
      end
    end  # -- with an assignment with group_min = 1

    context "with an assignment where instructors creates groups" do
      setup do
        @assignment = Assignment.make(:student_form_groups => false)
      end

      should "not be able to allow to form groups" do
        post_as @student,
                :creategroup,
                {:id => @assignment.id}

        assert_equal I18n.t("create_group.fail.not_allow_to_form_groups"),
                    flash[:fail_notice]
      end
    end  # -- with an assignment where instructors creates groups

    context "with an assignment where students have to work alone" do
      setup do
        @assignment = Assignment.make(:group_min => 1,
                                      :group_max => 1)
      end

      should "create group automatically" do
        get_as @student, :student_interface, :id => @assignment.id
        assert @student.has_accepted_grouping_for?(@assignment.id)
        assert_not_nil @student.accepted_grouping_for(@assignment.id)
        assert_equal @student,
                     @student.accepted_grouping_for(@assignment.id).inviter
        assert_redirected_to :action => 'student_interface',
                             :id => @assignment.id
      end
    end  # -- with an assignment where students have to work alone

    context "with an assignment, with a past due date" do
      setup do
        @assignment = Assignment.make(:due_date => 3.days.ago)
      end

      context "inviter of a group" do
        setup do
          @grouping = Grouping.make(:assignment => @assignment)
          sm = StudentMembership.make(
                 :grouping => @grouping,
                 :membership_status => StudentMembership::STATUSES[:inviter],
                 :user => @student)
        end

        should "not be able to invite" do
          student = Student.make
          post_as @student,
                  :invite_member,
                  {:id => @assignment.id,
                  :invite_member => student.user_name}
          assert_redirected_to :action => "student_interface",
                              :id => @assignment.id
          assert_equal I18n.t('invite_student.fail.due_date_passed',
                              :user_name => student.user_name),
                      flash[:fail_notice]
        end
      end
    end  # -- with an assignment, with a past due date
  end  # -- A student

  context "A logged in admin" do
    setup do
      clear_fixtures # don't want fixtures for this test

      # FIXME that context should be *much simpler*
      admin = Admin.make
      @first_assignment_file = AssignmentFile.make
      @second_assignment_file = AssignmentFile.make
      @assignment = Assignment.make
      # Make sure both have the correct assignment associated
      @first_assignment_file.assignment = @assignment
      @first_assignment_file.save
      @second_assignment_file.assignment = @assignment
      @second_assignment_file.save

      assert_equal 2, @assignment.assignment_files.count

      post_as(admin, :edit, :id => @assignment.id,
        :assignment => {
          :short_identifier => @assignment.short_identifier,
          :description => @assignment.description,
          :message => @assignment.message,
          :due_date => @assignment.due_date,
          :assignment_files_attributes => {
            "1" => { :id => @first_assignment_file.id,
                     :filename => @first_assignment_file.filename,
                     :_destroy => "0" },
            "2" => { :id => @second_assignment_file.id,
                     :filename => @second_assignment_file.filename,
                     :_destroy => "1" }, # i.e. this one should get deleted
          },
          :submission_rule_attributes => {
            :type => @assignment.submission_rule.type.to_s,
            :id => @assignment.submission_rule.id
          }
        })
    end

    should "get new assignment page" do
      get_as @admin, :new
      assert_response :success
    end

    should "be able to remove required assignment files using rails >= 2.3.8" do
      @assignment.reload
      assert_equal 1, @assignment.assignment_files.count
      assignment_file = @assignment.assignment_files.first
      assert_equal @first_assignment_file, assignment_file
    end
  end

  context "A logged in admin doing a POST" do

    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:assignment_1)
    end

    context "on new" do
      setup do
        post_as @admin, :new, :id => @assignment.id
      end
      should assign_to :assignment
      should assign_to :assignments
      should respond_with :success
    end

    context "with REPOSITORY_EXTERNAL_SUBMITS_ONLY as false" do
      setup do
        MarkusConfigurator.stubs(:markus_config_repository_external_submits_only?).returns(false)
        get_as @admin, :new
      end
      should "set allow_web_submits accordingly" do
        assignment = assigns(:assignment)
        assert assignment.allow_web_submits == true
      end
    end

    context "with REPOSITORY_EXTERNAL_SUBMITS_ONLY as true" do
      setup do
        MarkusConfigurator.stubs(
          :markus_config_repository_external_submits_only?).returns(true)
        get_as @admin, :new
      end

      should "set allow_web_submits accordingly" do
        assignment = assigns(:assignment)
        assert assignment.allow_web_submits == false
      end
    end
  end # context: A logged in admin doing a GET



  # If for an assignment the due date has passed, but the instructor has set up a grace period,
  # group formation functionality should be still possible
  context "For an assignment, for which the due date has passed but the collection date is
           still in the future," do

    setup do
      @grouping = groupings(:grouping_1)
      @assignment = @grouping.assignment
      grace_period_submission_rule = GracePeriodSubmissionRule.new
      @assignment.replace_submission_rule(grace_period_submission_rule)
      GracePeriodDeduction.destroy_all

      grace_period_submission_rule.save

      # On July 1 at 1PM, the instructor sets up the course...
      pretend_now_is(Time.parse("July 1 2009 1:00PM")) do
        # Due date is on the very same day and time
        @assignment.due_date = Time.parse("July 1 2009 1:00PM")
        # Set 24 grace period
        period = Period.new
        period.submission_rule = @assignment.submission_rule
        period.hours = 24
        period.save
        # Collect date is now after July 2 @ 1PM
        @assignment.save
      end
    end

    context "a logged in student" do

      setup do
        # We need a student with no grouping
        @student = users(:student_interface_controller_test_student)
      end

      should "have the create group link available" do
        # On July 1 at 6PM, the student navigates to the student_interface, which is
        # past the due date of the assignment, but before the grace period ends
        # at July 2 at 1PM.
        response = nil
        pretend_now_is(Time.parse("July 1 2009 6:00PM")) do
          response = get_as(@student, :student_interface, :id => @assignment.id)
        end
        assert_not_nil(response.body =~ /<a[^>]*>#{I18n.t(:create)}<\/a>/)
        assert_nil(response.body =~ /#{I18n.t(:invite)}/)
      end

      should "be able to create a group" do
        # On July 1 at 6PM, the student posts to the creategroup action, which is
        # past the due date of the assignment, but before the grace period ends
        # at July 2 at 1PM.
        response = nil
        pretend_now_is(Time.parse("July 1 2009 6:00PM")) do
          # We should have a create link first, which should later be absent
          response = get_as(@student, :student_interface, :id => @assignment.id)
          assert_not_nil(response.body =~ /<a[^>]*>#{I18n.t(:create)}<\/a>/)
          # Create the group
          response = post_as(@student, :creategroup, :id => @assignment.id)
          assert_equal(response.status, "302 Found", "Should get a redirect!")
          # See if the create link has disappeared
          response = get_as(@student, :student_interface, :id => @assignment.id)
          assert_nil(response.body =~ /<a[^>]*>#{I18n.t(:create)}<\/a>/)
        end
      end

      should "be able to invite students" do
        # On July 1 at 6PM, the student posts to the creategroup action, which is
        # past the due date of the assignment, but before the grace period ends
        # at July 2 at 1PM.
        st2 = users(:student_interface_controller_test_student2)
        response = nil
        pretend_now_is(Time.parse("July 1 2009 6:00PM")) do
          # We should have a create link first, which should later be absent
          response = get_as(@student, :student_interface, :id => @assignment.id)
          assert_not_nil(response.body =~ /<a[^>]*>#{I18n.t(:create)}<\/a>/)
          # Create the group
          response = post_as(@student, :creategroup, :id => @assignment.id)
          assert_equal(response.status, "302 Found", "Should get a redirect!")
          # See if the create link has disappeared
          response = get_as(@student, :student_interface, :id => @assignment.id)
          assert_nil(response.body =~ /<a[^>]*>#{I18n.t(:create)}<\/a>/)
          assert_not_nil(response.body =~ /#{I18n.t(:invite)}/)
          response = post_as(@student, :invite_member, {:id => @assignment.id, :invite_member => st2.user_name})
          assert_not_nil(flash[:success])
        end
      end

      should "not have the create group link available" do
        # On July 1 at 6PM, the student navigates to the student_interface, which is
        # past the due date of the assignment and after the grace period.
        response = nil
        pretend_now_is(Time.parse("July 2 2009 6:00PM")) do
          response = get_as(@student, :student_interface, :id => @assignment.id)
        end
        assert_nil(response.body =~ /<a[^>]*>#{I18n.t(:create)}<\/a>/)
        assert_nil(response.body =~ /#{I18n.t(:invite)}/)
      end

    end # end context logged in student

  end # context assignment past due date, pre collection date

  context "A valid grouping if user is the inviter" do

    should "be possible to delete if inviter is the only member" do
      student_membership = memberships(:membership6)
      grouping = student_membership.grouping
      assert_equal(1, grouping.accepted_students.length)
      user = grouping.inviter
      assignment = grouping.assignment
      assignment.group_min = 1
      assignment.group_max = 2
      assignment.save
      # we don't want submissions for this test
      grouping.submissions.destroy_all
      assert grouping.submissions.empty?
      assert grouping.is_valid?
      post_as(user, :deletegroup, {:id => assignment.id, :grouping_id => grouping.id})
      assert_redirected_to :action => "student_interface", :id => assignment.id
      assert_equal(I18n.t("assignment.group.deleted"), flash[:edit_notice])
      assert !user.has_accepted_grouping_for?(assignment.id)
    end

    should "not be possible to delete if assignment is not group assignment" do
      student_membership = memberships(:membership6)
      grouping = student_membership.grouping
      user = grouping.inviter
      assignment = grouping.assignment
      assignment.group_min = 1
      assignment.save
      assignment.reload
      assert !assignment.group_assignment?
      # we don't want submissions for this test
      grouping.submissions.destroy_all
      assert grouping.is_valid?
      post_as(user, :deletegroup, {:id => assignment.id, :grouping_id => grouping.id})
      assert_redirected_to :action => "student_interface", :id => assignment.id
      assert_equal(I18n.t('groups.cant_delete'), flash[:fail_notice])
      assert user.has_accepted_grouping_for?(assignment.id)
    end

    should "not be possible to delete if inviter is NOT the only member" do
      student_membership = memberships(:membership1)
      grouping = student_membership.grouping
      assert_equal(2, grouping.accepted_students.length)
      user = grouping.inviter
      assignment = grouping.assignment
      assignment.group_min = 1
      assignment.save
      assert grouping.is_valid?
      post_as(user, :deletegroup, {:id => assignment.id, :grouping_id => grouping.id})
      assert_redirected_to :action => "student_interface", :id => assignment.id
      assert_equal I18n.t('groups.cant_delete'), flash[:fail_notice]
      assert user.has_accepted_grouping_for?(assignment.id)
    end

  end

end
