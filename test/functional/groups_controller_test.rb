require File.expand_path(File.join(File.expand_path(File.dirname(__FILE__)), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

## TODO refactor this code

class GroupsControllerTest < AuthenticatedControllerTest

  context 'An authenticated and authorized student doing a ' do

    setup do
      @student = Student.make
      @assignment = Assignment.make
    end

    should 'GET on :new' do
      get_as @student, :new, assignment_id: @assignment.id
      assert_response :missing
    end

    should 'GET on :remove_group' do
      get_as @student, :remove_group, assignment_id: @assignment.id
      assert_response :missing
    end

    should 'GET on :rename_group' do
      get_as @student, :rename_group, assignment_id: @assignment.id
      assert_response :missing
    end

    should 'GET on :valid_grouping' do
      get_as @student, :valid_grouping, assignment_id: @assignment.id
      assert_response :missing
    end

    should 'GET on :invalid_grouping' do
      get_as @student, :invalid_grouping, assignment_id: @assignment.id
      assert_response :missing
    end

    should 'GET on :index' do
      get_as @student, :index, assignment_id: @assignment.id
      assert_response :missing
    end

    should 'GET on :csv_upload' do
      get_as @student, :csv_upload, assignment_id: @assignment.id
      assert_response :missing
    end

    should 'GET on :download_grouplist' do
      get_as @student, :download_grouplist, assignment_id: @assignment.id
      assert_response :missing
    end

    should 'POST on :use_another_assignment_groups' do
      post_as @student,
             :use_another_assignment_groups,
             assignment_id: @assignment.id
      assert_response :missing
    end

  end #student context

  context 'An authenticated and authorized admin doing a ' do

    setup do
      @admin = Admin.make
      @grouping = Grouping.make
      @assignment = Assignment.make(groupings: [@grouping])
    end

    should 'GET on :index(groups_controller)' do
      get_as @admin,
             :index,
             assignment_id: @assignment.id
      assert_response :success
    end

    should 'GET on :index' do
      get_as @admin,
             :index,
             assignment_id: @assignment.id
      assert_response :success
    end

    context 'GET on :add_group' do

      should 'be able to add group without groupname' do
        @assignment = Assignment.make
        Assignment.any_instance.stubs(:add_group).returns(Grouping.make)
        get_as @admin, :new, assignment_id: @assignment.id
        assert_response :success
      end

      should 'be able to create with groupname' do
        get_as @admin, :new,
          { assignment_id: @assignment.id, new_group_name: 'test' }
        assert_response :success
      end
    end #:add_group

    context 'DELETE on :remove_group' do

      should 'on group without a submission' do
        delete_as @admin,
                 :remove_group,
                 {assignment_id: @assignment.id,
                  grouping_id: @grouping.id}
        assert_response :success
        assert_not_nil assigns(:assignment) { @assignment }
        assert_not_nil assigns(:errors) { [] }
        assert_not_nil assigns(:removed_groupings) { [@grouping] }
      end

      should 'on group with a submission' do
        @grouping_with_submission = Grouping.make
        delete_as @admin,
                  :remove_group,
                  {assignment_id: @assignment.id,
                   grouping_id: @grouping_with_submission.id}
        assert_response :success
        assert_not_nil assigns(:assignment) { Assignment.make }
        assert_not_nil assigns(:errors) { [@grouping_with_submission.group.group_name] }
        assert_not_nil assigns(:removed_groupings) { [] }
      end

    end #:remove_group

    context 'POST on :rename_group' do

      should 'with unique, new name' do
        @new_name = 'NeW'
        post_as @admin,
                :rename_group, {assignment_id: @assignment.id,
          id: @grouping.id, new_groupname: @new_name, format: 'js'}
        assert_not_nil assigns :assignment
        assert_not_nil assigns :grouping
        assert_not_nil assigns :group
        assert_equal @new_name, assigns(:group).group_name
        assert_response :success
      end

      should 'with existing name' do
        @new_name = Grouping.make.group.group_name
        post_as @admin, :rename_group, {assignment_id: @assignment.id,
          id: @grouping.id, new_groupname: @new_name, format: 'js'}
        assert_response :success
        assert_equal @grouping.group.group_name, assigns(:group).group_name
      end
    end #:rename_group

    should 'POST on :valid_grouping' do
      post_as @admin, :valid_grouping, {assignment_id: @assignment.id,
        grouping_id: @grouping.id}
      assert_response :success
    end

    should 'POST on :invalid_grouping' do
      post_as @admin, :invalid_grouping, {assignment_id: @assignment.id,
        grouping_id: @grouping.id}
      assert_response :success
    end

    should 'be able to clone groups from another assignment' do
      target_assignment = Assignment.make
      @request.env['HTTP_REFERER'] = "assignments/#{target_assignment.id}/groups"
      post_as @admin,
              :use_another_assignment_groups,
              { assignment_id: target_assignment.id,
                clone_assignment_id: @assignment.id }

      assert_response :found
      assert render_template 'index', formats: [:'js.jsx'], handlers: [:erb]
    end

    should 'should be able to delete without groupings' do
      post_as @admin, :global_actions, {assignment_id: @assignment.id,
        global_actions: 'delete'}
      # check error: must select grouping
      assert_response 400
    end

    should 'be able to delete a grouping' do
      post_as @admin, :global_actions, {assignment_id: @assignment.id,
          global_actions: 'delete', groupings: [@grouping.id]}
      assert_response :success
    end

    should 'should not be able to do invalid any students' do
      post_as @admin, :global_actions, {assignment_id: @assignment.id,
        global_actions: 'invalid'}
      # check error: must select students
      assert_response 400
    end

    should 'should be able to invalide a selected grouping' do
      post_as @admin, :global_actions, {assignment_id: @assignment.id,
        global_actions: 'invalid', groupings: [@grouping.id]}
      assert_response :success
    end

    should 'be able to validate' do
      post_as @admin, :global_actions, {assignment_id: @assignment.id,
        global_actions: 'valid'}
      # should raise error: select a group
      assert_response 400
    end

    should 'and one is selected' do
      post_as @admin, :global_actions, {assignment_id: @assignment.id,
        global_actions: 'valid', groupings: [@grouping.id]}
      assert_response :success
    end

    context 'group creation with grace days deduction, All members' do

      setup do
        @student1 =  Student.make
        @student2 =  Student.make
        @student3 =  Student.make
      end

      should 'be deducted 0 grace days' do
        # create group with 2 members
        post_add [@student1.id, @student2.id]
        # Add 0 deductions to each member
        @grouping.accepted_student_memberships.each do |student_membership|
          # Remove all old deduction created by post_add
          deductions = student_membership.user.grace_period_deductions
          deductions.each do |deduction|
            student_membership.grace_period_deductions.delete(deduction)
            deduction.destroy
          end
          deduction = GracePeriodDeduction.new
          deduction.membership = student_membership
          deduction.deduction = 0
          deduction.save
        end

        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          # each member still has 5 grace credits out of 5
          assert_equal 5, student_membership.user.remaining_grace_credits
        end

        # add an additional member to the group
        @grouping.add_member(@student3)

        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          # all members still have 5 grace credits out of 5 including newly added member
          assert_equal 5, student_membership.user.remaining_grace_credits
        end
      end

      should 'be deducted 1 grace days' do
        # create group with 1 members
        post_add [@student1.id]
        # Add 1 deductions to each member
        @grouping.accepted_student_memberships.each do |student_membership|
          # Remove all old deduction created by post_add
          deductions = student_membership.user.grace_period_deductions
          deductions.each do |deduction|
            student_membership.grace_period_deductions.delete(deduction)
            deduction.destroy
          end
          deduction = GracePeriodDeduction.new
          deduction.membership = student_membership
          deduction.deduction = 1
          deduction.save
        end

        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          # each member has 4 grace credits out of 5
          assert_equal 4, student_membership.user.remaining_grace_credits
        end

        @grouping.add_member(@student2)

        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          # each members has 4 grace credits out of 5 including newly added member
          assert_equal 4, student_membership.user.remaining_grace_credits
        end

        @grouping.add_member(@student3)

        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          # each members has 4 grace credits out of 5 including newly added member
          assert_equal 4, student_membership.user.remaining_grace_credits
        end
      end

      should 'be deducted 2 grace days' do
        # create group with 2 members
        post_add [@student1.id, @student2.id]
        # Add 2 deductions to each member
        @grouping.accepted_student_memberships.each do |student_membership|
          # Remove all old deduction created by post_add
          deductions = student_membership.user.grace_period_deductions
          deductions.each do |deduction|
            student_membership.grace_period_deductions.delete(deduction)
            deduction.destroy
          end
          deduction = GracePeriodDeduction.new
          deduction.membership = student_membership
          deduction.deduction = 2
          deduction.save
        end

        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          # each members has 3 grace credits out of 5
          assert_equal 3, student_membership.user.remaining_grace_credits
        end

        @grouping.add_member(@student3)

        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          # each members has 3 grace credits out of 5 including newly added member
          assert_equal 3, student_membership.user.remaining_grace_credits
        end
      end

    end

    context 'POST on :global_actions on assign' do

      setup do
        @assignment = Assignment.make
        @admin = Admin.make
      end

      should 'and no group selected' do
        @student =  Student.make
        post_as @admin, :global_actions, {assignment_id: @assignment.id,
          global_actions: 'assign', students: [@student.id]}
        assert_response 400
      end

      should 'and no students selected' do
        @grouping = Grouping.make
        post_as @admin, :global_actions, {assignment_id: @assignment.id,
          global_actions: 'assign', groupings: [@grouping.id]}
        assert_equal 0, @grouping.student_memberships.size
        assert_response 400
      end

      should 'with a single student not in a group' do
        @student =  Student.make
        @grouping = Grouping.make
        post_add [@student.id]
        assert_response :success
        assert_equal 1, @grouping.student_memberships.size
        assert_equal 'inviter',
                      @grouping.student_memberships.at(0).membership_status
        assert_equal @student.id, @grouping.student_memberships.at(0).user_id
      end

      should 'with a single user who is already grouped on this assignment' do
        @student =  Student.make
        @grouping = Grouping.make
        @grouping.add_member(@student)
        post_add [@student.id]
        # should also assert error: student already grouped
        assert_response 400
        assert_equal 1, @grouping.student_memberships.size
      end

      should 'with two valid users' do
        @student1 =  Student.make
        @student2 =  Student.make
        @grouping = Grouping.make
        post_add [@student1.id, @student2.id]
        assert_response :success
        assert_equal 2,
                     @grouping.student_memberships.size
        assert_equal 'inviter',
                     @grouping.student_memberships.at(0).membership_status
        assert_equal 'accepted',
                     @grouping.student_memberships.at(1).membership_status
        students_id = [@student1.id, @student2.id]
        student_memberships_id = [@grouping.student_memberships.at(0).user_id,
                                  @grouping.student_memberships.at(1).user_id]
        assert_same_elements(students_id, student_memberships_id)
      end

      should 'with two valid users, with assignment past collection date' do
        # stub collection date
        Assignment.any_instance.stubs(:past_collection_date?).returns(true)
        @student1 =  Student.make
        @student2 =  Student.make
        @grouping = Grouping.make
        post_add [@student1, @student2]
        assert_response :success
        assert_equal 2, @grouping.student_memberships.size
        assert_equal 'inviter',
                     @grouping.student_memberships.at(0).membership_status
        assert_equal 'accepted',
                     @grouping.student_memberships.at(1).membership_status
        students_id = [@student1.id, @student2.id]
        student_memberships_id = [@grouping.student_memberships.at(0).user_id,
                                  @grouping.student_memberships.at(1).user_id]
        assert_same_elements(students_id, student_memberships_id)
      end

      should 'be able to add members' do
        @student1 =  Student.make
        @student2 =  Student.make
        @grouping = Grouping.make(assignment: @assignment)
        @grouping.add_member(@student1)
        post_add [@student2]

        # check for error: student already assigned
        assert_response :success
        assert_equal 2, @grouping.student_memberships.size
        assert_equal 'accepted',
                     @grouping.student_memberships.at(0).membership_status
        assert_equal 'accepted',
                     @grouping.student_memberships.at(1).membership_status
        students_id = [@student1.id, @student2.id]
        student_memberships_id = [@grouping.student_memberships.at(0).user_id,
                                  @grouping.student_memberships.at(1).user_id]
        assert_same_elements(students_id, student_memberships_id)
      end

      should 'with 1 valid user, 1 already assigned user' do
        @student1 =  Student.make
        @student2 =  Student.make
        @grouping = Grouping.make(assignment: @assignment)
        @grouping2 = Grouping.make(assignment: @assignment)
        @grouping2.add_member(@student2)
        post_add [@student1, @student2]
        # should also get error message we return is 'student already assigned'
        assert_response 400
        assert_equal 1, @grouping.student_memberships.size
        assert_equal 'inviter', @grouping.student_memberships.at(0).membership_status
        assert_equal @student1.id, @grouping.student_memberships.at(0).user_id
      end

      should 'with three valid users' do
        @student1 =  Student.make
        @student2 =  Student.make
        @student3 =  Student.make
        @grouping = Grouping.make
        post_add [@student1.id, @student2.id, @student3.id]
        assert_response :success
        assert_equal 3, @grouping.student_memberships.size
        assert_equal 'inviter',
                     @grouping.student_memberships.at(0).membership_status
        assert_equal 'accepted',
                     @grouping.student_memberships.at(1).membership_status
        assert_equal 'accepted',
                     @grouping.student_memberships.at(2).membership_status
        students_id = [@student1.id, @student2.id, @student3.id]
        student_memberships_id = [@grouping.student_memberships.at(0).user_id,
                                  @grouping.student_memberships.at(1).user_id,
                                  @grouping.student_memberships.at(2).user_id]
        assert_same_elements(students_id, student_memberships_id)
      end

      should 'with valid,valid,invalid users' do
        @student1 =  Student.make
        @student2 =  Student.make
        @student3 =  Student.make
        @grouping = Grouping.make(assignment: @assignment)
        @grouping2 = Grouping.make(assignment: @assignment)
        @grouping2.add_member(@student3)
        post_add [@student1.id, @student2.id, @student3.id]
        # should return error: already assigned
        assert_response 400
        assert_equal 2, @grouping.student_memberships.size
        assert_equal 'inviter',
                     @grouping.student_memberships.at(0).membership_status
        assert_equal 'accepted',
                     @grouping.student_memberships.at(1).membership_status
        students_id = [@student1.id, @student2.id]
        student_memberships_id = [@grouping.student_memberships.at(0).user_id,
                                  @grouping.student_memberships.at(1).user_id]
        assert_same_elements(students_id, student_memberships_id)
      end

    end #POST on global_actions on assign

    context 'with a grouping' do
      setup do
        @assignment = Assignment.make
        @admin = Admin.make
      end

      should 'be able to unassign a member' do
        @student1 = Student.make
        @student2 = Student.make
        @grouping = Grouping.make(assignment: @assignment)
        @grouping.add_member(@student1)
        @grouping.add_member(@student2)
        post_as @admin, :global_actions, {
          assignment_id: @assignment.id,
          global_actions: 'unassign',
          students_to_remove: [@student1.id]}
        assert_response :success
        @grouping.reload
        assert_equal 1, @grouping.student_memberships.size
      end

      should 'be able to unassign all group members' do
        @student1 = Student.make
        @student2 = Student.make
        @grouping = Grouping.make(assignment: @assignment)
        @grouping.add_member(@student1)
        @grouping.add_member(@student2)
        post_as @admin, :global_actions, {
          assignment_id: @assignment.id,
          global_actions: 'unassign',
          students_to_remove: [@student1.id, @student2.id]}
        assert_response :success
        @grouping.reload
        assert_equal 0, @grouping.student_memberships.size
      end
    end #POST on global_actions on unassign


    context 'GET on download_grouplist' do
      setup do
        @assignment = Assignment.make
      end

      context 'with no groups' do
        setup do
          @assignment.groupings.destroy_all
          @response = get_as @admin, :download_grouplist, {assignment_id: @assignment.id}
        end
        should respond_with :success
        should 'be an empty file returned' do
          assert @response.body.empty?
        end
        should 'route properly' do
          assert_recognizes({controller: 'groups', assignment_id: '1', action: 'download_grouplist' },
            {path: 'assignments/1/groups/download_grouplist', method: :get})
        end
      end # with no groups

      context 'with groups, but no TAs assigned' do
        setup do
          # Construct the array that a parse of the returned CSV
          # *should* return
          @assignment = Assignment.make(groupings: [Grouping.make])
          @match_array = construct_group_list_array(@assignment.groupings)
          @response = get_as @admin, :download_grouplist, {assignment_id: @assignment.id}
        end
        should respond_with :success
        should 'not be an empty file returned' do
          assert !@response.body.empty?
        end
        should 'return the expected CSV' do
          assert_equal @match_array, CSV.parse(@response.body)
        end
        should 'route properly' do
          assert_recognizes({controller: 'groups', assignment_id: '1', action: 'download_grouplist' },
            {path: 'assignments/1/groups/download_grouplist', method: :get})
        end
      end # with groups, but no TAs assigned

      context 'with groups, with TAs assigned' do
        setup do
          @assignment = Assignment.make(groupings: [Grouping.make])
          @ta1 = Ta.make
          @ta2 = Ta.make
          # For each grouping for Assignment 1, assign 2 TAs
          @assignment.groupings.each do |grouping|
            grouping.add_tas_by_user_name_array([@ta1.user_name, @ta2.user_name])
          end
          @assignment.groupings.reload
          @match_array = construct_group_list_array(@assignment.groupings)
          @response = get_as @admin, :download_grouplist, {assignment_id: @assignment.id}
        end
        should respond_with :success
        should 'not be an empty file returned' do
          assert !@response.body.empty?
        end
        should 'return the expected CSV, without TAs included' do
          assert_equal @match_array, CSV.parse(@response.body)
        end
        should 'route properly' do
          assert_recognizes({controller: 'groups', assignment_id: '1', action: 'download_grouplist' },
            {path: 'assignments/1/groups/download_grouplist', method: :get})
        end

      end # with groups, with TAs assigned

    end

  end #admin context

  def post_add(students)
    post_as @admin, :global_actions, {assignment_id: @assignment.id,
      global_actions: 'assign',
      groupings: [@grouping.id], students: students}
  end

  def construct_group_list_array(groupings)
    match_array = Array.new
    groupings.each do |grouping|
      grouping_array = Array.new
      grouping_array.push(grouping.group.group_name)
      grouping_array.push(grouping.group.repo_name)
      grouping.student_memberships.each do |student_membership|
        grouping_array.push(student_membership.user.user_name)
      end
      match_array.push(grouping_array)
    end
    return match_array
  end


end
