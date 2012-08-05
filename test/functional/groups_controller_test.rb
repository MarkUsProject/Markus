require File.join(File.dirname(__FILE__), 'authenticated_controller_test')
require File.join(File.dirname(__FILE__), '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'
require 'mocha'
require 'fastercsv'

## TODO refactor this code

class GroupsControllerTest < AuthenticatedControllerTest

  def setup
    clear_fixtures
  end

  context "An authenticated and authorized student doing a " do

    setup do
      @student = Student.make
      @assignment = Assignment.make
    end

    should "GET on :add_group" do
      get_as @student, :add_group, :assignment_id => @assignment.id
      assert_response :missing
    end

    should "GET on :remove_group" do
      get_as @student, :remove_group, :assignment_id => @assignment.id
      assert_response :missing
    end

    should "GET on :rename_group" do
      get_as @student, :rename_group, :assignment_id => @assignment.id
      assert_response :missing
    end

    should "GET on :valid_grouping" do
      get_as @student, :valid_grouping, :assignment_id => @assignment.id
      assert_response :missing
    end

    should "GET on :invalid_grouping" do
      get_as @student, :invalid_grouping, :assignment_id => @assignment.id
      assert_response :missing
    end

    should "GET on :index" do
      get_as @student, :index, :assignment_id => @assignment.id
      assert_response :missing
    end

    should "GET on :csv_upload" do
      get_as @student, :csv_upload, :assignment_id => @assignment.id
      assert_response :missing
    end

    should "GET on :download_grouplist" do
      get_as @student, :download_grouplist, :assignment_id => @assignment.id
      assert_response :missing
    end

    should "GET on :use_another_assignment_groups" do
      get_as @student,
             :use_another_assignment_groups,
             :assignment_id => @assignment.id
      assert_response :missing
    end

  end #student context

  context "An authenticated and authorized admin doing a " do

    setup do
      @admin = Admin.make
      @grouping = Grouping.make
      @assignment = Assignment.make(:groupings => [@grouping])
      setup_group_fixture_repos
    end

    should "GET on :index(groups_controller)" do
      get_as @admin,
             :index,
             :assignment_id => @assignment.id
      assert_response :success
    end

    should "GET on :populate" do
      get_as @admin,
             :populate,
             :assignment_id => @assignment.id
      assert_response :success
    end

    should "GET on :populate_students" do
      get_as @admin,
             :populate_students,
             :assignment_id => @assignment.id
      assert_response :success
    end

    should "GET on :index" do
      get_as @admin,
             :index,
             :assignment_id => @assignment.id
      assert_response :success
    end

    context "POST on :add_group" do

      should "be able to add group without groupname" do
        @assignment = Assignment.make
        Assignment.any_instance.stubs(:add_group).returns(Grouping.make)
        post_as @admin,
                :add_group,
                :assignment_id => @assignment.id
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row'
        assert assign_to(:assignment) { @assignment }
        assert assign_to :new_grouping
      end

      should "be able to create with groupname" do
        post_as @admin,
                :add_group,
                {:assignment_id => @assignment.id, :new_group_name => "test"}
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row.html.erb'
        assert assign_to(:assignment) { @assignment }
        assert assign_to :new_grouping
      end
    end #:add_group

    context "DELETE on :remove_group" do

      should "on group without a submission" do
        delete_as @admin,
                 :remove_group,
                 {:assignment_id => @assignment.id,
                  :grouping_id => @grouping.id}
        assert_response :success
        assert render_template 'groups/delete_groupings'
        assert assign_to(:assignment) { @assignment }
        assert assign_to(:errors) { [] }
        assert assign_to(:removed_groupings) { [@grouping] }
      end

      should "on group with a submission" do
        @grouping_with_submission = Grouping.make
        delete_as @admin,
                  :remove_group,
                  {:assignment_id => @assignment.id,
                   :grouping_id => @grouping_with_submission.id}
        assert_response :success
        assert render_template 'groups/delete_groupings'
        assert assign_to(:assignment) { Assignment.make }
        assert assign_to(:errors) { [@grouping_with_submission.group.group_name] }
        assert assign_to(:removed_groupings) { [] }
      end

    end #:remove_group

    context "POST on :rename_group" do

      should "with unique, new name" do
        @new_name = "NeW"
        post_as @admin,
                :rename_group, {:assignment_id => @assignment.id,
          :id => @grouping.id, :new_groupname => @new_name}
        assert assign_to :assignment
        assert assign_to :grouping
        assert assign_to :group
        assert_equal @new_name, assigns(:group).group_name
        assert_response :success
      end

      should "with existing name" do
        @new_name = Grouping.make.group.group_name
        post_as @admin, :rename_group, {:assignment_id => @assignment.id,
          :id => @grouping.id, :new_groupname => @new_name}
        assert assign_to :assignment
        assert assign_to :grouping
        assert assign_to :group
        assert_response :success
        assert_equal @grouping.group.group_name, assigns(:group).group_name
        assert_equal flash[:fail_notice], I18n.t('groups.rename_group.already_in_use')
      end

    end #:rename_group

    should "POST on :valid_grouping" do
      post_as @admin, :valid_grouping, {:assignment_id => @assignment.id,
        :grouping_id => @grouping.id}
      assert assign_to :assignment
      assert_response :success
    end

    should "POST on :invalid_grouping" do
      post_as @admin, :invalid_grouping, {:assignment_id => @assignment.id,
        :grouping_id => @grouping.id}
      assert assign_to :assignment
      assert_response :success
    end

    should "be able to clone groups from another assignment" do
      target_assignment = Assignment.make
      post_as @admin,
              :use_another_assignment_groups,
              {:assignment_id => target_assignment.id,
               :clone_groups_assignment_id => @assignment.id}

      assert assign_to :target_assignment
      assert_response :success
      assert render_template 'use_another_assignment_groups.rjs'
    end

    should "should be able to delete" do
      post_as @admin, :global_actions, {:assignment_id => @assignment.id,
        :global_actions => "delete"}
      assert assign_to :assignment
      assert assign_to :tas
    end

    should "be able to delete a grouping" do
      post_as @admin, :global_actions, {:assignment_id => @assignment.id,
          :global_actions => "delete", :groupings => [@grouping.id]}
      assert assign_to :assignment
      assert assign_to :tas
      assert_same_elements [@grouping], assigns(:removed_groupings)
      assert assign_to(:errors) { [] }
      assert render_template 'delete_groupings.rjs'
    end

    should "should be able to do invalid" do
      post_as @admin, :global_actions, {:assignment_id => @assignment.id,
        :global_actions => "invalid"}
      assert assign_to :assignment
      assert assign_to :tas
    end

    should "should be able to invalide a selected grouping" do
      post_as @admin, :global_actions, {:assignment_id => @assignment.id,
        :global_actions => "invalid", :groupings => [@grouping.id]}
      assert assign_to :assignment
      assert assign_to :tas
      assert render_template 'groups/table_row/_filter_table_row.html.erb'
    end

    should "be able to validate" do
      post_as @admin, :global_actions, {:assignment_id => @assignment.id,
        :global_actions => "valid"}
      assert assign_to :assignment
      assert assign_to :tas
    end

    should "and one is selected" do
      post_as @admin, :global_actions, {:assignment_id => @assignment.id,
        :global_actions => "valid", :groupings => [@grouping.id]}
      assert assign_to :assignment
      assert assign_to :tas
      assert render_template 'groups/table_row/_filter_table_row.html.erb'
    end

    context "POST on :global_actions on assign" do

      setup do
        @assignment = Assignment.make
      end

      should "and no group selected" do
        @student =  Student.make
        post_as @admin, :global_actions, {:assignment_id => @assignment.id,
          :global_actions => "assign", :students => [@student.id]}
        assert assign_to :assignment
        assert assign_to :tas
      end

      should "and no students selected" do
        @grouping = Grouping.make
        post_as @admin, :global_actions, {:assignment_id => @assignment.id,
          :global_actions => "assign", :groupings => [@grouping.id]}
        assert assign_to :assignment
        assert assign_to :tas
        assert_equal 0, @grouping.student_memberships.size
      end

      should "with a single student not in a group" do
        @student =  Student.make
        @grouping = Grouping.make
        post_add [@student.id]
        assert assign_to :assignment
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row.html.erb'
        assert_equal 1, @grouping.student_memberships.size
        assert_equal "inviter",
                      @grouping.student_memberships.at(0).membership_status
        assert_equal @student.id, @grouping.student_memberships.at(0).user_id
      end

      should "with a single user who is already grouped on this assignment" do
        @student =  Student.make
        @grouping = Grouping.make
        @grouping.add_member(@student)
        post_add [@student.id]
        assert assign_to :assignment
        assert assign_to(:messages) {
          [ I18n.t('add_student.fail.already_grouped', :user_name => @user_name) ] }
        assert assign_to(:error) { true }
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row.html.erb'
        assert_equal 1, @grouping.student_memberships.size
      end

      should "with two valid users" do
        @student1 =  Student.make
        @student2 =  Student.make
        @grouping = Grouping.make
        post_add [@student1.id, @student2.id]
        assert assign_to :assignment
        assert assign_to(:error) { false }
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row.html.erb'
        assert_equal 2,
                     @grouping.student_memberships.size
        assert_equal "inviter",
                     @grouping.student_memberships.at(0).membership_status
        assert_equal @student1.id, @grouping.student_memberships.at(0).user_id
        assert_equal "accepted",
                     @grouping.student_memberships.at(1).membership_status
        assert_equal @student2.id, @grouping.student_memberships.at(1).user_id
      end

      should "with two valid users, with assignment past collection date" do
        # stub collection date
        Assignment.any_instance.stubs(:past_collection_date?).returns(true)
        @student1 =  Student.make
        @student2 =  Student.make
        @grouping = Grouping.make
        post_add [@student1.id, @student2.id]
        assert assign_to :assignment
        assert assign_to(:error) { false }
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row.html.erb'
        assert_equal 2, @grouping.student_memberships.size
        assert_equal "inviter",
                     @grouping.student_memberships.at(0).membership_status
        assert_equal @student1.id, @grouping.student_memberships.at(0).user_id
        assert_equal "accepted",
                     @grouping.student_memberships.at(1).membership_status
        assert_equal @student2.id, @grouping.student_memberships.at(1).user_id
      end

      should "be able to add members" do
        @student1 =  Student.make
        @student2 =  Student.make
        @grouping = Grouping.make(:assignment => @assignment)
        @grouping2 = Grouping.make(:assignment => @assignment)
        @grouping2.add_member(@student1)
        post_add [@student1.id, @student2.id]

        assert assign_to :assignment
        assert assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped', :user_name => @student1.user_name)
          ]
        }
        assert assign_to(:error) { true }
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row.html.erb'
        assert_equal 1, @grouping.student_memberships.size
        assert_equal "inviter",
                     @grouping.student_memberships.at(0).membership_status
        assert_equal @student2.id, @grouping.student_memberships.at(0).user_id
      end

      should "with 1 valid user, 1 already assigned user" do
        @student1 =  Student.make
        @student2 =  Student.make
        @grouping = Grouping.make(:assignment => @assignment)
        @grouping2 = Grouping.make(:assignment => @assignment)
        @grouping2.add_member(@student2)
        post_add [@student1.id, @student2.id]

        assert assign_to :assignment
        assert assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped',
                   :user_name => @student2.user_name)
          ]
        }
        assert assign_to(:error) { true }
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row.html.erb'
        assert_equal 1, @grouping.student_memberships.size
        assert_equal "inviter", @grouping.student_memberships.at(0).membership_status
        assert_equal @student1.id, @grouping.student_memberships.at(0).user_id
      end

      should "with three valid users" do
        @student1 =  Student.make
        @student2 =  Student.make
        @student3 =  Student.make
        @grouping = Grouping.make
        post_add [@student1.id, @student2.id, @student3.id]
        assert assign_to :assignment
        assert assign_to(:error) { true }
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row.html.erb'
        assert_equal 3, @grouping.student_memberships.size
        assert_equal "inviter",
                     @grouping.student_memberships.at(0).membership_status
        assert_equal @student1.id,
                     @grouping.student_memberships.at(0).user_id
        assert_equal "accepted",
                     @grouping.student_memberships.at(1).membership_status
        assert_equal "accepted",
                     @grouping.student_memberships.at(2).membership_status
        assert_equal @student2.id, @grouping.student_memberships.at(1).user_id
        assert_equal @student3.id, @grouping.student_memberships.at(2).user_id
      end

      should "with valid,valid,invalid users" do
        @student1 =  Student.make
        @student2 =  Student.make
        @student3 =  Student.make
        @grouping = Grouping.make(:assignment => @assignment)
        @grouping2 = Grouping.make(:assignment => @assignment)
        @grouping2.add_member(@student3)
        post_add [@student1.id, @student2.id, @student3.id]
        assert assign_to :assignment
        assert assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped', :user_name => @student3.user_name)
          ]
        }
        assert assign_to(:error) { true }
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row.html.erb'
        assert_equal 2, @grouping.student_memberships.size
        assert_equal "inviter",
                     @grouping.student_memberships.at(0).membership_status
        assert_equal @student1.id,
                     @grouping.student_memberships.at(0).user_id
        assert_equal "accepted",
                     @grouping.student_memberships.at(1).membership_status
        assert_equal  @student2.id, @grouping.student_memberships.at(1).user_id
      end

      should "with valid,invalid,valid users" do
        @student1 =  Student.make
        @student2 =  Student.make
        @student3 =  Student.make
        @grouping = Grouping.make(:assignment => @assignment)
        @grouping2 = Grouping.make(:assignment => @assignment)
        @grouping2.add_member(@student2)
        post_add [@student1.id, @student2.id, @student3.id]
        assert assign_to :assignment
        assert assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped', :user_name => @student2.user_name)
          ]
        }
        assert assign_to(:error) { true }
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row.html.erb'
        assert_equal 2, @grouping.student_memberships.size
        assert_equal "inviter",
                     @grouping.student_memberships.at(0).membership_status
        assert_equal  @student1.id, @grouping.student_memberships.at(0).user_id
        assert_equal "accepted",
                     @grouping.student_memberships.at(1).membership_status
        assert_equal @student3.id, @grouping.student_memberships.at(1).user_id
      end

      should "with invalid,valid,valid users" do
        @student1 =  Student.make
        @student2 =  Student.make
        @student3 =  Student.make
        @grouping = Grouping.make(:assignment => @assignment)
        @grouping2 = Grouping.make(:assignment => @assignment)
        @grouping2.add_member(@student1)
        post_add [@student1.id, @student2.id, @student3.id]
        assert assign_to :assignment
        assert assign_to(:messages) {
          [
            I18n.t('add_student.fail.already_grouped', :user_name => @student1.user_name)
          ]
        }
        assert assign_to(:error) { true }
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_row.html.erb'
        assert_equal 2, @grouping.student_memberships.size
        assert_equal "inviter",
                     @grouping.student_memberships.at(0).membership_status
        assert_equal @student2.id, @grouping.student_memberships.at(0).user_id
        assert_equal "accepted",
                     @grouping.student_memberships.at(1).membership_status
        assert_equal @student3.id, @grouping.student_memberships.at(1).user_id
      end

    end #POST on global_actions on assign

    context "with a grouping" do
      setup do
        @grouping = Grouping.make
      end

      should "be able to unassigne a member" do
        @student1 = Student.make
        @student2 = Student.make
        @grouping.add_member(@student1)
        @grouping.add_member(@student2)
        post_as @admin, :global_actions, {:assignment_id => @assignment.id,
          :global_actions => "unassign", :groupings => [@grouping.id],
          "#{@grouping.id}_#{@student2.user_name}" => true}
        assert respond_with:success
        assert render_template 'groups/table_row/_filter_table_student_row.erb'
        assert assign_to :assignment
        @grouping.reload
        assert_equal 1, @grouping.student_memberships.size
      end

      should "be able to unassign an inviter" do
        @student1 = Student.make
        @student2 = Student.make
        @grouping.add_member(@student1)
        @grouping.add_member(@student2)
        post_as @admin, :global_actions, {:assignment_id => @assignment.id,
          :global_actions => "unassign", :groupings => [@grouping.id],
          "#{@grouping.id}_#{@student1.user_name}" => true}
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_student_row.erb'
        assert assign_to :assignment
        @grouping.reload
        assert_equal 1, @grouping.student_memberships.size
      end

      should "be able to unassigne all group members" do
        @student1 = Student.make
        @student2 = Student.make
        @grouping.add_member(@student1)
        @grouping.add_member(@student2)
        post_as @admin, :global_actions, {:assignment_id => @assignment.id,
          :global_actions => "unassign", :groupings => [@grouping.id],
          :students => [@student1.id, @student2.id],
          "#{@grouping.id}_#{@student1.user_name}" => true,
          "#{@grouping.id}_#{@student2.user_name}" => true}
        assert_response :success
        assert render_template 'groups/table_row/_filter_table_student_row.erb'
        assert assign_to :assignment
        @grouping.reload
        assert_equal 0, @grouping.student_memberships.size
      end
    end #POST on global_actions on unassign


    context "GET on download_grouplist" do
      setup do
        setup_group_fixture_repos
        @assignment = Assignment.make
      end

      context "with no groups" do
        setup do
          @assignment.groupings.destroy_all
          @response = get_as @admin, :download_grouplist, {:assignment_id => @assignment.id}
        end
        should respond_with :success
        should "be an empty file returned" do
          assert @response.body.empty?
        end
        should "route properly" do
          assert_recognizes({:controller => "groups", :assignment_id => "1", :action => "download_grouplist" },
            {:path => "assignments/1/groups/download_grouplist", :method => :get})
        end
      end # with no groups

      context "with groups, but no TAs assigned" do
        setup do
          # Construct the array that a parse of the returned CSV
          # *should* return
          @assignment = Assignment.make(:groupings => [Grouping.make])
          @match_array = construct_group_list_array(@assignment.groupings)
          @response = get_as @admin, :download_grouplist, {:assignment_id => @assignment.id}
        end
        should respond_with :success
        should "not be an empty file returned" do
          assert !@response.body.empty?
        end
        should "return the expected CSV" do
          assert_equal @match_array, FasterCSV.parse(@response.body)
        end
        should "route properly" do
          assert_recognizes({:controller => "groups", :assignment_id => "1", :action => "download_grouplist" },
            {:path => "assignments/1/groups/download_grouplist", :method => :get})
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
          @response = get_as @admin, :download_grouplist, {:assignment_id => @assignment.id}
        end
        should respond_with :success
        should "not be an empty file returned" do
          assert !@response.body.empty?
        end
        should "return the expected CSV, without TAs included" do
          assert_equal @match_array, FasterCSV.parse(@response.body)
        end
        should "route properly" do
          assert_recognizes({:controller => "groups", :assignment_id => "1", :action => "download_grouplist" },
            {:path => "assignments/1/groups/download_grouplist", :method => :get})
        end
      end # with groups, with TAs assigned

    end
  end #admin context

  def post_add(students)
    post_as @admin, :global_actions, {:assignment_id => @assignment.id,
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
