require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'
require 'mocha'
require 'fastercsv'

class GroupsControllerTest < AuthenticatedControllerTest

  def setup
    clear_fixtures
  end

  context "An authenticated and authorized student doing a " do
    
    setup do
      @student = Student.make
      @assignment = Assignment.make
    end
    
    context "GET on :add_group" do
      setup do
        get_as @student, :add_group
      end
      should respond_with :missing
    end
    
    context "GET on :remove_group" do
      setup do
        get_as @student, :remove_group
      end
      should respond_with :missing
    end
    
    context "GET on :rename_group" do
      setup do
        get_as @student, :rename_group
      end
      should respond_with :missing
    end
    
    context "GET on :valid_grouping" do
      setup do
        get_as @student, :valid_grouping
      end
      should respond_with :missing
    end

    context "GET on :invalid_grouping" do
      setup do
        get_as @student, :invalid_grouping
      end
      should respond_with :missing
    end
    
    context "GET on :manage" do
      setup do
        get_as @student, :manage
      end
      should respond_with :missing
    end
    
    context "GET on :csv_upload" do
      setup do
        get_as @student, :csv_upload
      end
      should respond_with :missing
    end
    
    context "GET on :add_csv_group" do
      setup do
        get_as @student, :add_csv_group
      end
      should respond_with :missing
    end
    
    context "GET on :download_grouplist" do
      setup do
        get_as @student, :download_grouplist
      end
      should respond_with :missing
    end
    
    context "GET on :use_another_assignment_groups" do
      setup do
        get_as @student, :use_another_assignment_groups
      end
      should respond_with :missing
    end
    
    context "GET on :create_groups_when_students_work_alone" do
      setup do
        get_as @student, :create_groups_when_students_work_alone
      end
      should respond_with :missing
    end
  end #student context
  
  context "An authenticated and authorized admin doing a " do
    
    setup do
      @admin = Admin.make
      @grouping = Grouping.make
      @assignment = Assignment.make(:groupings => [@grouping])
      setup_group_fixture_repos
    end
    
    context "GET on :manage" do
      setup do
        get_as @admin, :manage, {:id => @assignment.id}
      end
      should respond_with :success
    end

    context "GET on :populate" do
      setup do
        get_as @admin, :populate, {:id => @assignment.id}
      end
      should respond_with :success
    end

    context "GET on :populate_students" do
      setup do
        get_as @admin, :populate_students, {:id => @assignment.id}
      end
      should respond_with :success
    end

    context "GET on :manage" do
      setup do
        get_as @admin, :manage, {:id => @assignment.id}
      end
      should respond_with :success
    end
    
    context "POST on :add_group" do
      
      context "without groupname" do
        setup do
          @assignment = Assignment.make
          Assignment.any_instance.stubs(:add_group).returns(Grouping.make)
          post_as @admin, :add_group, {:id => @assignment.id}
        end
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should assign_to(:assignment) { @assignment }
        should assign_to :new_grouping
      end
      
      context "with groupname" do
        setup do
          post_as @admin, :add_group, {:id => @assignment.id, :new_group_name => "test"}
        end
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should assign_to(:assignment) { @assignment }
        should assign_to :new_grouping
      end
    end #:add_group
    
    context "DELETE on :remove_group" do
      
      context "on group without a submission" do
        setup do
          delete_as @admin, :remove_group, {:grouping_id => @grouping.id}
        end
        should respond_with :success
        should render_template 'delete_groupings.rjs'
        should assign_to(:assignment) { @assignment }
        should assign_to(:errors) { [] }
        should assign_to(:removed_groupings) { [@grouping] }
      end
      
      context "on group with a submission" do
        setup do
          @grouping_with_submission = Grouping.make
          delete_as @admin, :remove_group, {:grouping_id => @grouping_with_submission.id}
        end
        should respond_with :success
        should render_template 'delete_groupings.rjs'
        should assign_to(:assignment) { Assignment.make }
        should assign_to(:errors) { [@grouping_with_submission.group.group_name] }
        should assign_to(:removed_groupings) { [] }
      end
      
    end #:remove_group
    
    context "POST on :rename_group" do
      
      context "with unique, new name" do
        setup do
          @new_name = "NeW"
          post_as @admin, :rename_group, {:id => @assignment.id,
            :grouping_id => @grouping.id, :new_groupname => @new_name}
        end
        should assign_to :assignment
        should assign_to :grouping
        should assign_to :group
        should "set group name accordingly" do
          assert_equal @new_name, assigns(:group).group_name
        end
        should respond_with :success
      end
      
      context "with existing name" do
        setup do
          @new_name = Grouping.make.group.group_name
          post_as @admin, :rename_group, {:id => @assignment.id,
            :grouping_id => @grouping.id, :new_groupname => @new_name}
        end
        should assign_to :assignment
        should assign_to :grouping
        should assign_to :group
        should respond_with :success
        should "not change group name" do
          assert_equal @grouping.group.group_name, assigns(:group).group_name
        end
        should set_the_flash.to(I18n.t('groups.rename_group.already_in_use'))
      end
      
    end #:rename_group
    
    context "POST on :valid_grouping" do
      setup do
        post_as @admin, :valid_grouping, {:id => @assignment.id,
          :grouping_id => @grouping.id}
      end
      should assign_to :assignment
      should respond_with :success
    end

    context "POST on :invalid_grouping" do
      setup do
        post_as @admin, :invalid_grouping, {:id => @assignment.id,
          :grouping_id => @grouping.id}
      end
      should assign_to :assignment
      should respond_with :success
    end
    
    context "POST on :use_another_assignment_groups" do
      setup do
        target_assignment = Assignment.make
        post_as @admin, :use_another_assignment_groups, 
          {:id => target_assignment.id,
           :clone_groups_assignment_id => @assignment.id}
      end
      
      teardown do
        destroy_repos
      end
      
      should assign_to :target_assignment
      should respond_with :success
      should render_template 'use_another_assignment_groups.rjs'
    end
    
    context "POST on :global_actions on delete" do
      
      context "and none selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id,
            :global_actions => "delete"}
        end
        should assign_to :assignment
        should assign_to :tas
      end
      
      context "and one is selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id,
            :global_actions => "delete", :groupings => [@grouping.id]}
        end
        should assign_to :assignment
        should assign_to :tas
        should "assign @removed_groupings accordingly" do
          assert_same_elements [@grouping], assigns(:removed_groupings)
        end
        should assign_to(:errors) { [] }
        should render_template 'delete_groupings.rjs'
      end
      
    end

    context "POST on :global_actions on invalid" do
      context "and none selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id,
            :global_actions => "invalid"}
        end
        should assign_to :assignment
        should assign_to :tas
      end

      context "and one is selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id,
            :global_actions => "invalid", :groupings => [@grouping.id]}
        end
        should assign_to :assignment
        should assign_to :tas
        should render_template 'groups/table_row/_filter_table_row.html.erb'
      end
    end

    context "POST on :global_actions on valid" do
      context "and none selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id,
            :global_actions => "valid"}
        end
        should assign_to :assignment
        should assign_to :tas
      end

      context "and one is selected" do
        setup do
          post_as @admin, :global_actions, {:id => @assignment.id,
            :global_actions => "valid", :groupings => [@grouping.id]}
        end
        should assign_to :assignment
        should assign_to :tas
        should render_template 'groups/table_row/_filter_table_row.html.erb'
      end
    end

    context "POST on :global_actions on assign" do

      setup do
        @assignment = Assignment.make
      end

      context "and no group selected" do
        setup do
          @student =  Student.make
          post_as @admin, :global_actions, {:id => @assignment.id,
            :global_actions => "assign", :students => [@student.id]}
        end
        should assign_to :assignment
        should assign_to :tas
      end

      context "and no students selected" do
        setup do
          @grouping = Grouping.make
          post_as @admin, :global_actions, {:id => @assignment.id,
            :global_actions => "assign", :groupings => [@grouping.id]}
        end
        should assign_to :assignment
        should assign_to :tas
        should "not change number of members" do
          assert_equal 0, @grouping.student_memberships.size
        end
      end

      context "with a single student not in a group" do
        setup do
          @student =  Student.make
          @grouping = Grouping.make
          post_add [@student.id]
        end
        should assign_to :assignment
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 1" do
          assert_equal 1, @grouping.student_memberships.size
        end
        should "set new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal @student.id, @grouping.student_memberships.at(0).user_id
        end
      end

      context "with a single user who is already grouped on this assignment" do
        setup do
          @student =  Student.make
          @grouping = Grouping.make
          @grouping.add_member(@student)
          post_add [@student.id]
        end
        should assign_to :assignment
        should assign_to(:messages) {
          [ I18n.t('add_student.fail.already_grouped', :user_name => @user_name) ] }
        should assign_to(:error) { true }
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should "not change number of members" do
          assert_equal 1, @grouping.student_memberships.size
        end
      end

      context "with two valid users" do
        setup do
          @student1 =  Student.make
          @student2 =  Student.make
          @grouping = Grouping.make
          post_add [@student1.id, @student2.id]
        end
        should assign_to :assignment
        should assign_to(:error) { false }
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 2" do
          assert_equal 2, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal @student1.id, @grouping.student_memberships.at(0).user_id
        end
        should "set second new student as accepted" do
          assert_equal "accepted", @grouping.student_memberships.at(1).membership_status
          assert_equal @student2.id, @grouping.student_memberships.at(1).user_id
        end
      end

      context "with two valid users, with assignment past collection date" do
        setup do
          # stub collection date
          Assignment.any_instance.stubs(:past_collection_date?).returns(true)
          @student1 =  Student.make
          @student2 =  Student.make
          @grouping = Grouping.make
          post_add [@student1.id, @student2.id]
        end
        should assign_to :assignment
        should assign_to(:error) { false }
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 2" do
          assert_equal 2, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal @student1.id, @grouping.student_memberships.at(0).user_id
        end
        should "set second new student as accepted" do
          assert_equal "accepted", @grouping.student_memberships.at(1).membership_status
          assert_equal @student2.id, @grouping.student_memberships.at(1).user_id
        end
      end

      context "with 1 already assigned user, 1 valid user" do
        setup do
          @student1 =  Student.make
          @student2 =  Student.make
          @grouping = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @grouping2.add_member(@student1)
          post_add [@student1.id, @student2.id]
        end
        should assign_to :assignment
        should assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped', :user_name => @student1.user_name)
          ]
        }
        should assign_to(:error) { true }
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 1" do
          assert_equal 1, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal @student2.id, @grouping.student_memberships.at(0).user_id
        end
      end

      context "with 1 valid user, 1 already assigned user" do
        setup do
          @student1 =  Student.make
          @student2 =  Student.make
          @grouping = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @grouping2.add_member(@student2)
          post_add [@student1.id, @student2.id]
        end
        should assign_to :assignment
        should assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped', :user_name => @student2.user_name)
          ]
        }
        should assign_to(:error) { true }
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 1" do
          assert_equal 1, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal @student1.id, @grouping.student_memberships.at(0).user_id
        end
      end

      context "with three valid users" do
        setup do
          @student1 =  Student.make
          @student2 =  Student.make
          @student3 =  Student.make
          @grouping = Grouping.make
          post_add [@student1.id, @student2.id, @student3.id]
        end
        should assign_to :assignment
        should assign_to(:error) { true }
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 3" do
          assert_equal 3, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal @student1.id, @grouping.student_memberships.at(0).user_id
        end
        should "set the other students as accepted" do
          assert_equal "accepted", @grouping.student_memberships.at(1).membership_status
          assert_equal "accepted", @grouping.student_memberships.at(2).membership_status
          assert_equal @student2.id, @grouping.student_memberships.at(1).user_id
          assert_equal @student3.id, @grouping.student_memberships.at(2).user_id
        end
      end

      context "with valid,valid,invalid users" do
        setup do
          @student1 =  Student.make
          @student2 =  Student.make
          @student3 =  Student.make
          @grouping = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @grouping2.add_member(@student3)
          post_add [@student1.id, @student2.id, @student3.id]
        end
        should assign_to :assignment
        should assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped', :user_name => @student3.user_name)
          ]
        }
        should assign_to(:error) { true }
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 2" do
          assert_equal 2, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal  @student1.id, @grouping.student_memberships.at(0).user_id
        end
        should "set second new student as accepted" do
          assert_equal "accepted", @grouping.student_memberships.at(1).membership_status
          assert_equal  @student2.id, @grouping.student_memberships.at(1).user_id
        end
      end

      context "with valid,invalid,valid users" do
        setup do
          @student1 =  Student.make
          @student2 =  Student.make
          @student3 =  Student.make
          @grouping = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @grouping2.add_member(@student2)
          post_add [@student1.id, @student2.id, @student3.id]
        end
        should assign_to :assignment
        should assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped', :user_name => @student2.user_name)
          ]
        }
        should assign_to(:error) { true }
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 2" do
          assert_equal 2, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal  @student1.id, @grouping.student_memberships.at(0).user_id
        end
        should "set second new student as accepted" do
          assert_equal "accepted", @grouping.student_memberships.at(1).membership_status
          assert_equal  @student3.id, @grouping.student_memberships.at(1).user_id
        end
      end

      context "with invalid,valid,valid users" do
        setup do
          @student1 =  Student.make
          @student2 =  Student.make
          @student3 =  Student.make
          @grouping = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @grouping2.add_member(@student1)
          post_add [@student1.id, @student2.id, @student3.id]
        end
        should assign_to :assignment
        should assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped', :user_name => @student1.user_name)
          ]
        }
        should assign_to(:error) { true }
        should respond_with :success
        should render_template 'groups/table_row/_filter_table_row.html.erb'
        should "increment number of members by 2" do
          assert_equal 2, @grouping.student_memberships.size
        end
        should "set first new student as inviter" do
          assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
          assert_equal  @student2.id, @grouping.student_memberships.at(0).user_id
        end
        should "set second new student as accepted" do
          assert_equal "accepted", @grouping.student_memberships.at(1).membership_status
          assert_equal  @student3.id, @grouping.student_memberships.at(1).user_id
        end
      end

    end#POST on global_actions on assign

    context "POST on :global_actions on unassign" do
      setup do
        @grouping = Grouping.make
      end

      context "on member" do
        setup do
          @student1 = Student.make
          @student2 = Student.make
          @grouping.add_member(@student1)
          @grouping.add_member(@student2)
          post_as @admin, :global_actions, {:id => @assignment.id,
            :global_actions => "unassign", :groupings => [@grouping.id],
            "#{@grouping.id}_#{@student2.user_name}" => true}
        end
        should_respond_with :success
        should render_template 'groups/table_row/_filter_table_student_row.erb'
        should_assign_to :assignment
        should "decrease number of members by 1" do
          @grouping.reload
          assert_equal 1, @grouping.student_memberships.size
        end
      end

      context "on inviter" do
        setup do
          @student1 = Student.make
          @student2 = Student.make
          @grouping.add_member(@student1)
          @grouping.add_member(@student2)
          post_as @admin, :global_actions, {:id => @assignment.id,
            :global_actions => "unassign", :groupings => [@grouping.id],
            "#{@grouping.id}_#{@student1.user_name}" => true}
        end
        should_respond_with :success
        should render_template 'groups/table_row/_filter_table_student_row.erb'
        should_assign_to :assignment
        should "decrease number of members by 1" do
          @grouping.reload
          assert_equal 1, @grouping.student_memberships.size
        end
      end

      context "for all group members" do
        setup do
          @student1 = Student.make
          @student2 = Student.make
          @grouping.add_member(@student1)
          @grouping.add_member(@student2)
          post_as @admin, :global_actions, {:id => @assignment.id,
            :global_actions => "unassign", :groupings => [@grouping.id],
            :students => [@student1.id, @student2.id],
            "#{@grouping.id}_#{@student1.user_name}" => true,
            "#{@grouping.id}_#{@student2.user_name}" => true}
        end
        should_respond_with :success
        should render_template 'groups/table_row/_filter_table_student_row.erb'
        should_assign_to :assignment
        should "result in an empty group" do
          @grouping.reload
          assert_equal 0, @grouping.student_memberships.size
        end
      end 
    end#POST on global_actions on unassign
    
    
    context "GET on download_grouplist" do
      setup do
        setup_group_fixture_repos
        @assignment = Assignment.make
      end
      
      context "with no groups" do
        setup do
          @assignment.groupings.destroy_all
          @response = get_as @admin, :download_grouplist, {:id => @assignment.id}
        end
        should respond_with :success
        should "be an empty file returned" do
          assert @response.body.empty?
        end
      end # with no groups
      
      context "with groups, but no TAs assigned" do
        setup do
          # Construct the array that a parse of the returned CSV
          # *should* return
          @assignment = Assignment.make(:groupings => [Grouping.make])
          @match_array = construct_group_list_array(@assignment.groupings)
          @response = get_as @admin, :download_grouplist, {:id => @assignment.id}
        end
        should respond_with :success
        should "not be an empty file returned" do
          assert !@response.body.empty?
        end
        should "return the expected CSV" do
          assert_equal @match_array, FasterCSV.parse(@response.body)
        end
      end # with groups, but no TAs assigned
      
      context "with groups, with TAs assigned" do
        setup do
          @assignment = Assignment.make(:groupings => [Grouping.make])
          @ta1 = Ta.make
          @ta2 = Ta.make
          # For each grouping for Assignment 1, assign 2 TAs
          @assignment.groupings.each do |grouping|
            grouping.add_tas_by_user_name_array([@ta1.user_name, @ta2.user_name])
          end
          @assignment.groupings.reload
          @match_array = construct_group_list_array(@assignment.groupings)
          @response = get_as @admin, :download_grouplist, {:id => @assignment.id}
        end
        should respond_with :success
        should "not be an empty file returned" do
          assert !@response.body.empty?
        end
        should "return the expected CSV, without TAs included" do
          assert_equal @match_array, FasterCSV.parse(@response.body)
        end
      end # with groups, with TAs assigned

    end
  end #admin context
  
  def post_add(students)
    post_as @admin, :global_actions, {:id => @assignment.id, 
      :global_actions => "assign",
      :groupings => [@grouping.id], :students => students}
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
