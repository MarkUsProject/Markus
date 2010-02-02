require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'
require 'fastercsv'

class GroupsControllerTest < AuthenticatedControllerTest
  
  context "An authenticated and authorized student doing a " do
    fixtures :groupings, :users, :assignments
    
    setup do
      @student = users(:student1)
    end
    
    context "GET on :add_member" do
      setup do
        get_as @student, :add_member
      end
      should_respond_with :missing
    end
    
    context "GET on :remove_member" do
      setup do
        get_as @student, :remove_member
      end
      should_respond_with :missing
    end
    
    context "GET on :add_group" do
      setup do
        get_as @student, :add_group
      end
      should_respond_with :missing
    end
    
    context "GET on :remove_group" do
      setup do
        get_as @student, :remove_group
      end
      should_respond_with :missing
    end
    
    context "GET on :rename_group" do
      setup do
        get_as @student, :rename_group
      end
      should_respond_with :missing
    end
    
    context "GET on :valid_grouping" do
      setup do
        get_as @student, :valid_grouping
      end
      should_respond_with :missing
    end
    
    context "GET on :manage" do
      setup do
        get_as @student, :manage
      end
      should_respond_with :missing
    end
    
    context "GET on :csv_upload" do
      setup do
        get_as @student, :csv_upload
      end
      should_respond_with :missing
    end
    
    context "GET on :add_csv_group" do
      setup do
        get_as @student, :add_csv_group
      end
      should_respond_with :missing
    end
    
    context "GET on :download_grouplist" do
      setup do
        get_as @student, :download_grouplist
      end
      should_respond_with :missing
    end
    
    context "GET on :use_another_assignment_groups" do
      setup do
        get_as @student, :use_another_assignment_groups
      end
      should_respond_with :missing
    end
    
    context "GET on :create_groups_when_students_work_alone" do
      setup do
        get_as @student, :create_groups_when_students_work_alone
      end
      should_respond_with :missing
    end
  end #student context
  
  context "An authenticated and authorized admin doing a " do
    fixtures :users, :assignments, :groupings, :groups, :memberships
    
    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:assignment_1)
      @grouping = groupings(:grouping_4)
      setup_group_fixture_repos
    end
    
    context "GET on :manage" do
      setup do
        get_as @admin, :manage, {:id => @assignment.id}
      end
      should_respond_with :success
    end
    
    context "DELETE on :remove_member" do
      
      setup do
        @grouping = groupings(:grouping_1)
      end
      
      context "on member" do
        setup do
          membership = memberships(:membership2)
          delete_as @admin, :remove_member, {:id => @assignment.id, :grouping_id  => @grouping.id, :mbr_id => membership.id}
        end
        should_respond_with :success
        should_render_template 'remove_member.rjs'
        should_assign_to :mbr_id, :assignment, :grouping
        should_assign_to(:inviter) { false  }
      end
      
      context "on inviter" do
        setup do
          membership = memberships(:membership1)
          delete_as @admin, :remove_member, {:id => @assignment.id, :grouping_id  => @grouping.id, :mbr_id => membership.id}
        end
        should_respond_with :success
        should_render_template 'remove_member.rjs'
        should_assign_to :mbr_id, :assignment, :grouping
        should "assign @inviter accordingly" do
          assert_nil assigns(:inviter)
        end
      end
      
    end #:remove_member
    
    context "POST on :add_group" do
      
      context "without groupname" do
        setup do
          post_as @admin, :add_group, {:id => @assignment.id}
        end
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should_assign_to(:assignment) { @assignment }
        should_assign_to :new_grouping
      end
      
      context "with groupname" do
        setup do
          post_as @admin, :add_group, {:id => @assignment.id, :new_group_name => "test"}
        end
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should_assign_to(:assignment) { @assignment }
        should_assign_to :new_grouping
      end
    end #:add_group
    
    context "DELETE on :remove_group" do
      
      context "on group without a submission" do
        setup do
          delete_as @admin, :remove_group, {:grouping_id => @grouping.id}
        end
        should_respond_with :success
        should_render_template 'delete_groupings.rjs'
        should_assign_to(:assignment) { @assignment }
        should_assign_to(:errors) { [] }
        should_assign_to(:removed_groupings) { [@grouping] }
      end
      
      context "on group with a submission" do
        setup do
          @grouping_with_submission = groupings(:grouping2)
          delete_as @admin, :remove_group, {:grouping_id => @grouping_with_submission.id}
        end
        should_respond_with :success
        should_render_template 'delete_groupings.rjs'
        should_assign_to(:assignment) { assignments(:assignment_2) }
        should_assign_to(:errors) { [@grouping_with_submission.group.group_name] }
        should_assign_to(:removed_groupings) { [] }
      end
      
    end #:remove_group
    
    context "POST on :rename_group" do
      
      context "with unique, new name" do
        setup do
          @new_name = "NeW"
          post_as @admin, :rename_group, {:id => @assignment.id, :grouping_id => @grouping.id, :new_groupname => @new_name}
        end
        should_assign_to :assignment, :grouping, :group
        should "set group name accordingly" do
          assert_equal @new_name, assigns(:group).group_name
        end
        should_respond_with :success
        should_set_the_flash_to I18n.t('groups.rename_group.success')
        should_render_template 'rename_group.rjs'
      end
      
      context "with existing name" do
        setup do
          @new_name = groups(:group_3).group_name
          post_as @admin, :rename_group, {:id => @assignment.id, :grouping_id => @grouping.id, :new_groupname => @new_name}
        end
        should_assign_to :assignment, :grouping, :group
        should_respond_with :success
        should "not change group name" do
          assert_equal @grouping.group.group_name, assigns(:group).group_name
        end
        should_set_the_flash_to I18n.t('groups.rename_group.already_in_use')
        should_render_template 'rename_group.rjs'
      end
      
    end #:rename_group
    
    context "POST on :valid_grouping" do
      setup do
        post_as @admin, :valid_grouping, {:id => @assignment.id, :grouping_id => @grouping.id}
      end
      should_assign_to :assignment
      should_respond_with :success
      should_render_template 'valid_grouping.rjs'
    end
    
    context "POST on :use_another_assignment_groups" do
      setup do
        target_assignment = assignments(:assignment_3)
        post_as @admin, :use_another_assignment_groups, {:id => target_assignment.id, :clone_groups_assignment_id => @assignment.id}
      end
      
      teardown do
        destroy_repos
      end
      
      should_assign_to :target_assignment
      should_respond_with :success
      should_set_the_flash_to "Groups created"
      should_render_template 'use_another_assignment_groups.rjs'
    end
    
    context "POST on :global_actions on delete" do
      
      context "and none selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id, :global_actions => "delete"}
        end
        should_assign_to :assignment, :tas
        should_render_template 'error_single.rjs'
        should_assign_to(:error) { "You need to select at least one group." }
      end
      
      context "and one is selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id, :global_actions => "delete", :groupings => [groupings(:grouping_1).id]}
        end
        should_assign_to :assignment, :tas
        should "assign @removed_groupings accordingly" do
          assert_same_elements [groupings(:grouping_1)], assigns(:removed_groupings)
        end
        should_assign_to(:errors) { [] }
        should_render_template 'delete_groupings.rjs'
      end
      
    end
    
    context "POST on :global_actions on random_assign" do
      setup do
          # Remove TAs from all groupings used...
          groupings(:grouping_2).remove_ta_by_id(users(:ta1).id)
          groupings(:grouping_5).remove_ta_by_id(users(:ta3).id)
          groupings(:grouping_6).remove_ta_by_id(users(:ta3).id)
      end
      
      context "and no graders selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id, :global_actions => "", :submit_type => "random_assign"}
        end
        should_assign_to(:error) { I18n.t( 'groups.no_graders_selected') }
      end
      
      context "and no groups selected, at least one grader" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id, :global_actions => "", :submit_type => "random_assign", :graders => [users(:ta1).id]}
        end
        should_assign_to(:error) { I18n.t( 'groups.no_groups_selected') }
      end
      
      context "and one grader and one group is selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id, :global_actions => "", :submit_type => "random_assign", :groupings => [groupings(:grouping_1).id], :graders => [users(:ta1).id]}
        end
        should "assign grader to group accordingly" do
          assert_same_elements groupings(:grouping_1).get_ta_names, [users(:ta1).user_name]
        end
        should "not assign that grader to non selected groups" do
          assert_same_elements groupings(:grouping_2).get_ta_names, []
          assert_same_elements groupings(:grouping_3).get_ta_names, []
          assert_same_elements groupings(:grouping_4).get_ta_names, []
          assert_same_elements groupings(:grouping_5).get_ta_names, []
          assert_same_elements groupings(:grouping_6).get_ta_names, []
        end
      end
      
      context "and one grader and multiple groups are selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id, :global_actions => "", :submit_type => "random_assign", :groupings => [groupings(:grouping_1).id,groupings(:grouping_2).id,groupings(:grouping_3).id], :graders => [users(:ta1).id]}
        end
        should "assign that grader to all groups accordingly" do
          assert_same_elements groupings(:grouping_1).get_ta_names, [users(:ta1).user_name]
          assert_same_elements groupings(:grouping_2).get_ta_names, [users(:ta1).user_name]
          assert_same_elements groupings(:grouping_3).get_ta_names, [users(:ta1).user_name]
        end
        should "not assign that grader to non selected groups" do
          assert_same_elements groupings(:grouping_4).get_ta_names, []
          assert_same_elements groupings(:grouping_5).get_ta_names, []
          assert_same_elements groupings(:grouping_6).get_ta_names, []
        end
      end
      
      context "and two graders and one group is selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id, :global_actions => "", :submit_type => "random_assign", :groupings => [groupings(:grouping_3).id], :graders => [users(:ta1).id,users(:ta2).id]}
        end
        should "assign one grader to selected group" do
          # Getting count as graders are assigned randomly. Should only have one grader.
          assert_equal groupings(:grouping_3).get_ta_names.size, 1
        end
        should "not assign that grader to non-selected groups" do
          assert_same_elements groupings(:grouping_1).get_ta_names, []
          assert_same_elements groupings(:grouping_2).get_ta_names, []
          assert_same_elements groupings(:grouping_4).get_ta_names, []
          assert_same_elements groupings(:grouping_5).get_ta_names, []
          assert_same_elements groupings(:grouping_6).get_ta_names, []
        end
      end
      
      context "and two graders and multiple groups are selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id, :global_actions => "", :submit_type => "random_assign", :groupings => [groupings(:grouping_2).id,groupings(:grouping_4).id,groupings(:grouping_5).id], :graders => [users(:ta1).id,users(:ta2).id]}
        end
        should "assign one grader to each selected group" do
          # Getting count as graders are assigned randomly. Should only have one grader each.
          assert_equal groupings(:grouping_2).get_ta_names.size, 1
          assert_equal groupings(:grouping_4).get_ta_names.size, 1
          assert_equal groupings(:grouping_5).get_ta_names.size, 1
        end
        should "not assign that grader to non-selected groups" do
          assert_same_elements groupings(:grouping_1).get_ta_names, []
          assert_same_elements groupings(:grouping_3).get_ta_names, []
          assert_same_elements groupings(:grouping_6).get_ta_names, []
        end
      end
      
      context "and multiple graders and multiple groups are selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id, :global_actions => "", :submit_type => "random_assign", :groupings => [groupings(:grouping_1).id,groupings(:grouping_2).id,groupings(:grouping_4).id,groupings(:grouping_5).id,groupings(:grouping_6).id], :graders => [users(:ta1).id,users(:ta2).id,users(:ta2).id]}
        end
        should "assign one grader to each selected group" do
          # Getting count as graders are assigned randomly. Should only have one grader each.
          assert_equal groupings(:grouping_1).get_ta_names.size, 1
          assert_equal groupings(:grouping_2).get_ta_names.size, 1
          assert_equal groupings(:grouping_4).get_ta_names.size, 1
          assert_equal groupings(:grouping_5).get_ta_names.size, 1
          assert_equal groupings(:grouping_6).get_ta_names.size, 1
        end
        should "not assign graders to non selected groups" do
          assert_same_elements groupings(:grouping_3).get_ta_names, []
        end
      end
      
    end
    
    context "POST on :add_member" do
      
      context "with an empty username field" do
        setup do
          post_add ''
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) { [] }
        should_assign_to(:bad_user_names) { [] }
        should_assign_to(:error) { false }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "not change number of members" do
          assert_equal 0, @grouping.student_memberships.size
        end
      end
      
      context "with a single user not in a group" do
        setup do
          @user_name = users(:student6).user_name
          post_add @user_name
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) { [ I18n.t('add_student.success', :user_name => @user_name) ] }
        should_assign_to(:bad_user_names) { [] }
        should_assign_to(:error) { false }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 1" do
          assert_equal 1, @grouping.student_memberships.size
        end
        should "set new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal users(:student6).id, @grouping.student_memberships.at(0).user_id
        end
      end
      
      context "with a single invalid username" do
        setup do
          @user_name = users(:student6).user_name + "asjfdlskjslkfds"
          post_add @user_name
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) { [ I18n.t('add_student.fail.dne', :user_name => @user_name) ] }
        should_assign_to(:bad_user_names) { [ @user_name ] }
        should_assign_to(:error) { true }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "not change number of members" do
          assert_equal 0, @grouping.student_memberships.size
        end
      end
      
      context "with a single user who is hidden" do
        setup do
          @user_name = users(:hidden_student).user_name
          post_add @user_name
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) { [ I18n.t('add_student.fail.hidden', :user_name => @user_name) ] }
        should_assign_to(:bad_user_names) { [ @user_name ] }
        should_assign_to(:error) { true }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "not change number of members" do
          assert_equal 0, @grouping.student_memberships.size
        end
      end
      
      context "with a single user who is already grouped on this assignment" do
        setup do
          @user_name = users(:student1).user_name
          post_add @user_name
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) { [ I18n.t('add_student.fail.already_grouped', :user_name => @user_name) ] }
        should_assign_to(:bad_user_names) { [ @user_name ] }
        should_assign_to(:error) { true }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "not change number of members" do
          assert_equal 0, @grouping.student_memberships.size
        end
      end
      
      context "with two valid users" do
        setup do
          @user_names = [users(:student6).user_name, users(:student7).user_name]
          post_add @user_names.join(',')
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) {
          [
            I18n.t('add_student.success', :user_name => @user_names.at(0)),
            I18n.t('add_student.success', :user_name => @user_names.at(1))
          ]
        }
        should_assign_to(:bad_user_names) { [] }
        should_assign_to(:error) { false }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 2" do
          assert_equal 2, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal users(:student6).id, @grouping.student_memberships.at(0).user_id
        end
        should "set second new student as accepted" do
          assert_equal "accepted", @grouping.student_memberships.at(1).membership_status
          assert_equal users(:student7).id, @grouping.student_memberships.at(1).user_id
        end
      end
      
      context "with two invalid users" do
        setup do
          @user_names = [users(:student6).user_name + "Fjdksljfkl", users(:student1).user_name]
          post_add @user_names.join(',')
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) {
          [
            I18n.t('add_student.fail.dne', :user_name => @user_names.at(0)),
            I18n.t('add_student.fail.already_grouped', :user_name => @user_names.at(1))
          ]
        }
        should_assign_to(:bad_user_names) { @user_names }
        should_assign_to(:error) { true }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "not change number of members" do
          assert_equal 0, @grouping.student_memberships.size
        end
      end
      
      context "with valid,invalid users" do
        setup do
          @user_names = [users(:student6).user_name, users(:student1).user_name]
          post_add @user_names.join(',')
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) {
          [
            I18n.t('add_student.success', :user_name => @user_names.at(0)),
            I18n.t('add_student.fail.already_grouped', :user_name => @user_names.at(1))
          ]
        }
        should_assign_to(:bad_user_names) { [ @user_names.at(1) ] }
        should_assign_to(:error) { true }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 1" do
          assert_equal 1, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal users(:student6).id, @grouping.student_memberships.at(0).user_id
        end
      end
      
      context "with invalid,valid users" do
        setup do
          @user_names = [users(:student1).user_name, users(:student6).user_name]
          post_add @user_names.join(',')
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped', :user_name => @user_names.at(0)),
            I18n.t('add_student.success', :user_name => @user_names.at(1))
          ]
        }
        should_assign_to(:bad_user_names) { [ @user_names.at(0) ] }
        should_assign_to(:error) { true }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 1" do
          assert_equal 1, @grouping.student_memberships.size
        end
        should "set second new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal users(:student6).id, @grouping.student_memberships.at(0).user_id
        end
      end
      
      context "with three valid users" do
        setup do
          @user_names = [users(:student6).user_name, users(:student7).user_name, users(:student8).user_name]
          post_add @user_names.join(',')
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) {
          [
            I18n.t('add_student.success', :user_name => @user_names.at(0)),
            I18n.t('add_student.success', :user_name => @user_names.at(1)),
            I18n.t('add_student.success', :user_name => @user_names.at(2))
          ]
        }
        should_assign_to(:bad_user_names) { [] }
        should_assign_to(:error) { false }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 3" do
          assert_equal 3, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal users(:student6).id, @grouping.student_memberships.at(0).user_id
        end
        should "set other students as accepted" do
          assert_equal "accepted", @grouping.student_memberships.at(1).membership_status
          assert_equal "accepted", @grouping.student_memberships.at(2).membership_status
        end
      end
      
      context "with three invalid users" do
        setup do
          @user_names = [users(:student6).user_name + "Fjdksljfkl", users(:student1).user_name, users(:hidden_student).user_name]
          post_add @user_names.join(',')
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) {
          [
            I18n.t('add_student.fail.dne', :user_name => @user_names.at(0)),
            I18n.t('add_student.fail.already_grouped', :user_name => @user_names.at(1)),
            I18n.t('add_student.fail.hidden', :user_name => @user_names.at(2))
          ]
        }
        should_assign_to(:bad_user_names) { @user_names }
        should_assign_to(:error) { true }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "not change number of members" do
          assert_equal 0, @grouping.student_memberships.size
        end
      end
      
      context "with valid,valid,invalid users" do
        setup do
          @user_names = [users(:student6).user_name, users(:student7).user_name, users(:student1).user_name]
          post_add @user_names.join(',')
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) {
          [
            I18n.t('add_student.success', :user_name => @user_names.at(0)),
            I18n.t('add_student.success', :user_name => @user_names.at(1)),
            I18n.t('add_student.fail.already_grouped', :user_name => @user_names.at(2))
          ]
        }
        should_assign_to(:bad_user_names) { [ @user_names.at(2) ] }
        should_assign_to(:error) { true }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 2" do
          assert_equal 2, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal users(:student6).id, @grouping.student_memberships.at(0).user_id
        end
        should "set second new student as accepted" do
          assert_equal "accepted", @grouping.student_memberships.at(1).membership_status
          assert_equal users(:student7).id, @grouping.student_memberships.at(1).user_id
        end
      end
      
      context "with valid,invalid,valid users" do
        setup do
          @user_names = [users(:student6).user_name, users(:student1).user_name, users(:student7).user_name]
          post_add @user_names.join(',')
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) {
          [
            I18n.t('add_student.success', :user_name => @user_names.at(0)),
            I18n.t('add_student.fail.already_grouped', :user_name => @user_names.at(1)),
            I18n.t('add_student.success', :user_name => @user_names.at(2))
          ]
        }
        should_assign_to(:bad_user_names) { [ @user_names.at(1) ] }
        should_assign_to(:error) { true }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 2" do
          assert_equal 2, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal users(:student6).id, @grouping.student_memberships.at(0).user_id
        end
        should "set third new student as accepted" do
          assert_equal "accepted", @grouping.student_memberships.at(1).membership_status
          assert_equal users(:student7).id, @grouping.student_memberships.at(1).user_id
        end
      end
      
      context "with invalid,valid,valid users" do
        setup do
          @user_names = [users(:student1).user_name, users(:student6).user_name, users(:student7).user_name]
          post_add @user_names.join(',')
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped', :user_name => @user_names.at(0)),
            I18n.t('add_student.success', :user_name => @user_names.at(1)),
            I18n.t('add_student.success', :user_name => @user_names.at(2))
          ]
        }
        should_assign_to(:bad_user_names) { [ @user_names.at(0) ] }
        should_assign_to(:error) { true }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 2" do
          assert_equal 2, @grouping.student_memberships.size
        end
        should "set second new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal users(:student6).id, @grouping.student_memberships.at(0).user_id
        end
        should "set third new student as accepted" do
          assert_equal "accepted", @grouping.student_memberships.at(1).membership_status
          assert_equal users(:student7).id, @grouping.student_memberships.at(1).user_id
        end
      end
      
      context "with valid,invalid,invalid users" do
        setup do
          @user_names = [users(:student6).user_name, users(:student7).user_name + "fdjsl", users(:student1).user_name]
          post_add @user_names.join(',')
        end
        should_assign_to :assignment, :grouping, :group_name
        should_assign_to(:messages) {
          [
            I18n.t('add_student.success', :user_name => @user_names.at(0)),
            I18n.t('add_student.fail.dne', :user_name => @user_names.at(1)),
            I18n.t('add_student.fail.already_grouped', :user_name => @user_names.at(2))
          ]
        }
        should_assign_to(:bad_user_names) { @user_names[1,2] }
        should_assign_to(:error) { true }
        should_respond_with :success
        should_render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by " do
          assert_equal 1, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal users(:student6).id, @grouping.student_memberships.at(0).user_id
        end
      end
      
    end #:add_member
    
    context "GET on download_grouplist" do
      setup do
        setup_group_fixture_repos
        @assignment = assignments(:assignment_1)
      end
      
      context "with no groups" do
        setup do
          @assignment.groupings.destroy_all
          @response = get_as @admin, :download_grouplist, {:id => @assignment.id}
        end
        should_respond_with :success
        should "be an empty file returned" do
          assert @response.body.empty?
        end
      end # with no groups
      
      context "with groups, but no TAs assigned" do
        setup do
          # Construct the array that a parse of the returned CSV
          # *should* return
          @match_array = construct_group_list_array(@assignment.groupings)
          @response = get_as @admin, :download_grouplist, {:id => @assignment.id}
        end
        should_respond_with :success
        should "not be an empty file returned" do
          assert !@response.body.empty?
        end
        should "return the expected CSV" do
          assert_equal @match_array, FasterCSV.parse(@response.body)
        end
      end # with groups, but no TAs assigned
      
      context "with groups, with TAs assigned" do
        setup do
          @ta1 = users(:ta1)
          @ta2 = users(:ta2)
          # For each grouping for Assignment 1, assign 2 TAs
          @assignment.groupings.each do |grouping|
            grouping.add_tas_by_user_name_array([@ta1.user_name, @ta2.user_name])
          end
          @assignment.groupings.reload
          @match_array = construct_group_list_array(@assignment.groupings)
          @response = get_as @admin, :download_grouplist, {:id => @assignment.id}
        end
        should_respond_with :success
        should "not be an empty file returned" do
          assert !@response.body.empty?
        end
        should "return the expected CSV, without TAs included" do
          assert_equal @match_array, FasterCSV.parse(@response.body)
        end
      end # with groups, with TAs assigned

    end
  end #admin context
  
  def post_add(user_name)
    post_as @admin, :add_member, {:id => @assignment.id, :grouping_id => @grouping.id, :student_user_name => user_name}
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
