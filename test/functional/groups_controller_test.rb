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

   def test_should_invite_someone
     @assignment = assignments(:assignment_1)
     student = users(:student6)
     post_as(@student, :invite_member, {:id => @assignment.id,
     :invite_member => student.id})
     assert_response :success
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

#   def test_invite_member
#      @assignment = Assignment.first
#      student2 = users(:student2)
#      student.remove_member
#      post_as(@student, :invite_member, {:id => @assignment.id})
#   end

end
