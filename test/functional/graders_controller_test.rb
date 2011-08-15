require File.join(File.dirname(__FILE__), 'authenticated_controller_test')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')


require 'shoulda'
require 'mocha'
require 'fastercsv'

class GradersControllerTest < AuthenticatedControllerTest

  def setup
    clear_fixtures
  end

  context "An authenticated and authorized student doing a " do

    setup do
      @student = Student.make
    end

    context "GET on :upload_dialog" do
      setup do
        get_as @student, :upload_dialog, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "GET on :download_dialog" do
      setup do
        get_as @student, :download_dialog, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "GET on :groups_coverage_dialog" do
      setup do
        get_as @student, :groups_coverage_dialog, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "GET on :grader_criteria_dialog" do
      setup do
        get_as @student, :grader_criteria_dialog, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "GET on :populate" do
      setup do
        get_as @student, :populate, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "GET on :populate_graders" do
      setup do
        get_as @student, :populate_graders, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "GET on :populate_criteria" do
      setup do
        get_as @student, :populate_criteria, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "GET on :set_assign_criteria" do
      setup do
        get_as @student, :set_assign_criteria, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "GET on :index" do
      setup do
        get_as @student, :index, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "GET on :csv_upload_grader_mapping" do
      setup do
        get_as @student, :csv_upload_grader_mapping, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "GET on :download_grouplist" do
      setup do
        get_as @student, :download_grouplist, :assignment_id => 2
      end
      should respond_with :missing
    end

    context "GET on :add_grader_to_grouping" do
      setup do
        get_as @student, :add_grader_to_grouping, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "GET on :global_actions" do
      setup do
        get_as @student, :global_action, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :upload_dialog" do
      setup do
        post_as @student, :upload_dialog, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :download_dialog" do
      setup do
        post_as @student, :download_dialog, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :groups_coverage_dialog" do
      setup do
        post_as @student, :groups_coverage_dialog, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :grader_criteria_dialog" do
      setup do
        post_as @student, :grader_criteria_dialog, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :populate" do
      setup do
        post_as @student, :populate, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :populate_graders" do
      setup do
        post_as @student, :populate_graders, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :populate_criteria" do
      setup do
        post_as @student, :populate_criteria, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :set_assign_criteria" do
      setup do
        post_as @student, :set_assign_criteria, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :csv_upload_grader_mapping" do
      setup do
        post_as @student, :csv_upload_grader_mapping, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :download_grouplist" do
      setup do
        post_as @student, :download_grouplist, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :add_grader_to_grouping" do
      setup do
        post_as @student, :add_grader_to_grouping, :assignment_id => 1
      end
      should respond_with :missing
    end

    context "POST on :global_actions" do
      setup do
        post_as @student, :global_actions, :assignment_id => 1
      end
      should respond_with :missing
    end

  end #student context

  context "An authenticated and authorized admin" do

    setup do
      @admin = Admin.make
      @assignment = Assignment.make(:marking_scheme_type => "rubric")
    end

    context "doing a GET on :index(graders_controller)" do
      setup do
        get_as @admin, :index, {:assignment_id => @assignment.id}
      end
      should respond_with :success
      should assign_to :assignment
    end #manage

    context "doing a POST on :set_assign_criteria" do

      context "and value is true" do
        setup do
          post_as @admin, :set_assign_criteria, {:assignment_id => @assignment.id,
            :value => 'true'}
        end
        should respond_with :success
        should "set assignment.assign_graders_to_criteria to true" do
          @assignment.reload
          assert @assignment.assign_graders_to_criteria
        end
      end

      context "and value is nil" do
        setup do
          post_as @admin, :set_assign_criteria, {:assignment_id => @assignment.id}
        end
        should respond_with :success
        should "set assignment.assign_graders_to_criteria to false" do
          @assignment.reload
          assert !@assignment.assign_graders_to_criteria
        end
      end
    end

    context "doing a POST on :csv_upload_grader_groups_mapping" do

      setup do
        # Contents: test_group,g9browni,g9younas
        #           second_test_group,g9browni
        #           Group 3,c7benjam
        @group_grader_map_file = fixture_file_upload(
                                    File.join("..",
                                              "group_csvs",
                                              "group_grader_map.csv"))
      end

      context "and all graders and groups are valid" do
        setup do
          @ta1 = Ta.make(:user_name => "g9browni")
          @ta2 = Ta.make(:user_name => "g9younas")
          @ta3 = Ta.make(:user_name => "c7benjam")
          @grouping1 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => "test_group"))
          @grouping2 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => "second_test_group"))
          @grouping3 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => "Group 3"))
          post_as @admin, :csv_upload_grader_groups_mapping, {
              :assignment_id => @assignment.id,
              :grader_mapping => @group_grader_map_file}
        end

        should respond_with :redirect
        should "assign graders to groupings appropriately" do
          assert @grouping1.tas.count == 2
          assert @grouping1.tas.include? @ta1
          assert @grouping1.tas.include? @ta2
          assert @grouping2.tas.count == 1
          assert @grouping2.tas.include? @ta1
          assert @grouping3.tas.count == 1
          assert @grouping3.tas.include? @ta3
        end
      end

      context "and some graders are invalid" do
        setup do
          @ta1 = Ta.make(:user_name => "g9browni")
          @ta2 = Ta.make(:user_name => "g9younas")
          @ta3 = Ta.make(:user_name => "c0curtis")
          @grouping1 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => "test_group"))
          @grouping2 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => "second_test_group"))
          @grouping3 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => "Group 3"))
          post_as @admin, :csv_upload_grader_groups_mapping, {
              :assignment_id => @assignment.id,
              :grader_mapping => @group_grader_map_file}
        end

        should respond_with :redirect
        should "assign valid graders to groupings but ignore invalid ones" do
          assert @grouping1.tas.count == 2
          assert @grouping1.tas.include? @ta1
          assert @grouping1.tas.include? @ta2
          assert @grouping2.tas.count == 1
          assert @grouping2.tas.include? @ta1
          assert @grouping3.tas.count == 0
        end
      end

      context "and some groupings are invalid" do
        setup do
          @ta1 = Ta.make(:user_name => "g9browni")
          @ta2 = Ta.make(:user_name => "g9younas")
          @ta3 = Ta.make(:user_name => "c7benjam")
          @grouping1 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => "Group of 7"))
          @grouping2 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => "second_test_group"))
          @grouping3 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => "Group 3"))
          post_as @admin, :csv_upload_grader_groups_mapping, {
              :assignment_id => @assignment.id,
              :grader_mapping => @group_grader_map_file}
        end

        should respond_with :redirect
        should "still assign graders to valid groupings" do
          assert @grouping1.tas.count == 0
          assert @grouping2.tas.count == 1
          assert @grouping2.tas.include? @ta1
          assert @grouping3.tas.count == 1
          assert @grouping3.tas.include? @ta3
        end
      end
    end #groups csv upload

    context "doing a POST on :csv_upload_grader_criteria_mapping" do

      setup do
        # Contents: correctness,g9browni,g9younas
        #           style,g9browni
        #           class design,c7benjam
        @ctieria_grader_map_file = fixture_file_upload(
                                      File.join("..",
                                                "group_csvs",
                                                "criteria_grader_map.csv"))
      end

      context "with rubric criteria" do
        setup do
          @assignment = Assignment.make(:marking_scheme_type => 'rubric', :assign_graders_to_criteria => true)
        end
        context "and all graders and criteria are valid" do
          setup do
            @ta1 = Ta.make(:user_name => "g9browni")
            @ta2 = Ta.make(:user_name => "g9younas")
            @ta3 = Ta.make(:user_name => "c7benjam")
            @criterion1 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => "correctness")
            @criterion2 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => "style")
            @criterion3 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => "class design")
            post_as @admin, :csv_upload_grader_criteria_mapping, {
                :assignment_id => @assignment.id,
                :grader_criteria_mapping => @ctieria_grader_map_file}
          end

          should respond_with :redirect
          should "assign graders to criteria appropriately" do
            assert @criterion1.tas.count == 2
            assert @criterion1.tas.include? @ta1
            assert @criterion1.tas.include? @ta2
            assert @criterion2.tas.count == 1
            assert @criterion2.tas.include? @ta1
            assert @criterion3.tas.count == 1
            assert @criterion3.tas.include? @ta3
          end
        end

        context "and some graders are invalid" do
          setup do
            @ta1 = Ta.make(:user_name => "g9browni")
            @ta2 = Ta.make(:user_name => "reid")
            @ta3 = Ta.make(:user_name => "c7benjam")
            @criterion1 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => "correctness")
            @criterion2 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => "style")
            @criterion3 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => "class design")
            post_as @admin, :csv_upload_grader_criteria_mapping, {
                :assignment_id => @assignment.id,
                :grader_criteria_mapping => @ctieria_grader_map_file}
          end

          should respond_with :redirect
          should "assign only valid graders to criteria" do
            assert @criterion1.tas.count == 1
            assert @criterion1.tas.include? @ta1
            assert @criterion2.tas.count == 1
            assert @criterion2.tas.include? @ta1
            assert @criterion3.tas.count == 1
            assert @criterion3.tas.include? @ta3
          end
        end

        context "and some criteria are invalid" do
          setup do
            @ta1 = Ta.make(:user_name => "g9browni")
            @ta2 = Ta.make(:user_name => "g9younas")
            @ta3 = Ta.make(:user_name => "c7benjam")
            @criterion1 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => "correctness")
            @criterion2 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => "professor's whim")
            @criterion3 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => "class design")
            post_as @admin, :csv_upload_grader_criteria_mapping, {
                :assignment_id => @assignment.id,
                :grader_criteria_mapping => @ctieria_grader_map_file}
          end

          should respond_with :redirect
          should "assign only to valid criteria" do
            assert @criterion1.tas.count == 2
            assert @criterion1.tas.include? @ta1
            assert @criterion2.tas.count == 0
            assert @criterion3.tas.count == 1
            assert @criterion3.tas.include? @ta3
          end
        end
      end # rubric criteria

      context "with flexible criteria" do
        setup do
          @assignment = Assignment.make(:marking_scheme_type => 'flexible', :assign_graders_to_criteria => true)
        end
        context "and all graders and criteria are valid" do
          setup do
            @ta1 = Ta.make(:user_name => "g9browni")
            @ta2 = Ta.make(:user_name => "g9younas")
            @ta3 = Ta.make(:user_name => "c7benjam")
            @criterion1 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => "correctness")
            @criterion2 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => "style")
            @criterion3 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => "class design")
            post_as @admin, :csv_upload_grader_criteria_mapping, {
                :assignment_id => @assignment.id,
                :grader_criteria_mapping => @ctieria_grader_map_file}
          end

          should respond_with :redirect
          should "assign graders to criteria appropriately" do
            assert @criterion1.tas.count == 2
            assert @criterion1.tas.include? @ta1
            assert @criterion1.tas.include? @ta2
            assert @criterion2.tas.count == 1
            assert @criterion2.tas.include? @ta1
            assert @criterion3.tas.count == 1
            assert @criterion3.tas.include? @ta3
          end
        end

        context "and some graders are invalid" do
          setup do
            @ta1 = Ta.make(:user_name => "g9browni")
            @ta2 = Ta.make(:user_name => "reid")
            @ta3 = Ta.make(:user_name => "c7benjam")
            @criterion1 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => "correctness")
            @criterion2 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => "style")
            @criterion3 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => "class design")
            post_as @admin, :csv_upload_grader_criteria_mapping, {
                :assignment_id => @assignment.id,
                :grader_criteria_mapping => @ctieria_grader_map_file}
          end

          should respond_with :redirect
          should "assign only valid graders to criteria" do
            assert @criterion1.tas.count == 1
            assert @criterion1.tas.include? @ta1
            assert @criterion2.tas.count == 1
            assert @criterion2.tas.include? @ta1
            assert @criterion3.tas.count == 1
            assert @criterion3.tas.include? @ta3
          end
        end

        context "and some criteria are invalid" do
          setup do
            @ta1 = Ta.make(:user_name => "g9browni")
            @ta2 = Ta.make(:user_name => "g9younas")
            @ta3 = Ta.make(:user_name => "c7benjam")
            @criterion1 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => "correctness")
            @criterion2 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => "professor's whim")
            @criterion3 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => "class design")
            post_as @admin, :csv_upload_grader_criteria_mapping, {
                :id => @assignment.id,
                :grader_criteria_mapping => @ctieria_grader_map_file}
          end

          should respond_with :redirect
          should "assign only to valid criteria" do
            assert @criterion1.tas.count == 2
            assert @criterion1.tas.include? @ta1
            assert @criterion2.tas.count == 0
            assert @criterion3.tas.count == 1
            assert @criterion3.tas.include? @ta3
          end
        end
      end # flexible criteria
    end # criteria csv upload

    context "doing a POST on :add_grader_to_grouping" do
        setup do
          @grouping = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @ta = Ta.make
          @ta2 = Ta.make
          post_as @admin, :add_grader_to_grouping, {:id => @assignment.id,
              :grouping_id => @grouping.id,
              :grader_id => @ta.id}
        end
        should respond_with :success
        should "assign a grader to a grouping" do
          assert @grouping.tas[0].id == @ta.id
        end
        should "not assign any other graders to the grouping" do
          assert @grouping.tas.count == 1
        end
        should "not assign grader to any other groupings" do
          assert @ta.memberships.count == 1
        end
    end

    context "with groups table selected doing a" do

      context "POST on :global_actions on random_assign" do
        setup do
          @grouping1 = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @grouping3 = Grouping.make(:assignment => @assignment)
          @ta1 = Ta.make
          @ta2 = Ta.make
          @ta3 = Ta.make
        end

        context "and no graders selected" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "random_assign", :current_table => "groups_table"}
          end
          should respond_with :success
          should "not assign anything" do
            @assignment.groupings do |grouping|
              assert grouping.tas == []
            end
          end
        end

        context "and no groups selected, at least one grader" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "random_assign", :graders => [@ta1], :current_table => "groups_table"}
          end
          should respond_with :success
          should "not assign anything" do
            @assignment.groupings do |grouping|
              assert grouping.tas == []
            end
          end
        end

        context "and no graders are selected, at least one grouping" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "random_assign", :groupings => [@grouping1], :current_table => "groups_table"}
          end
          should respond_with :success
          should "not assign anything" do
            @assignment.groupings do |grouping|
              assert grouping.tas == []
            end
          end
        end

        context "and one grader and one grouping is selected" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "random_assign", :groupings => [@grouping1],
              :graders => [@ta1], :current_table => "groups_table"}
          end
          should respond_with :success
          should "assign grader to grouping" do
            assert @grouping1.tas[0].id == @ta1.id
          end
          should "not assign assign grader to non-selected groupings" do
            assert @grouping2.tas == []
            assert @grouping3.tas == []
          end
        end

        context "and one grader and multiple groupings are selected" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "random_assign",
              :groupings => [@grouping1, @grouping2],
              :graders => [@ta1],
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "assign grader to all groupings" do
            assert @grouping1.tas[0].id == @ta1.id
            assert @grouping2.tas[0].id == @ta1.id
          end
          should "not assign assign grader to non-selected groupings" do
            assert @grouping3.tas == []
          end
        end

        context "and two graders and one grouping is selected" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "random_assign",
              :groupings => [@grouping1],
              :graders => [@ta1, @ta2],
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "assign one of the graders to the grouping" do
            assert((@grouping1.tas[0].id == @ta1.id or @grouping1.tas[0].id == @ta2.id))
          end
          should "not assign assign grader to non-selected groupings" do
            assert @grouping2.tas == []
            assert @grouping3.tas == []
          end
        end

        context "and two graders and two groupings are selected" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "random_assign",
              :groupings => [@grouping1, @grouping2],
              :graders => [@ta1, @ta2],
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "assign one of the graders to each grouping" do
            assert((@grouping1.tas[0].id == @ta1.id or @grouping1.tas[0].id == @ta2.id))
            assert((@grouping2.tas[0].id == @ta1.id or @grouping2.tas[0].id == @ta2.id))
            assert @grouping1.tas[0].id != @grouping2.tas[0].id
          end
          should "not assign assign grader to non-selected groupings" do
            assert @grouping3.tas == []
          end
        end

        context "and multiple graders and multiple groupings are selected" do
          setup do
            @ta3 = Ta.make
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "random_assign",
              :groupings => [@grouping1, @grouping2, @grouping3],
              :graders => [@ta1, @ta2, @ta3],
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "assign exactly one grader to each grouping" do
            assert @grouping1.tas.size == 1
            assert @grouping2.tas.size == 1
            assert @grouping3.tas.size == 1
          end
        end
      end #random assign

      context "POST on :global_actions on assign" do
        setup do
          @grouping1 = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @grouping3 = Grouping.make(:assignment => @assignment)
          @ta1 = Ta.make
          @ta2 = Ta.make
          @ta3 = Ta.make
        end

        context "and no graders selected" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "assign", :current_table => "groups_table"}
          end
          should respond_with :success
          should "not assign anything" do
            @assignment.groupings do |grouping|
              assert grouping.tas == []
            end
          end
        end

        context "and no groupings selected, at least one grader" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "assign", :graders => [@ta1], :current_table => "groups_table"}
          end
          should respond_with :success
          should "not assign anything" do
            @assignment.groupings do |grouping|
              assert grouping.tas == []
            end
          end
        end

        context "and no graders are selected, at least one grouping" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "assign", :groupings => [@grouping1], :current_table => "groups_table"}
          end
          should respond_with :success
          should "not assign anything" do
            @assignment.groupings do |grouping|
              assert grouping.tas == []
            end
          end
        end

        context "and one grader and one grouping is selected" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "assign", :groupings => [@grouping1],
              :graders => [@ta1], :current_table => "groups_table"}
          end
          should respond_with :success
          should "assign grader to grouping" do
            assert @grouping1.tas[0].id == @ta1.id
          end
          should "not assign assign grader to non-selected groupings" do
            assert @grouping2.tas == []
            assert @grouping3.tas == []
          end
        end

        context "and one grader and two groupings are selected" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "assign",
              :groupings => [@grouping1, @grouping2],
              :graders => [@ta1],
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "assign grader to all groupings" do
            assert @grouping1.tas[0].id == @ta1.id
            assert @grouping2.tas[0].id == @ta1.id
          end
          should "not assign assign grader to non-selected groupings" do
            assert @grouping3.tas == []
          end
        end

        context "and two graders and one grouping is selected" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "assign",
              :groupings => [@grouping1],
              :graders => [@ta1, @ta2],
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "assign both graders to each grouping" do
            assert @grouping1.tas.length == 2
            assert @grouping1.tas.include?(@ta1)
            assert @grouping1.tas.include?(@ta2)
          end
          should "not assign assign grader to non-selected groupings" do
            assert @grouping2.tas == []
            assert @grouping3.tas == []
          end
        end

        context "and two graders and two groupings are selected" do
          setup do
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "assign",
              :groupings => [@grouping1, @grouping2],
              :graders => [@ta1, @ta2],
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "assign both graders to each grouping" do
            assert @grouping1.tas.length == 2
            assert @grouping1.tas.include?(@ta1)
            assert @grouping1.tas.include?(@ta2)
            assert @grouping2.tas.length == 2
            assert @grouping2.tas.include?(@ta1)
            assert @grouping2.tas.include?(@ta2)
          end
          should "not assign assign grader to non-selected groupings" do
            assert @grouping3.tas == []
          end
        end

        context "and multiple graders and multiple groupings are selected" do
          setup do
            @ta3 = Ta.make
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "assign",
              :groupings => [@grouping1, @grouping2, @grouping3],
              :graders => [@ta1, @ta2, @ta3],
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "assign each grader to each grouping" do
            assert @grouping1.tas.length == 3
            assert @grouping1.tas.include?(@ta1)
            assert @grouping1.tas.include?(@ta2)
            assert @grouping1.tas.include?(@ta3)
            assert @grouping2.tas.length == 3
            assert @grouping2.tas.include?(@ta1)
            assert @grouping2.tas.include?(@ta2)
            assert @grouping2.tas.include?(@ta3)
          end
        end

        context "and some graders are already assigned to some groups" do
          setup do
            TaMembership.make(:user => @ta1, :grouping => @grouping2)
            TaMembership.make(:user => @ta2, :grouping => @grouping1)
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "assign",
              :groupings => [@grouping1, @grouping2],
              :graders => [@ta1.id.to_s, @ta2.id.to_s],
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "only assign remaining graders to remaining groupings" do
            assert @grouping1.tas.length == 2
            assert @grouping1.tas.include?(@ta1)
            assert @grouping1.tas.include?(@ta2)
            assert @grouping2.tas.length == 2
            assert @grouping2.tas.include?(@ta1)
            assert @grouping2.tas.include?(@ta2)
          end
          should "not assign assign grader to non-selected groupings" do
            assert @grouping3.tas == []
          end
        end
      end #assign

      context "POST on :global_actions on unassign" do
        setup do
          @grouping1 = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @grouping3 = Grouping.make(:assignment => @assignment)
          @ta1 = Ta.make
          @ta2 = Ta.make
          @ta3 = Ta.make
        end

        context "and no graders or groupings are selected" do
          setup do
            TaMembership.make(:user => @ta1, :grouping => @grouping1)
            TaMembership.make(:user => @ta2, :grouping => @grouping2)
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "unassign",
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "not unassign anything" do
            assert @grouping1.tas == [@ta1]
            assert @grouping2.tas == [@ta2]
            assert @grouping3.tas == []
          end
        end

        context "and all graders from one grouping are selected" do
          setup do
            TaMembership.make(:user => @ta1, :grouping => @grouping1)
            TaMembership.make(:user => @ta2, :grouping => @grouping1)
            TaMembership.make(:user => @ta3, :grouping => @grouping1)
            TaMembership.make(:user => @ta3, :grouping => @grouping3)
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "unassign",
              :groupings => [@grouping1],
              "#{@grouping1.id}_#{@ta1.user_name}" => true,
              "#{@grouping1.id}_#{@ta2.user_name}" => true,
              "#{@grouping1.id}_#{@ta3.user_name}" => true,
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "unassign all groups" do
            assert @grouping1.tas == []
          end
          should "leave other groups as they are" do
            assert @grouping2.tas == []
            assert @grouping3.tas == [@ta3]
          end
        end

        context "and all groupings from one grader are selected" do
          setup do
            TaMembership.make(:user => @ta1, :grouping => @grouping1)
            TaMembership.make(:user => @ta2, :grouping => @grouping1)
            TaMembership.make(:user => @ta3, :grouping => @grouping1)
            TaMembership.make(:user => @ta3, :grouping => @grouping2)
            TaMembership.make(:user => @ta3, :grouping => @grouping3)
            post_as @admin, :global_actions, {:id => @assignment.id,
              :global_actions => "unassign",
              :groupings => [@grouping1, @grouping2, @grouping3],
              "#{@grouping1.id}_#{@ta3.user_name}" => true,
              "#{@grouping2.id}_#{@ta3.user_name}" => true,
              "#{@grouping3.id}_#{@ta3.user_name}" => true,
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "unassign grader from all groups" do
            assert !@grouping1.tas.include?(@ta3)
            assert !@grouping2.tas.include?(@ta3)
            assert !@grouping3.tas.include?(@ta3)
          end
          should "leave other tas as they are" do
            assert @grouping1.tas.include?(@ta1)
            assert @grouping1.tas.include?(@ta2)
          end
        end

        context "and one grader and one grouping is selected where the grader and grouping have other memberships" do
          setup do
            TaMembership.make(:user => @ta1, :grouping => @grouping1)
            TaMembership.make(:user => @ta2, :grouping => @grouping1)
            TaMembership.make(:user => @ta3, :grouping => @grouping1)
            TaMembership.make(:user => @ta1, :grouping => @grouping2)
            TaMembership.make(:user => @ta2, :grouping => @grouping2)
            TaMembership.make(:user => @ta3, :grouping => @grouping2)
            TaMembership.make(:user => @ta1, :grouping => @grouping3)
            TaMembership.make(:user => @ta2, :grouping => @grouping3)
            TaMembership.make(:user => @ta3, :grouping => @grouping3)
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => "unassign",
              :groupings => [@grouping2],
              "#{@grouping2.id}_#{@ta1.user_name}" => true,
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "unassign grader from grouping" do
            assert !@grouping2.tas.include?(@ta1)
          end
          should "leave other tas and groups as they are" do
            assert @grouping1.tas.include?(@ta1)
            assert @grouping1.tas.include?(@ta2)
            assert @grouping1.tas.include?(@ta3)
            assert @grouping2.tas.include?(@ta2)
            assert @grouping2.tas.include?(@ta3)
            assert @grouping3.tas.include?(@ta1)
            assert @grouping3.tas.include?(@ta2)
            assert @grouping3.tas.include?(@ta3)
          end
        end

        context "and multiple graders and multiple groupings are selected" do
          setup do
            TaMembership.make(:user => @ta1, :grouping => @grouping1)
            TaMembership.make(:user => @ta2, :grouping => @grouping1)
            TaMembership.make(:user => @ta3, :grouping => @grouping1)
            TaMembership.make(:user => @ta1, :grouping => @grouping2)
            TaMembership.make(:user => @ta2, :grouping => @grouping2)
            TaMembership.make(:user => @ta3, :grouping => @grouping2)
            TaMembership.make(:user => @ta1, :grouping => @grouping3)
            TaMembership.make(:user => @ta2, :grouping => @grouping3)
            TaMembership.make(:user => @ta3, :grouping => @grouping3)
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => "unassign",
              :groupings => [@grouping1, @grouping2, @grouping3],
              "#{@grouping1.id}_#{@ta1.user_name}" => true,
              "#{@grouping1.id}_#{@ta2.user_name}" => true,
              "#{@grouping1.id}_#{@ta3.user_name}" => true,
              "#{@grouping2.id}_#{@ta1.user_name}" => true,
              "#{@grouping2.id}_#{@ta2.user_name}" => true,
              "#{@grouping2.id}_#{@ta3.user_name}" => true,
              "#{@grouping3.id}_#{@ta1.user_name}" => true,
              "#{@grouping3.id}_#{@ta2.user_name}" => true,
              "#{@grouping3.id}_#{@ta3.user_name}" => true,
              :current_table => "groups_table"}
          end
          should respond_with :success
          should "unassign all graders from all groupings" do
            assert @grouping1.tas == []
            assert @grouping2.tas == []
            assert @grouping3.tas == []
          end
        end
      end #unassign

    end #groupings table

    context "With criteria table selected" do
      context "with rubric marking scheme doing a" do
        context "POST on :global_actions on random_assign" do
          setup do
            @criterion1 = RubricCriterion.make(:assignment => @assignment)
            @criterion2 = RubricCriterion.make(:assignment => @assignment)
            @criterion3 = RubricCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          context "and no graders selected" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "random_assign", :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and no criteria selected, at least one grader" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "random_assign", :graders => [@ta1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and no graders are selected, at least one criterion" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "random_assign", :criteria => [@criterion1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and one grader and one criterion is selected" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "random_assign", :criteria => [@criterion1],
                :graders => [@ta1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign grader to criterion" do
              assert @criterion1.tas[0].id == @ta1.id
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion2.tas == []
              assert @criterion3.tas == []
            end
          end

          context "and one grader and multiple criteria are selected" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "random_assign",
                :criteria => [@criterion1, @criterion2],
                :graders => [@ta1],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign grader to all criteria" do
              assert @criterion1.tas[0].id == @ta1.id
              assert @criterion2.tas[0].id == @ta1.id
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion3.tas == []
            end
          end

          context "and two graders and one criterion is selected" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "random_assign",
                :criteria => [@criterion1],
                :graders => [@ta1, @ta2],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign one of the graders to the criterion" do
              assert((@criterion1.tas[0].id == @ta1.id or @criterion1.tas[0].id == @ta2.id))
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion2.tas == []
              assert @criterion3.tas == []
            end
          end

          context "and two graders and two criteria are selected" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "random_assign",
                :criteria => [@criterion1, @criterion2],
                :graders => [@ta1, @ta2],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign one of the graders to each criterion" do
              assert((@criterion1.tas[0].id == @ta1.id or @criterion1.tas[0].id == @ta2.id))
              assert ((@criterion2.tas[0].id == @ta1.id or @criterion2.tas[0].id == @ta2.id))
              assert @criterion1.tas[0].id != @criterion2.tas[0].id
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion3.tas == []
            end
          end

          context "and multiple graders and multiple criteria are selected" do
            setup do
              @ta3 = Ta.make
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "random_assign",
                :criteria => [@criterion1, @criterion2, @criterion3],
                :graders => [@ta1, @ta2, @ta3],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign exactly one grader to each criterion" do
              assert @criterion1.tas.size == 1
              assert @criterion2.tas.size == 1
              assert @criterion3.tas.size == 1
            end
          end
        end #random assign

        context "POST on :global_actions on assign" do
          setup do
            @criterion1 = RubricCriterion.make(:assignment => @assignment)
            @criterion2 = RubricCriterion.make(:assignment => @assignment)
            @criterion3 = RubricCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          context "and no graders selected" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "assign", :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and no criteria selected, at least one grader" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "assign", :graders => [@ta1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and no graders are selected, at least one criterion" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "assign", :criteria => [@criterion1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and one grader and one criterion is selected" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "assign", :criteria => [@criterion1],
                :graders => [@ta1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign grader to criterion" do
              assert @criterion1.tas[0].id == @ta1.id
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion2.tas == []
              assert @criterion3.tas == []
            end
          end

          context "and one grader and two criteria are selected" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "assign",
                :criteria => [@criterion1, @criterion2],
                :graders => [@ta1],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign grader to all criteria" do
              assert @criterion1.tas[0].id == @ta1.id
              assert @criterion2.tas[0].id == @ta1.id
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion3.tas == []
            end
          end

          context "and two graders and one criterion is selected" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "assign",
                :criteria => [@criterion1],
                :graders => [@ta1, @ta2],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign both graders to each criterion" do
              assert @criterion1.tas.length == 2
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion2.tas == []
              assert @criterion3.tas == []
            end
          end

          context "and two graders and two criteria are selected" do
            setup do
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "assign",
                :criteria => [@criterion1, @criterion2],
                :graders => [@ta1, @ta2],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign both graders to each criterion" do
              assert @criterion1.tas.length == 2
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
              assert @criterion2.tas.length == 2
              assert @criterion2.tas.include?(@ta1)
              assert @criterion2.tas.include?(@ta2)
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion3.tas == []
            end
          end

          context "and multiple graders and multiple criteria are selected" do
            setup do
              @ta3 = Ta.make
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "assign",
                :criteria => [@criterion1, @criterion2, @criterion3],
                :graders => [@ta1, @ta2, @ta3],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign each grader to each criterion" do
              assert @criterion1.tas.length == 3
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
              assert @criterion1.tas.include?(@ta3)
              assert @criterion2.tas.length == 3
              assert @criterion2.tas.include?(@ta1)
              assert @criterion2.tas.include?(@ta2)
              assert @criterion2.tas.include?(@ta3)
            end
          end

          context "and some graders are already assigned to some criteria" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "assign",
                :criteria => [@criterion1, @criterion2],
                :graders => [@ta1, @ta2],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "only assign remaining graders to remaining criteria" do
              @criterion1.reload
              @criterion2.reload
              @criterion3.reload
              assert @criterion1.tas.length == 2
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
              assert @criterion2.tas.length == 2
              assert @criterion2.tas.include?(@ta1)
              assert @criterion2.tas.include?(@ta2)
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion3.tas == []
            end
          end
        end #assign

        context "POST on :global_actions on unassign" do
          setup do
            @criterion1 = RubricCriterion.make(:assignment => @assignment)
            @criterion2 = RubricCriterion.make(:assignment => @assignment)
            @criterion3 = RubricCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          context "and no graders or criteria are selected" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion2)
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "unassign",
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not unassign anything" do
              @criterion1.reload
              @criterion2.reload
              @criterion3.reload
              assert @criterion1.tas == [@ta1]
              assert @criterion2.tas == [@ta2]
              assert @criterion3.tas == []
            end
          end

          context "and all graders from one criterion are selected" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "unassign",
                :criteria => [@criterion1],
                "#{@criterion1.id}_#{@ta1.user_name}" => true,
                "#{@criterion1.id}_#{@ta2.user_name}" => true,
                "#{@criterion1.id}_#{@ta3.user_name}" => true,
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "unassign all criteria" do
              @criterion1.reload
              assert @criterion1.tas == []
            end
            should "leave other criteria as they are" do
              @criterion2.reload
              @criterion3.reload
              assert @criterion2.tas == []
              assert @criterion3.tas == [@ta3]
            end
          end

          context "and all criteria from one grader are selected" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "unassign",
                :criteria => [@criterion1, @criterion2, @criterion3],
                "#{@criterion1.id}_#{@ta3.user_name}" => true,
                "#{@criterion2.id}_#{@ta3.user_name}" => true,
                "#{@criterion3.id}_#{@ta3.user_name}" => true,
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "unassign grader from all criteria" do
              @criterion1.reload
              @criterion2.reload
              @criterion3.reload
              assert !@criterion1.tas.include?(@ta3)
              assert !@criterion2.tas.include?(@ta3)
              assert !@criterion3.tas.include?(@ta3)
            end
            should "leave other tas as they are" do
              @criterion1.reload
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
            end
          end

          context "and one grader and one criterion is selected where the grader and criterion have other memberships" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion3)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion3)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
              post_as @admin, :global_actions, {:assignment_id => @assignment.id,
                :global_actions => "unassign",
                :criteria => [@criterion2],
                "#{@criterion2.id}_#{@ta1.user_name}" => true,
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "unassign grader from criterion" do
              assert !@criterion2.tas.include?(@ta1)
            end
            should "leave other tas and criteria as they are" do
              @criterion1.reload
              @criterion2.reload
              @criterion3.reload
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
              assert @criterion1.tas.include?(@ta3)
              assert @criterion2.tas.include?(@ta2)
              assert @criterion2.tas.include?(@ta3)
              assert @criterion3.tas.include?(@ta1)
              assert @criterion3.tas.include?(@ta2)
              assert @criterion3.tas.include?(@ta3)
            end
          end

          context "and multiple graders and multiple criteria are selected" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion3)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion3)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "unassign",
                :criteria => [@criterion1, @criterion2, @criterion3],
                "#{@criterion1.id}_#{@ta1.user_name}" => true,
                "#{@criterion1.id}_#{@ta2.user_name}" => true,
                "#{@criterion1.id}_#{@ta3.user_name}" => true,
                "#{@criterion2.id}_#{@ta1.user_name}" => true,
                "#{@criterion2.id}_#{@ta2.user_name}" => true,
                "#{@criterion2.id}_#{@ta3.user_name}" => true,
                "#{@criterion3.id}_#{@ta1.user_name}" => true,
                "#{@criterion3.id}_#{@ta2.user_name}" => true,
                "#{@criterion3.id}_#{@ta3.user_name}" => true,
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "unassign all graders from all criteria" do
              assert @criterion1.tas == []
              assert @criterion2.tas == []
              assert @criterion3.tas == []
            end
          end
        end #unassign

      end #rubric scheme
      context "with flexible marking scheme doing a" do
        setup do
          @assignment = Assignment.make(:marking_scheme_type => "flexible")
        end
        context "POST on :global_actions on random_assign" do
          setup do
            @criterion1 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion2 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion3 = FlexibleCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          context "and no graders selected" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "random_assign", :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and no criteria selected, at least one grader" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "random_assign", :graders => [@ta1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and no graders are selected, at least one criterion" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "random_assign", :criteria => [@criterion1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and one grader and one criterion is selected" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "random_assign", :criteria => [@criterion1],
                :graders => [@ta1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign grader to criterion" do
              assert @criterion1.tas[0].id == @ta1.id
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion2.tas == []
              assert @criterion3.tas == []
            end
          end

          context "and one grader and multiple criteria are selected" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "random_assign",
                :criteria => [@criterion1, @criterion2],
                :graders => [@ta1],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign grader to all criteria" do
              assert @criterion1.tas[0].id == @ta1.id
              assert @criterion2.tas[0].id == @ta1.id
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion3.tas == []
            end
          end

          context "and two graders and one criterion is selected" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "random_assign",
                :criteria => [@criterion1],
                :graders => [@ta1, @ta2],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign one of the graders to the criterion" do
              assert((@criterion1.tas[0].id == @ta1.id or @criterion1.tas[0].id == @ta2.id))
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion2.tas == []
              assert @criterion3.tas == []
            end
          end

          context "and two graders and two criteria are selected" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "random_assign",
                :criteria => [@criterion1, @criterion2],
                :graders => [@ta1, @ta2],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign one of the graders to each criterion" do
              assert((@criterion1.tas[0].id == @ta1.id or @criterion1.tas[0].id == @ta2.id))
              assert((@criterion2.tas[0].id == @ta1.id or @criterion2.tas[0].id == @ta2.id))
              assert @criterion1.tas[0].id != @criterion2.tas[0].id
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion3.tas == []
            end
          end

          context "and multiple graders and multiple criteria are selected" do
            setup do
              @ta3 = Ta.make
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "random_assign",
                :criteria => [@criterion1, @criterion2, @criterion3],
                :graders => [@ta1, @ta2, @ta3],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign exactly one grader to each criterion" do
              assert @criterion1.tas.size == 1
              assert @criterion2.tas.size == 1
              assert @criterion3.tas.size == 1
            end
          end
        end #random assign

        context "POST on :global_actions on assign" do
          setup do
            @criterion1 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion2 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion3 = FlexibleCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          context "and no graders selected" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "assign", :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and no criteria selected, at least one grader" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "assign", :graders => [@ta1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and no graders are selected, at least one criterion" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "assign", :criteria => [@criterion1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not assign anything" do
              @assignment.get_criteria do |criterion|
                assert criterion.tas == []
              end
            end
          end

          context "and one grader and one criterion is selected" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "assign", :criteria => [@criterion1],
                :graders => [@ta1], :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign grader to criterion" do
              assert @criterion1.tas[0].id == @ta1.id
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion2.tas == []
              assert @criterion3.tas == []
            end
          end

          context "and one grader and two criteria are selected" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "assign",
                :criteria => [@criterion1, @criterion2],
                :graders => [@ta1],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign grader to all criteria" do
              assert @criterion1.tas[0].id == @ta1.id
              assert @criterion2.tas[0].id == @ta1.id
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion3.tas == []
            end
          end

          context "and two graders and one criterion is selected" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "assign",
                :criteria => [@criterion1],
                :graders => [@ta1, @ta2],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign both graders to each criterion" do
              assert @criterion1.tas.length == 2
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion2.tas == []
              assert @criterion3.tas == []
            end
          end

          context "and two graders and two criteria are selected" do
            setup do
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "assign",
                :criteria => [@criterion1, @criterion2],
                :graders => [@ta1, @ta2],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign both graders to each criterion" do
              assert @criterion1.tas.length == 2
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
              assert @criterion2.tas.length == 2
              assert @criterion2.tas.include?(@ta1)
              assert @criterion2.tas.include?(@ta2)
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion3.tas == []
            end
          end

          context "and multiple graders and multiple criteria are selected" do
            setup do
              @ta3 = Ta.make
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "assign",
                :criteria => [@criterion1, @criterion2, @criterion3],
                :graders => [@ta1, @ta2, @ta3],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "assign each grader to each criterion" do
              assert @criterion1.tas.length == 3
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
              assert @criterion1.tas.include?(@ta3)
              assert @criterion2.tas.length == 3
              assert @criterion2.tas.include?(@ta1)
              assert @criterion2.tas.include?(@ta2)
              assert @criterion2.tas.include?(@ta3)
            end
          end

          context "and some graders are already assigned to some criteria" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "assign",
                :criteria => [@criterion1, @criterion2],
                :graders => [@ta1, @ta2],
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "only assign remaining graders to remaining criteria" do
              @criterion1.reload
              @criterion2.reload
              assert @criterion1.tas.length == 2
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
              assert @criterion2.tas.length == 2
              assert @criterion2.tas.include?(@ta1)
              assert @criterion2.tas.include?(@ta2)
            end
            should "not assign assign grader to non-selected criteria" do
              assert @criterion3.tas == []
            end
          end
        end #assign

        context "POST on :global_actions on unassign" do
          setup do
            @criterion1 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion2 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion3 = FlexibleCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          context "and no graders or criteria are selected" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion2)
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "unassign",
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "not unassign anything" do
              @criterion1.reload
              @criterion2.reload
              @criterion3.reload
              assert @criterion1.tas == [@ta1]
              assert @criterion2.tas == [@ta2]
              assert @criterion3.tas == []
            end
          end

          context "and all graders from one criterion are selected" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "unassign",
                :criteria => [@criterion1],
                "#{@criterion1.id}_#{@ta1.user_name}" => true,
                "#{@criterion1.id}_#{@ta2.user_name}" => true,
                "#{@criterion1.id}_#{@ta3.user_name}" => true,
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "unassign all criteria" do
              @criterion1.reload
              assert @criterion1.tas == []
            end
            should "leave other criteria as they are" do
              @criterion2.reload
              @criterion3.reload
              assert @criterion2.tas == []
              assert @criterion3.tas == [@ta3]
            end
          end

          context "and all criteria from one grader are selected" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "unassign",
                :criteria => [@criterion1, @criterion2, @criterion3],
                "#{@criterion1.id}_#{@ta3.user_name}" => true,
                "#{@criterion2.id}_#{@ta3.user_name}" => true,
                "#{@criterion3.id}_#{@ta3.user_name}" => true,
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "unassign grader from all criteria" do
              @criterion1.reload
              @criterion2.reload
              @criterion3.reload
              assert !@criterion1.tas.include?(@ta3)
              assert !@criterion2.tas.include?(@ta3)
              assert !@criterion3.tas.include?(@ta3)
            end
            should "leave other tas as they are" do
              @criterion1.reload
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
            end
          end

          context "and one grader and one criterion is selected where the grader and criterion have other memberships" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion3)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion3)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "unassign",
                :criteria => [@criterion2],
                "#{@criterion2.id}_#{@ta1.user_name}" => true,
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "unassign grader from criterion" do
              @criterion2.reload
              assert !@criterion2.tas.include?(@ta1)
            end
            should "leave other tas and criteria as they are" do
              @criterion1.reload
              @criterion2.reload
              @criterion3.reload
              assert @criterion1.tas.include?(@ta1)
              assert @criterion1.tas.include?(@ta2)
              assert @criterion1.tas.include?(@ta3)
              assert @criterion2.tas.include?(@ta2)
              assert @criterion2.tas.include?(@ta3)
              assert @criterion3.tas.include?(@ta1)
              assert @criterion3.tas.include?(@ta2)
              assert @criterion3.tas.include?(@ta3)
            end
          end

          context "and multiple graders and multiple criteria are selected" do
            setup do
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion1)
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion2)
              CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion3)
              CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion3)
              CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
              post_as @admin, :global_actions, {:id => @assignment.id,
                :global_actions => "unassign",
                :criteria => [@criterion1, @criterion2, @criterion3],
                "#{@criterion1.id}_#{@ta1.user_name}" => true,
                "#{@criterion1.id}_#{@ta2.user_name}" => true,
                "#{@criterion1.id}_#{@ta3.user_name}" => true,
                "#{@criterion2.id}_#{@ta1.user_name}" => true,
                "#{@criterion2.id}_#{@ta2.user_name}" => true,
                "#{@criterion2.id}_#{@ta3.user_name}" => true,
                "#{@criterion3.id}_#{@ta1.user_name}" => true,
                "#{@criterion3.id}_#{@ta2.user_name}" => true,
                "#{@criterion3.id}_#{@ta3.user_name}" => true,
                :current_table => "criteria_table"}
            end
            should respond_with :success
            should "unassign all graders from all criteria" do
              assert @criterion1.tas == []
              assert @criterion2.tas == []
              assert @criterion3.tas == []
            end
          end
        end #unassign

      end #flexible scheme
    end #criteria table

  end #admin context
end
