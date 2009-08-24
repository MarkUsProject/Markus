require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'fastercsv'

class AssignmentsControllerTest < AuthenticatedControllerTest
  
  fixtures  :users, :assignments, :rubric_criteria, :marks, :submission_rules
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
      'due_date(2i)'  => '',
      'due_date(2i)'  => '',
      'due_date(2i)'  => '',
    }
    setup_group_fixture_repos
    
  end
  
  def teardown
    destroy_repos
  end
  
  # Test for accessing new assignment page
  def test_get_new
    get_as @admin, :new
    assert_response :success
  end
  
  # TODO
  
  
  # Test create assignment with assignment files
  def test_create_assignment
    get_as @admin, :new
    
  end
    
  # Student Interface Tests
  def test_join_group
    assignment = assignments(:assignment_1)
    student = users(:student5)
    grouping = groupings(:grouping_2)
    post_as(student, :join_group, {:id => assignment.id, :grouping_id =>
    grouping.id} )
    assert student.has_accepted_grouping_for?(assignment.id), "should
    have accepted grouping for this assignment"
  end

  def test_decline_invitation
    assignment = assignments(:assignment_1)
    student = users(:student5)
    grouping = groupings(:grouping_2)
    post_as(student, :decline_invitation, {:id => assignment.id, :grouping_id =>
    grouping.id} )
    assert !student.has_accepted_grouping_for?(assignment.id), "should not
    have accepted groupings for this assignment"
    assert !student.has_pending_groupings_for?(assignment.id), "should
    not have pending groupings for this assignment"
  end

  def test_create_group_working_alone
    assignment = assignments(:assignment_1)
    assignment.group_min = 1
    assignment.save
    student = users(:student3)
    post_as(student, :creategroup, {:id => assignment.id, :workalone => 'true'})
    assert_redirected_to :action => "student_interface"
    assert student.has_accepted_grouping_for?(assignment.id)
    grouping = student.accepted_grouping_for(assignment.id)
    assert grouping.is_valid?
  end
 
  def test_student_cannot_work_alone_if_group_min_not_one
    assignment = assignments(:assignment_1)
    assignment.group_min = 2
    assignment.save
    student = users(:student3)
    post_as(student, :creategroup, {:id => assignment.id, :workalone => 'true'})
    assert_redirected_to :action => "student_interface"
    assert_equal("You cannot work alone for this assignment - the group size minimum is #{assignment.group_min}", flash[:fail_notice])
    assert !student.has_accepted_grouping_for?(assignment.id)
  end

  def test_create_group
    assignment = assignments(:assignment_1)
    student = users(:student3)
    post_as(student, :creategroup, {:id => assignment.id})
    assert_redirected_to :action => "student_interface"
    assert student.has_accepted_grouping_for?(assignment.id)
  end
  
  def test_students_cannot_create_groups_if_instructors_create_groups
    assignment = assignments(:assignment_1)
    assignment.instructor_form_groups = true
    assignment.student_form_groups = false
    assignment.save
    student = users(:student3)
    post_as(student, :creategroup, {:id => assignment.id})
    assert_equal("Assignment does not allow students to form groups", flash[:fail_notice])
  end
  
  def test_student_cannot_create_group_if_already_grouped
    assignment = assignments(:assignment_1)
    student = users(:student3)
    post_as(student, :creategroup, {:id => assignment.id})
    assert_redirected_to :action => "student_interface"
    assert student.has_accepted_grouping_for?(assignment.id)
    
    grouping = student.accepted_grouping_for(assignment.id)
    
    post_as(student, :creategroup, {:id => assignment.id})
    assert_redirected_to :action => "student_interface"
    assert_equal "You already have a group, and cannot create another", flash[:fail_notice]
    # Get past some possible caching here...
    student = Student.find(student.id)
    assert student.has_accepted_grouping_for?(assignment.id)
    assert_equal grouping, student.accepted_grouping_for(assignment.id)

  end
  
  def test_invite_member
    assignment = assignments(:assignment_1)
    student = users(:student1)
    invited = users(:student5)
    post_as(student, :invite_member, {:id => assignment.id, :invite_member => invited.user_name})
    assert_equal(I18n.t('invite_student.success', :user_name => invited.user_name), flash[:success].first)
    assert_redirected_to :action => "student_interface"
  end

  def test_cant_invite_hidden_student
    assignment = assignments(:assignment_1)
    student = users(:student1)
    invited = users(:hidden_student)
    post_as(student, :invite_member, {:id => assignment.id, :invite_member => invited.user_name})
    assert_redirected_to :action => "student_interface"
    assert_equal(I18n.t('invite_student.fail.hidden', :user_name => invited.user_name), flash[:fail_notice].first)
  end

  def test_cant_invite_already_pending
    assignment = assignments(:assignment_1)
    student = users(:student4)
    invited = users(:student5)
    post_as(student, :invite_member, {:id => assignment.id, :invite_member => invited.user_name})
    assert_redirected_to :action => "student_interface"
    assert_equal(I18n.t('invite_student.fail.already_pending', :user_name => invited.user_name), flash[:fail_notice].first)
  end

  def test_cant_invite_student_who_dne
    assignment = assignments(:assignment_1)
    student = users(:student4)
    post_as(student, :invite_member, {:id => assignment.id, :invite_member => "zhfbdjhzkyfg"})
    assert_redirected_to :action => "student_interface"
    assert_equal(I18n.t('invite_student.fail.dne', :user_name => 'zhfbdjhzkyfg'), flash[:fail_notice].first)
  end
  
  def test_cant_invite_student_after_due_date
    assignment = assignments(:assignment_1)
    assignment.due_date = 2.days.ago
    assignment.save(false)
    student = users(:student4)
    target = users(:student5)
    assert !target.has_accepted_grouping_for?(assignment.id)
    post_as(student, :invite_member, {:id => assignment.id, :invite_member => target.user_name})
    assert_redirected_to :action => "student_interface"
    assert_equal(I18n.t('invite_student.fail.due_date_passed', :user_name => target.user_name), flash[:fail_notice].first)
  
  end
  
  def test_invite_multiple_students
    assignment = assignments(:assignment_1)
    inviter = users(:student4)
    students = [users(:student1), users(:student2), users(:student3), users(:student5), users(:student6)]
    user_names = students.collect { |student| student.user_name }.join(',')
    post_as(users(:student4), :invite_member, {:id => assignment.id, :invite_member => user_names})  
    assert_redirected_to :action => "student_interface"
    grouping = inviter.accepted_grouping_for(assignment.id)
    assert_equal 3, grouping.pending_students.size
  end
  
  def test_invite_multiple_students_with_invalid
    assignment = assignments(:assignment_1)
    inviter = users(:student4)
    students = [users(:student1), users(:student2), users(:student3), users(:student5), users(:student6)]
    invalid_users = ['%(*&@#$(*#$EJDF','falsj asdlfkjasdl aslkdjasd,dasflk(*!@*@*@!!!','lkjsdlkfjsdfsdlkfjsfsdf']
    user_names = ((students.collect { |student| student.user_name }) + invalid_users).join(',')
    post_as(users(:student4), :invite_member, {:id => assignment.id, :invite_member => user_names})  
    assert_redirected_to :action => "student_interface"
    grouping = inviter.accepted_grouping_for(assignment.id)
    assert_equal 3, grouping.pending_students.size
  end
  
  def test_invite_multiple_students_with_spacing
    assignment = assignments(:assignment_1)
    inviter = users(:student4)
    students = [users(:student1), users(:student2), users(:student3), users(:student5), users(:student6)]
    user_names = students.collect { |student| student.user_name }.join(' ,  ')
    post_as(users(:student4), :invite_member, {:id => assignment.id, :invite_member => user_names})  
    assert_redirected_to :action => "student_interface"
    grouping = inviter.accepted_grouping_for(assignment.id)
    assert_equal 3, grouping.pending_students.size
  end
  
  def test_cannot_invite_self_to_group
    assignment = assignments(:assignment_1)
    inviter = users(:student4)
    original_pending = inviter.accepted_grouping_for(assignment.id).pending_students.size
    students = [users(:student6), users(:student4)]
    user_names = students.collect { |student| student.user_name }.join(' ,  ')
    post_as(users(:student4), :invite_member, {:id => assignment.id, :invite_member => user_names})  
    assert_redirected_to :action => "student_interface"
    grouping = inviter.accepted_grouping_for(assignment.id)
    assert_equal original_pending + 1, grouping.pending_students.size
    assert_equal(I18n.t('invite_student.fail.inviting_self'), flash[:fail_notice].first)
  end
  
  def test_cannot_invite_admins
    assignment = assignments(:assignment_1)
    inviter = users(:student4)
    original_pending = inviter.accepted_grouping_for(assignment.id).pending_students.size
    admins = [users(:olm_admin_1), users(:olm_admin_2)]
    user_names = admins.collect { |admin| admin.user_name }.join(' ,  ')
    post_as(users(:student4), :invite_member, {:id => assignment.id, :invite_member => user_names})  
    assert_redirected_to :action => "student_interface"
    grouping = inviter.accepted_grouping_for(assignment.id)
    assert_equal original_pending, grouping.pending_students.size
    assert_equal(I18n.t('invite_student.fail.dne', :user_name => users(:olm_admin_1).user_name), flash[:fail_notice][0])
    assert_equal(I18n.t('invite_student.fail.dne', :user_name => users(:olm_admin_2).user_name), flash[:fail_notice][1])
  end
  
  def test_cannot_invite_graders
    assignment = assignments(:assignment_1)
    inviter = users(:student4)
    original_pending = inviter.accepted_grouping_for(assignment.id).pending_students.size
    graders = [users(:ta1), users(:ta2)]
    user_names = graders.collect { |grader| grader.user_name }.join(' ,  ')
    post_as(users(:student4), :invite_member, {:id => assignment.id, :invite_member => user_names})  
    assert_redirected_to :action => "student_interface"
    grouping = inviter.accepted_grouping_for(assignment.id)
    assert_equal original_pending, grouping.pending_students.size
    assert_equal(I18n.t('invite_student.fail.dne', :user_name => users(:ta1).user_name), flash[:fail_notice][0])
    assert_equal(I18n.t('invite_student.fail.dne', :user_name => users(:ta2).user_name), flash[:fail_notice][1])
  end
  
  def test_cannot_invite_unless_group_created
    assignment = assignments(:assignment_1)
    inviter = users(:student6)
    students = [users(:student1), users(:student2), users(:student3), users(:student5)]
    user_names = students.collect { |student| student.user_name }.join(' ,  ')
    assert_raises RuntimeError do
      post_as(users(:student6), :invite_member, {:id => assignment.id, :invite_member => user_names})  
    end
  end

  def test_disinvite_member
    assignment = assignments(:assignment_1)
    membership = memberships(:membership5)
    user = users(:student4)
    student = users(:student5)
    post_as(user, :disinvite_member, {:id => assignment.id, :membership => membership.id})
    assert_response :success
    assert_equal("Member disinvited", flash[:edit_notice])
    assert !student.has_pending_groupings_for?(assignment.id)
  end


  def test_inviter_can_delete_rejected
    membership = memberships(:membership3)
    grouping = membership.grouping
    assignment = grouping.assignment
    user = grouping.inviter
    assert_equal grouping.inviter, user
    assert_nothing_raised do
      post_as(user, :delete_rejected, {:id => assignment.id, :membership => membership.id})
    end
    assert_raises ActiveRecord::RecordNotFound do
      membership = StudentMembership.find(membership.id)
    end
    assert_response :redirect
    assert_redirected_to :action => 'student_interface'
  end
  
  def test_cant_delete_rejected_if_not_inviter
    membership = memberships(:membership3)
    grouping = membership.grouping
    assignment = grouping.assignment
    user = users(:student4)
    student = users(:student3)
    assert grouping.inviter != user
    assert_raises RuntimeError do
      post_as(user, :delete_rejected, {:id => assignment.id, :membership => membership.id})
    end
    assert_nothing_raised do
      membership = StudentMembership.find(membership.id)
    end
    assert !membership.nil?
    assert_response :success
  end

  def test_deletegroup
    user = users(:student4)
    grouping = groupings(:grouping_2)
    assignment = grouping.assignment
    assignment.group_min = 4
    assignment.save
    assert !grouping.is_valid?
    post_as(user, :deletegroup, {:id => assignment.id, :grouping_id => grouping.id})
    assert_redirected_to :action => "student_interface"
    assert_equal("Group has been deleted", flash[:edit_notice])
    assert !user.has_accepted_grouping_for?(assignment.id)
  end
  
  def test_cant_delete_group_if_not_inviter_and_pending
    user = users(:student4)
    grouping = groupings(:grouping_2)
    assignment = grouping.assignment
    grouping.invite(users(:student6).user_name, set_membership_status=StudentMembership::STATUSES[:pending])
    post_as(users(:student6), :deletegroup, {:id => assignment.id})
    assert_equal("You do not currently have a group", flash[:fail_notice])
    assert user.has_accepted_grouping_for?(assignment.id)
  end  

  def test_cant_delete_group_if_not_inviter_and_accepted
    user = users(:student4)
    grouping = groupings(:grouping_2)
    assignment = grouping.assignment
    grouping.invite(users(:student6).user_name, set_membership_status=StudentMembership::STATUSES[:accepted])
    post_as(users(:student6), :deletegroup, {:id => assignment.id})
    assert_equal("Only the inviter can delete the group", flash[:fail_notice])
    assert user.has_accepted_grouping_for?(assignment.id)
  end  
  
  def test_cant_delete_group_if_has_submission
    user = users(:student4)
    grouping = groupings(:grouping_2)
    assignment = grouping.assignment
    assignment.group_min = 2
    assignment.save
    grouping.invite(users(:student6).user_name, set_membership_status=StudentMembership::STATUSES[:accepted])
    grouping.create_grouping_repository_folder
    assert grouping.is_valid?
    Submission.create_by_timestamp(grouping, Time.now)
    grouping = Grouping.find(grouping.id)
    assert grouping.has_submission?   
    post_as(users(:student4), :deletegroup, {:id => assignment.id})
    assert_equal("You already submitted something. You cannot delete your group.", flash[:fail_notice])
    assert user.has_accepted_grouping_for?(assignment.id)
  end

  
  def test_cant_delete_if_group_valid
    assignment = assignments(:assignment_1)
    assignment.group_min = 1
    assignment.save
    user = users(:student4)
    grouping = user.accepted_grouping_for(assignment.id)
    assert grouping.is_valid?
    post_as(user, :deletegroup, {:id => assignment.id})
    assert_equal("Your group is valid, and can only be deleted by instructors.", flash[:fail_notice])
    assert user.has_accepted_grouping_for?(assignment.id)
  end
  
  def test_students_cant_access_grades_report
    user = users(:student4)
    get_as(user, :download_csv_grades_report)
    assert_response :missing
  end

  def test_graders_cant_access_grades_report
    user = users(:ta1)
    get_as(user, :download_csv_grades_report)
    assert_response :missing
  end
  
  def test_admins_can_get_csv_grades_report
    # Insert a student that won't have a grouping
    s = Student.new
    s.first_name = 'Test'
    s.last_name = 'Test'
    s.user_name = 'Test'
    assert s.valid?
    s.save
    
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
            assert !grouping.has_submission?
          else
            # Student didn't have a grouping, so it was OK that this
            # column was blank
          end
        else
          out_of = assignments[index].total_mark
          grouping = student.accepted_grouping_for(assignments[index])
          assert_not_nil grouping
          assert grouping.has_submission?
          submission = grouping.get_submission_used
          assert_not_nil submission.result
          assert_equal final_mark.to_f, (submission.result.total_mark / out_of * 100).to_f
        end
      end
      
    end
    
    assert_response :success
  end
  
  def test_cannot_get_group_properties_if_student
    get_as(users(:student1), :update_group_properties_on_persist, :assignment_id => assignments(:assignment_1).id)
    assert_response :missing
  end
  
  def test_cannot_get_group_properties_if_grader
    get_as(users(:ta1), :update_group_properties_on_persist, :assignment_id => assignments(:assignment_1).id)
    assert_response :missing

  end
  
  def test_update_group_properties_on_persist
    assignment = assignments(:assignment_1)
    get_as(@admin, :update_group_properties_on_persist, :assignment_id => assignment.id)
    assert assigns(:assignment)
    assert_equal assignment, assigns(:assignment)
  end
  
  def test_cannot_edit_if_student
    get_as(users(:student4), :edit, :id => assignments(:assignment_1).id)
    assert_response :missing
  end
  
  def test_cannot_edit_if_grader
    get_as(users(:ta1), :edit, :id => assignments(:assignment_1).id)
    assert_response :missing
  end
  
  def test_get_edit_form_if_not_post
    get_as(@admin, :edit, :id => assignments(:assignment_1).id)
    assert_response :success
    assert assigns(:assignment)
  end
  
  def test_edit_basic_params
    post_as(@admin, :edit, :id => assignments(:assignment_1).id, 
      :assignment => {
        :short_identifier => 'New SI', 
        :description => 'New Description',
        :message => 'New Message',
        :due_date => 3.days.from_now,
        :submission_rule_attributes => {
          :type => assignments(:assignment_1).submission_rule.type.to_s, 
          :id => assignments(:assignment_1).submission_rule.id
        }
      })
    a = Assignment.find(assignments(:assignment_1).id)
    assert_equal 'New SI', a.short_identifier
    assert_equal 'New Description', a.description
    assert_equal 'New Message', a.message
    assert ((3.days.from_now - a.due_date).abs < 5)
  end

  def test_cant_edit_with_invalid_params
    original_assignment = assignments(:assignment_1)
    post_as(@admin, :edit, :id => assignments(:assignment_1).id, 
      :assignment => {
        :short_identifier => '', 
        :description => 'New Description',
        :message => 'New Message',
        :due_date => 3.days.from_now,
        :submission_rule_attributes => {
          :type => assignments(:assignment_1).submission_rule.type.to_s, 
          :id => assignments(:assignment_1).submission_rule.id
        }
      })
    a = Assignment.find(assignments(:assignment_1).id)
    assert_equal original_assignment.short_identifier, a.short_identifier
    assert_equal original_assignment.description, a.description
    assert_equal original_assignment.message, a.message
    assert_equal original_assignment.due_date, a.due_date
    assert_not_nil assigns(:assignment)
    assert !assigns(:assignment).errors.empty?
  end
  
  def test_cant_pass_non_submission_rule_class
    original_assignment = assignments(:assignment_1)
    post_as(@admin, :edit, :id => assignments(:assignment_1).id, 
      :assignment => {
        :short_identifier => 'New SI', 
        :description => 'New Description',
        :message => 'New Message',
        :due_date => 3.days.from_now,
        :submission_rule_attributes => {
          :type => 'UnknownClass', 
          :id => assignments(:assignment_1).submission_rule.id
        }
      })
    a = Assignment.find(assignments(:assignment_1).id)
    assert_equal original_assignment.short_identifier, a.short_identifier
    assert_equal original_assignment.description, a.description
    assert_equal original_assignment.message, a.message
    assert_equal original_assignment.due_date, a.due_date
    assert_equal original_assignment.submission_rule.type.to_s, a.submission_rule.type.to_s
    assert_not_nil assigns(:assignment)
    assert !assigns(:assignment).errors.empty?
  end

  def test_cant_pass_non_submission_rule_class_2
    original_assignment = assignments(:assignment_1)
    post_as(@admin, :edit, :id => assignments(:assignment_1).id, 
      :assignment => {
        :short_identifier => 'New SI', 
        :description => 'New Description',
        :message => 'New Message',
        :due_date => 3.days.from_now,
        :submission_rule_attributes => {
          :type => 'Student', 
          :id => assignments(:assignment_1).submission_rule.id
        }
      })
    a = Assignment.find(assignments(:assignment_1).id)
    assert_equal original_assignment.short_identifier, a.short_identifier
    assert_equal original_assignment.description, a.description
    assert_equal original_assignment.message, a.message
    assert_equal original_assignment.due_date, a.due_date
    assert_equal original_assignment.submission_rule.type.to_s, a.submission_rule.type.to_s
    assert_not_nil assigns(:assignment)
    assert !assigns(:assignment).errors.empty?
  end

  def test_can_change_submission_rule_class_without_periods
    original_assignment = assignments(:assignment_1)
    post_as(@admin, :edit, :id => assignments(:assignment_1).id, 
      :assignment => {
        :short_identifier => 'New SI', 
        :description => 'New Description',
        :message => 'New Message',
        :due_date => 3.days.from_now,
        :submission_rule_attributes => {
          :type => 'PenaltyPeriodSubmissionRule', 
          :id => assignments(:assignment_1).submission_rule.id
        }
      })
    a = Assignment.find(assignments(:assignment_1).id)
    assert_equal 'New SI', a.short_identifier
    assert_equal 'New Description', a.description
    assert_equal 'New Message', a.message
    assert_equal "PenaltyPeriodSubmissionRule", a.submission_rule.type.to_s
    assert_not_nil assigns(:assignment)
    assert assigns(:assignment).errors.empty?
  end
  
  def test_can_change_submission_rule_class_with_periods
    original_assignment = assignments(:assignment_1)
    post_as(@admin, :edit, :id => assignments(:assignment_1).id, 
      :assignment => {
        :short_identifier => 'New SI', 
        :description => 'New Description',
        :message => 'New Message',
        :due_date => 3.days.from_now,
        :submission_rule_attributes => {
          :type => 'PenaltyPeriodSubmissionRule', 
          :id => assignments(:assignment_1).submission_rule.id,
          :periods_attributes => [
            {:deduction => '10', :hours => '24'},
            {:deduction => '20', :hours => '24'}
          ]
        }
      })
    a = Assignment.find(assignments(:assignment_1).id)
    assert_equal 'New SI', a.short_identifier
    assert_equal 'New Description', a.description
    assert_equal 'New Message', a.message
    assert_equal "PenaltyPeriodSubmissionRule", a.submission_rule.type.to_s
    assert_equal 2, a.submission_rule.periods.length
    first_period = a.submission_rule.periods.first
    last_period = a.submission_rule.periods.last
    assert_equal 10, first_period.deduction
    assert_equal 24, first_period.hours
    assert_equal 20, last_period.deduction
    assert_equal 24, last_period.hours

    assert_not_nil assigns(:assignment)
    assert assigns(:assignment).errors.empty?
    
  end
  

  def test_setting_instructor_forms_groups
    original_assignment = assignments(:assignment_1)
    post_as(@admin, :edit, {:id => assignments(:assignment_1).id, 
      :assignment => {
        :short_identifier => 'New SI', 
        :description => 'New Description',
        :message => 'New Message',
        :due_date => 3.days.from_now,
        :student_form_groups => '0',
        :submission_rule_attributes => {
          :type => 'NoLateSubmissionRule', 
          :id => assignments(:assignment_1).submission_rule.id
        }
        },
      :is_group_assignment => 'true'
      
      })
    a = Assignment.find(assignments(:assignment_1).id)
    assert_equal 'New SI', a.short_identifier
    assert_equal 'New Description', a.description
    assert_equal 'New Message', a.message
    assert_equal original_assignment.submission_rule.type.to_s, a.submission_rule.type.to_s
    assert a.instructor_form_groups
    assert !a.student_form_groups
    assert_not_nil assigns(:assignment)
    assert assigns(:assignment).errors.empty?
  end
  
  def test_setting_students_forms_groups
    original_assignment = assignments(:assignment_1)
    post_as(@admin, :edit, {:id => assignments(:assignment_1).id, 
      :assignment => {
        :short_identifier => 'New SI', 
        :description => 'New Description',
        :message => 'New Message',
        :due_date => 3.days.from_now,
        :student_form_groups => 'true',
        :submission_rule_attributes => {
          :type => 'NoLateSubmissionRule', 
          :id => assignments(:assignment_1).submission_rule.id
        }
        },
      :is_group_assignment => 'true'
      
      })
    a = Assignment.find(assignments(:assignment_1).id)
    assert_equal 'New SI', a.short_identifier
    assert_equal 'New Description', a.description
    assert_equal 'New Message', a.message
    assert_equal original_assignment.submission_rule.type.to_s, a.submission_rule.type.to_s
    assert a.student_form_groups
    assert !a.instructor_form_groups
    assert_not_nil assigns(:assignment)
    assert assigns(:assignment).errors.empty?
  end
  
  def test_on_index_student_gets_assignment_results
    get_as(users(:student1), :index)
    assert assigns(:a_id_results)
    assert assigns(:assignments)
    assert_response :success
  end
  
  # TODO:  A test to make sure that @a_id_results from index actually
  # does proper computing of averages/etc
  def test_student_gets_accurate_average_per_assignment
    assert false
  end
  
  def test_on_index_grader_gets_assignment_list
    get_as(users(:ta1), :index)
    assert assigns(:assignments)
    assert_response :success 
  end

  def test_on_index_instructor_gets_assignment_list
    get_as(@admin, :index)
    assert assigns(:assignments)
    assert_response :success 
  end
  
  def test_instructor_bounced_from_student_interface
    get_as(@admin, :student_interface, :id => assignments(:assignment_1).id)
    assert_response :missing
  end

  def test_grader_bounced_from_student_interface
    get_as(users(:ta1), :student_interface, :id => assignments(:assignment_1).id)
    assert_response :missing
  end
  
  def test_student_gets_student_interface
    get_as(users(:student1), :student_interface, :id => assignments(:assignment_1).id)
    assert assigns(:assignment)
    assert assigns(:pending_grouping).nil?
    assert_response :success
  end
  
  def test_student_gets_solo_grouping_automatically
    # Destroy the grouping for a student
    assignment = assignments(:assignment_1)
    student = users(:student1)
    grouping = student.accepted_grouping_for(assignment.id)
    if !grouping.nil?
      grouping.destroy
    end
    student.reload
    assert !student.has_accepted_grouping_for?(assignment.id)
    assert student.accepted_grouping_for(assignment.id).nil?
    # Make this a solo assignment
    assignment.group_max = 1
    assignment.group_min = 1
    assignment.instructor_form_groups = false
    assignment.student_form_groups = false
    assignment.save

    get_as(users(:student1), :student_interface, :id => assignment.id)
    student = Student.find(student.id)
    assert student.has_accepted_grouping_for?(assignment.id)
    assert_not_nil student.accepted_grouping_for(assignment.id)
    assert_equal student, student.accepted_grouping_for(assignment.id).inviter
    assert_redirected_to :action => 'student_interface'
  end
  
  def test_student_gets_list_of_pending_groupings
    # Destroy the grouping for a student
    assignment = assignments(:assignment_1)
    student = users(:student1)
    grouping = student.accepted_grouping_for(assignment.id)
    if !grouping.nil?
      grouping.destroy
    end
    student.reload
    assert !student.has_accepted_grouping_for?(assignment.id)
    assert student.accepted_grouping_for(assignment.id).nil?
    # Make this a group assignment
    assignment.group_max = 4
    assignment.group_min = 2
    assignment.instructor_form_groups = false
    assignment.student_form_groups = true
    assignment.save
    
    # Create some pending invitations for this student
    invitations = 0
    assignment.groupings.each do |some_grouping|
      if some_grouping.student_memberships.length > 0
        invitations = invitations + 1
        some_grouping.invite(student.user_name)
      end
    end

    get_as(users(:student1), :student_interface, :id => assignment.id)
    assert_response :success
    assert assigns(:pending_grouping)
    assert_equal invitations, assigns(:pending_grouping).length
  end
  
end
