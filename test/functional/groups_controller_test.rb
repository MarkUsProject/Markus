require File.dirname(__FILE__) + '/authenticated_controller_test'

require 'shoulda'

class GroupsControllerTest < AuthenticatedControllerTest
  
  context "An authenticated and authorized student doing a " do
    fixtures :users
    
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
        setup_group_fixture_repos
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
          post_as @admin, :global_actions, {:id => @assignment.id, :global_actions => "delete", :groupings => [groupings(:grouping_1).id, groupings(:grouping_2).id]}
        end
        should_assign_to :assignment, :tas
        should "assign @removed_groupings accordingly" do
          assert_same_elements [groupings(:grouping_1), groupings(:grouping_2)], assigns(:removed_groupings)
        end
        should_assign_to(:errors) { [] }
        should_render_template 'delete_groupings.rjs'
      end
      
    end

end
