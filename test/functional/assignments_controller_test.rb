require File.dirname(__FILE__) + '/authenticated_controller_test'

class AssignmentsControllerTest < AuthenticatedControllerTest
  
  fixtures  :users, :assignments
  
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
  
  
  # Test create assignment with assignment files and blank text fields
  
  # Test create invalid assignment
  
  
  # Test update invalid assignment without file
  
  # Test update valid assignment without file
  
  # Test update 0-1 file with blank text fields
  
  # Test add and remove at the same time
  
  # Test remove all files
  
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
    student = users(:student3)
    post_as(student, :creategroup, {:id => assignment.id, :workingalone => 'true'})
    assert_redirected_to :action => "student_interface"
    assert student.has_accepted_grouping_for?(assignment.id)
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


  def test_delete_rejected
    assignment = assignments(:assignment_1)
    membership = memberships(:membership3)
    user = users(:student1)
    student = users(:student3)
    post_as(user, :delete_rejected, {:id => assignment.id, :membership => membership.id})
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
  
  def test_cant_delete_group_if_not_inviter
    user = users(:student4)
    grouping = groupings(:grouping_2)
    assignment = grouping.assignment
    grouping.invite(users(:student6).user_name, set_membership_status=StudentMembership::STATUSES[:pending])
    post_as(users(:student6), :deletegroup, {:id => assignment.id})
    assert_equal("You do not currently have a group", flash[:fail_notice])
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
  
end
