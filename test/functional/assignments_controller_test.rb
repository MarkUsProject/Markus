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
    assert_response :success
    assert student.has_accepted_grouping_for?(assignment.id)
  end

  def test_create_group
    assignment = assignments(:assignment_1)
    student = users(:student3)
    post_as(student, :creategroup, {:id => assignment.id})
    assert_response :success
    assert student.has_accepted_grouping_for?(assignment.id)
  end

  def test_invite_member1
    assignment = assignments(:assignment_1)
    student = users(:student1)
    invited = users(:student5)
    post_as(student, :invite_member, {:id => assignment.id, :invite_member => invited.user_name})
    assert_response :success
    assert_equal("Student invited.", flash[:edit_notice])
  end

  def test_invite_member2
    assignment = assignments(:assignment_1)
    student = users(:student1)
    invited = users(:hidden_student)
    post_as(student, :invite_member, {:id => assignment.id, :invite_member => invited.user_name})
    assert_response :success
    assert_equal("Could not invite this student - this student's account has been disable.", flash[:fail_notice])
  end

  def test_invite_member3
    assignment = assignments(:assignment_1)
    student = users(:student4)
    invited = users(:student5)
    post_as(student, :invite_member, {:id => assignment.id, :invite_member => invited.user_name})
    assert_response :success
    assert_equal("This student is already a pending member of this group!", flash[:fail_notice])
  end

  def test_invite_member4
    assignment = assignments(:assignment_1)
    student = users(:student4)
    post_as(student, :invite_member, {:id => assignment.id, :invite_member => "zhfbdjhzkyfg"})
    assert_response :success
    assert_equal("This student doesn't exist.", flash[:fail_notice])
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
    assignment = assignments(:assignment_1)
    user = users(:student4)
    grouping = groupings(:grouping_2)
    post_as(user, :deletegroup, {:id => assignment.id, :grouping_id => grouping.id})
    assert_response :success
    assert_equal("Group has been deleted", flash[:edit_notice])
    assert !user.has_accepted_grouping_for?(assignment.id)
  end
end
