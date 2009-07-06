require File.dirname(__FILE__) + '/authenticated_controller_test'

class GroupsControllerTest < AuthenticatedControllerTest
  
  fixtures :users, :assignments, :groupings, :groups, :memberships

  def setup
     @controller = GroupsController.new
     @request = ActionController::TestRequest.new
     @response = ActionController::TestResponse.new
     @admin = users(:olm_admin_1)
     @student = users(:student1)
  end

  #security test!
  def test_student_locked_out
     get_as @student, :add_member
     assert_response :missing

     get_as @student, :remove_member
     assert_response :missing

     get_as @student, :add_group
     assert_response :missing

     get_as @student, :remove_group
     assert_response :missing

     get_as @student, :rename_group
     assert_response :missing

     get_as @student, :valid_grouping
     assert_response :missing

     get_as @student, :manage
     assert_response :missing

     get_as @student, :csv_upload
     assert_response :missing

     get_as @student, :add_csv_group
     assert_response :missing

     get_as @student, :download_grouplist
     assert_response :missing

     get_as @student, :use_another_assignment_groups
     assert_response :missing

     get_as @student, :create_groups_when_students_work_alone
     assert_response :missing
  end

   def test_should_get_student_interface_working_in_group_student
     @assignment = assignments(:assignment_1)
     get_as(@student, :student_interface, {:id => @assignment.id})
     assert_response :success
   end

   def test_should_get_student_interface_working_alone_student
     @assignment = assignments(:assignment_2)
     get_as(@student, :student_interface, {:id => @assignment.id})
     assert_response :success
   end

   def test_should_get_manage
     @assignment = Assignment.first
     get_as(@admin, :manage, {:id => @assignment.id})
     assert_response :success
   end
 
   def test_should_creategroup
      @assignment = Assignment.first
      student = users(:student6)
      post_as(student, :creategroup, {:id => @assignment.id})
      assert_response :success
   end

   def test_should_creategroup_alone
      @assignment = assignments(:assignment_1)
      student = users(:student6)
      post_as(student, :creategroup, {:id => @assignment.id, :workalone => true})
      assert_response :success
   end

   def test_shouldnts_invite_hidden_student
     @assignment = assignments(:assignment_1)
     @grouping = @student.accepted_grouping_for(@assignment.id)
     original_memberships = @grouping.memberships
     student = users(:hidden_student)
     post_as(@student, :invite_member, {:id => @assignment.id, :invite_member => student.id})
     assert_response :success
     assert_equal "Could not invite this student - this student's account has been disabled", flash[:fail_notice]
     assert_equal original_memberships, @grouping.memberships, "Memberships were not equal"
   end

   def test_should_invite_someone
     @assignment = assignments(:assignment_1)
     student = users(:student6)
     post_as(@student, :invite_member, {:id => @assignment.id,
     :invite_member => student.id})
     assert_response :success
     assert_equal 'Student invited.', flash[:edit_notice]
   end

   def test_should_invite_someone_alreadyinvited
     @assignment = assignments(:assignment_1)
     student = users(:student5)
     inviter = users(:student4)
     post_as(inviter, :invite_member, {:id => @assignment.id, :invite_member => student.id})
     assert_response :success
     assert_equal 'This student is already a pending member of this group!', flash[:fail_notice]
   end

   def test_disinvite_member
     @assignment = assignments(:assignment_1)
     membership = memberships(:membership5)
     inviter = users(:student4)
     post_as(inviter, :disinvite_member, {:id => @assignment.id, :membership => membership.id} )
   end

   def test_student_choose_to_join_a_group
      @assignment = assignments(:assignment_1)
      student = users(:student5)
      grouping = groupings(:grouping_2)
      post_as(student, :join, {:id => @assignment.id, :grouping_id =>
      grouping.id})
      assert_response :success
   end

   def test_student_choose_to_decline_an_invitation
      @assignment = assignments(:assignment_1)
      student = users(:student5)
      grouping = groupings(:grouping_2)
      post_as(student, :decline_invitation, {:id => @assignment.id, :grouping_id =>  grouping.id})
      assert_response :success
   end

   def test_delete_rejected
      @assignment = assignments(:assignment_1)
      membership = memberships(:membership3)
      post_as(@student, :delete_rejected, {:id => @assignment.id,
      :membership => membership.id})
      assert_response :success
   end

  def test_remove_member
      @assignment = Assignment.first
      membership = memberships(:membership2)
      grouping = groupings(:grouping_1)
      post_as(@admin, :remove_member, {:id => @assignment.id, :mbr_id =>
      membership.id, :grouping_id => grouping.id})
      assert_response :success
   end

   def test_delete_group_without_submission
     @assignment = assignments(:assignment_1)
     grouping = groupings(:grouping_4)
     post_as(@admin, :delete_group, {:id => @assignment.id, :grouping_id => grouping.id})
     assert_response :success
   end

   def test_remove_member
     @assignment = assignments(:assignment_1)
     grouping = groupings(:grouping_1)
     membership = memberships(:membership2)
     post_as(@admin, :remove_member, {:id => @assignment.id, :grouping_id => grouping.id, :mbr_id => membership.id})
     assert_response :success
   end

   def test_remove_member_inviter
     @assignment = assignments(:assignment_1)
     grouping = groupings(:grouping_1)
     membership = memberships(:membership1)
     post_as(@admin, :remove_member, {:id => @assignment.id, :grouping_id  => grouping.id, :mbr_id => membership.id})
     assert_response :success
   end

   def test_add_group_without_groupname
     @assignment = assignments(:assignment_1)
     post_as(@admin, :add_group, {:id => @assignment.id})
     assert_response :success
   end

   def test_add_group_with_groupname
     @assignment = assignments(:assignment_1)
     post_as(@admin, :add_group, {:id => @assignment.id, :new_group_name => "test"})
     assert_response :success
   end

   def test_remove_group_without_submission
     @assignment = assignments(:assignment_1)
     grouping = groupings(:grouping_4)
     post_as(@admin, :remove_group, {:id => @assignment.id, :grouping_id => grouping.id})
     assert_response :success
   end

   def test_rename_grouping
     assignment = assignments(:assignment_1)
     grouping = groupings(:grouping_4)
     post_as(@admin, :valid_grouping, {:id => assignment.id, :grouping_id => grouping.id, :new_groupname => "NeW"})
    assert_response :success
   end


   def test_valid_grouping
     assignment = assignments(:assignment_1)
     grouping = groupings(:grouping_4)
     post_as(@admin, :valid_grouping, {:id => assignment.id, :grouping_id => grouping.id})
     assert_response :success
   end

   def test_use_another_assignment_groups
      source_assignment = assignments(:assignment_1)
      target_assignment = assignments(:assignment_3)
      post_as(@admin, :use_another_assignment_groups, {:id => target_assignment.id, :clone_groups_assignment_id => source_assignment.id})
      assert_response :success
      assert_equal("Groups created", flash[:edit_notice])
   end

end
