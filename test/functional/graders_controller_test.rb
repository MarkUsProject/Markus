require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'
require 'mocha/setup'

class GradersControllerTest < AuthenticatedControllerTest

  context 'An authenticated and authorized student doing a ' do

    setup do
      @student = Student.make
    end

    should 'GET on :upload_dialog' do
      get_as @student, :upload_dialog, :assignment_id => 1
      assert_response :missing
    end

    should 'GET on :download_dialog' do
      get_as @student, :download_dialog, :assignment_id => 1
      assert_response :missing
    end

    should 'GET on :groups_coverage_dialog' do
      get_as @student, :groups_coverage_dialog, :assignment_id => 1
      assert_response :missing
    end

    should 'GET on :grader_criteria_dialog' do
      get_as @student, :grader_criteria_dialog, :assignment_id => 1
      assert_response :missing
    end

    should 'GET on :populate' do
      get_as @student, :populate, :assignment_id => 1
      assert_response :missing
    end

    should 'GET on :populate_graders' do
      get_as @student, :populate_graders, :assignment_id => 1
      assert_response :missing
    end

    should 'GET on :populate_criteria' do
      get_as @student, :populate_criteria, :assignment_id => 1
      assert_response :missing
    end

    should 'GET on :set_assign_criteria' do
      get_as @student, :set_assign_criteria, :assignment_id => 1
      assert_response :missing
    end

    should 'GET on :index' do
      get_as @student, :index, :assignment_id => 1
      assert_response :missing
    end

    should 'GET on :csv_upload_grader_groups_mapping' do
      get_as @student, :csv_upload_grader_groups_mapping, :assignment_id => 1
      assert_response :missing
    end

    should 'GET on :add_grader_to_grouping' do
      get_as @student, :add_grader_to_grouping, :assignment_id => 1
      assert_response :missing
    end

    should 'GET on :global_actions' do
      get_as @student, :global_actions, :assignment_id => 1
      assert_response :missing
    end

    should 'POST on :upload_dialog' do
      post_as @student, :upload_dialog, :assignment_id => 1
      assert_response :missing
    end

    should 'POST on :download_dialog' do
      post_as @student, :download_dialog, :assignment_id => 1
      assert_response :missing
    end

    should 'POST on :groups_coverage_dialog' do
      post_as @student, :groups_coverage_dialog, :assignment_id => 1
      assert_response :missing
    end

    should 'POST on :grader_criteria_dialog' do
      post_as @student, :grader_criteria_dialog, :assignment_id => 1
      assert_response :missing
    end

    should 'POST on :populate' do
      post_as @student, :populate, :assignment_id => 1
      assert_response :missing
    end

    should 'POST on :populate_graders' do
      post_as @student, :populate_graders, :assignment_id => 1
      assert_response :missing
    end

    should 'POST on :populate_criteria' do
      post_as @student, :populate_criteria, :assignment_id => 1
      assert_response :missing
    end

    should 'POST on :set_assign_criteria' do
      post_as @student, :set_assign_criteria, :assignment_id => 1
      assert_response :missing
    end

    should 'POST on :csv_upload_grader_groups_mapping' do
      post_as @student, :csv_upload_grader_groups_mapping, :assignment_id => 1
      assert_response :missing
    end

    should 'POST on :add_grader_to_grouping' do
      post_as @student, :add_grader_to_grouping, :assignment_id => 1
      assert_response :missing
    end

    should 'POST on :global_actions' do
      post_as @student, :global_actions, :assignment_id => 1
      assert_response :missing
    end

  end #student context

  context 'An authenticated and authorized admin' do

    setup do
      @admin = Admin.make
      @assignment = Assignment.make(:marking_scheme_type => 'rubric')
    end

    should 'doing a GET on :index(graders_controller)' do
      get_as @admin, :index, {:assignment_id => @assignment.id}
      assert_response :success
      assert_not_nil assigns :assignment
    end #manage

    context 'doing a POST on :set_assign_criteria' do

      should 'and value is true' do
        post_as @admin, :set_assign_criteria, {:assignment_id => @assignment.id,
          :value => 'true'}
        assert_response :success
        @assignment.reload
        assert @assignment.assign_graders_to_criteria
      end

      should 'and value is nil' do
        post_as @admin, :set_assign_criteria, {:assignment_id => @assignment.id}
        assert_response :success
        @assignment.reload
        assert !@assignment.assign_graders_to_criteria
      end
    end

    context 'doing a POST on :csv_upload_grader_groups_mapping' do

      setup do
        # Contents: test_group,g9browni,g9younas
        #           second_test_group,g9browni
        #           Group 3,c7benjam
        @group_grader_map_file = fixture_file_upload(
                                    File.join('group_csvs',
                                              'group_grader_map.csv'))
      end

      should 'and all graders and groups are valid' do
        @ta1 = Ta.make(:user_name => 'g9browni')
        @ta2 = Ta.make(:user_name => 'g9younas')
        @ta3 = Ta.make(:user_name => 'c7benjam')
        @grouping1 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => 'test_group'))
        @grouping2 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => 'second_test_group'))
        @grouping3 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => 'Group 3'))
        post_as @admin, :csv_upload_grader_groups_mapping, {
            :assignment_id => @assignment.id,
            :grader_mapping => @group_grader_map_file}

        assert_response :redirect
        assert @grouping1.tas.count == 2
        assert @grouping1.tas.include? @ta1
        assert @grouping1.tas.include? @ta2
        assert @grouping2.tas.count == 1
        assert @grouping2.tas.include? @ta1
        assert @grouping3.tas.count == 1
        assert @grouping3.tas.include? @ta3
        assert_recognizes({:controller => 'graders', :assignment_id => '1', :action => 'csv_upload_grader_groups_mapping' },
          {:path => 'assignments/1/graders/csv_upload_grader_groups_mapping', :method => :post})
      end

      should 'and some graders are invalid' do
        @ta1 = Ta.make(:user_name => 'g9browni')
        @ta2 = Ta.make(:user_name => 'g9younas')
        @ta3 = Ta.make(:user_name => 'c0curtis')
        @grouping1 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => 'test_group'))
        @grouping2 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => 'second_test_group'))
        @grouping3 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => 'Group 3'))
        post_as @admin, :csv_upload_grader_groups_mapping, {
            :assignment_id => @assignment.id,
            :grader_mapping => @group_grader_map_file}

        assert_response :redirect
        assert @grouping1.tas.count == 2
        assert @grouping1.tas.include? @ta1
        assert @grouping1.tas.include? @ta2
        assert @grouping2.tas.count == 1
        assert @grouping2.tas.include? @ta1
        assert @grouping3.tas.count == 0
      end

      should 'and some groupings are invalid' do
        @ta1 = Ta.make(:user_name => 'g9browni')
        @ta2 = Ta.make(:user_name => 'g9younas')
        @ta3 = Ta.make(:user_name => 'c7benjam')
        @grouping1 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => 'Group of 7'))
        @grouping2 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => 'second_test_group'))
        @grouping3 = Grouping.make(:assignment => @assignment, :group => Group.make(:group_name => 'Group 3'))
        post_as @admin, :csv_upload_grader_groups_mapping, {
            :assignment_id => @assignment.id,
            :grader_mapping => @group_grader_map_file}

        assert_response :redirect
        assert @grouping1.tas.count == 0
        assert @grouping2.tas.count == 1
        assert @grouping2.tas.include? @ta1
        assert @grouping3.tas.count == 1
        assert @grouping3.tas.include? @ta3
      end
    end #groups csv upload

    context 'doing a POST on :csv_upload_grader_criteria_mapping' do

      setup do
        # Contents: correctness,g9browni,g9younas
        #           style,g9browni
        #           class design,c7benjam
        @ctieria_grader_map_file = fixture_file_upload(
                                      File.join('group_csvs',
                                                'criteria_grader_map.csv'))
      end

      context 'with rubric criteria' do
        setup do
          @assignment = Assignment.make(:marking_scheme_type => 'rubric', :assign_graders_to_criteria => true)
        end

        should 'and all graders and criteria are valid' do
          @ta1 = Ta.make(:user_name => 'g9browni')
          @ta2 = Ta.make(:user_name => 'g9younas')
          @ta3 = Ta.make(:user_name => 'c7benjam')
          @criterion1 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => 'correctness')
          @criterion2 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => 'style')
          @criterion3 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => 'class design')
          post_as @admin, :csv_upload_grader_criteria_mapping, {
              :assignment_id => @assignment.id,
              :grader_criteria_mapping => @ctieria_grader_map_file}

          assert_response :redirect
          assert @criterion1.tas.count == 2
          assert @criterion1.tas.include? @ta1
          assert @criterion1.tas.include? @ta2
          assert @criterion2.tas.count == 1
          assert @criterion2.tas.include? @ta1
          assert @criterion3.tas.count == 1
          assert @criterion3.tas.include? @ta3
          assert_recognizes({:controller => 'graders', :assignment_id => '1', :action => 'csv_upload_grader_criteria_mapping' },
            {:path => 'assignments/1/graders/csv_upload_grader_criteria_mapping', :method => :post})
        end

        should 'and some graders are invalid' do
          @ta1 = Ta.make(:user_name => 'g9browni')
          @ta2 = Ta.make(:user_name => 'reid')
          @ta3 = Ta.make(:user_name => 'c7benjam')
          @criterion1 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => 'correctness')
          @criterion2 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => 'style')
          @criterion3 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => 'class design')
          post_as @admin, :csv_upload_grader_criteria_mapping, {
              :assignment_id => @assignment.id,
              :grader_criteria_mapping => @ctieria_grader_map_file}

          assert_response :redirect
          assert @criterion1.tas.count == 1
          assert @criterion1.tas.include? @ta1
          assert @criterion2.tas.count == 1
          assert @criterion2.tas.include? @ta1
          assert @criterion3.tas.count == 1
          assert @criterion3.tas.include? @ta3
        end

        should 'and some criteria are invalid' do
          @ta1 = Ta.make(:user_name => 'g9browni')
          @ta2 = Ta.make(:user_name => 'g9younas')
          @ta3 = Ta.make(:user_name => 'c7benjam')
          @criterion1 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => 'correctness')
          @criterion2 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => "professor's whim")
          @criterion3 = RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => 'class design')
          post_as @admin, :csv_upload_grader_criteria_mapping, {
              :assignment_id => @assignment.id,
              :grader_criteria_mapping => @ctieria_grader_map_file}

          assert_response :redirect
          assert @criterion1.tas.count == 2
          assert @criterion1.tas.include? @ta1
          assert @criterion2.tas.count == 0
          assert @criterion3.tas.count == 1
          assert @criterion3.tas.include? @ta3
        end
      end # rubric criteria

      context 'with flexible criteria' do
        setup do
          @assignment = Assignment.make(:marking_scheme_type => 'flexible', :assign_graders_to_criteria => true)
        end

        should 'and all graders and criteria are valid' do
          @ta1 = Ta.make(:user_name => 'g9browni')
          @ta2 = Ta.make(:user_name => 'g9younas')
          @ta3 = Ta.make(:user_name => 'c7benjam')
          @criterion1 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => 'correctness')
          @criterion2 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => 'style')
          @criterion3 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => 'class design')
          post_as @admin, :csv_upload_grader_criteria_mapping, {
              :assignment_id => @assignment.id,
              :grader_criteria_mapping => @ctieria_grader_map_file}

          assert_response :redirect
          assert @criterion1.tas.count == 2
          assert @criterion1.tas.include? @ta1
          assert @criterion1.tas.include? @ta2
          assert @criterion2.tas.count == 1
          assert @criterion2.tas.include? @ta1
          assert @criterion3.tas.count == 1
          assert @criterion3.tas.include? @ta3
        end

        should 'and some graders are invalid' do
          @ta1 = Ta.make(:user_name => 'g9browni')
          @ta2 = Ta.make(:user_name => 'reid')
          @ta3 = Ta.make(:user_name => 'c7benjam')
          @criterion1 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => 'correctness')
          @criterion2 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => 'style')
          @criterion3 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => 'class design')
          post_as @admin, :csv_upload_grader_criteria_mapping, {
              :assignment_id => @assignment.id,
              :grader_criteria_mapping => @ctieria_grader_map_file}

          assert_response :redirect
          assert @criterion1.tas.count == 1
          assert @criterion1.tas.include? @ta1
          assert @criterion2.tas.count == 1
          assert @criterion2.tas.include? @ta1
          assert @criterion3.tas.count == 1
          assert @criterion3.tas.include? @ta3
        end

        should 'and some criteria are invalid' do
          @ta1 = Ta.make(:user_name => 'g9browni')
          @ta2 = Ta.make(:user_name => 'g9younas')
          @ta3 = Ta.make(:user_name => 'c7benjam')
          @criterion1 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => 'correctness')
          @criterion2 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => "professor's whim")
          @criterion3 = FlexibleCriterion.make(:assignment => @assignment, :flexible_criterion_name => 'class design')
          post_as @admin, :csv_upload_grader_criteria_mapping, {
              :assignment_id => @assignment.id,
              :grader_criteria_mapping => @ctieria_grader_map_file}

          assert_response :redirect
          assert @criterion1.tas.count == 2
          assert @criterion1.tas.include? @ta1
          assert @criterion2.tas.count == 0
          assert @criterion3.tas.count == 1
          assert @criterion3.tas.include? @ta3
        end
      end # flexible criteria
    end # criteria csv upload

    context 'doing a GET on :download_grader_groupings_mapping' do
      setup do
        @assignment = Assignment.make(:marking_scheme_type => 'rubric', :assign_graders_to_criteria => true)
      end

      should 'routing properly' do
          post_as @admin, :download_grader_groupings_mapping,
                          :assignment_id => @assignment.id
          assert_response :success
          assert_recognizes({:controller => 'graders', :assignment_id => '1', :action => 'download_grader_groupings_mapping' },
            {:path => 'assignments/1/graders/download_grader_groupings_mapping', :method => :get})
      end
    end

    context 'doing a GET on :download_grader_criteria_mapping' do
      setup do
        @assignment = Assignment.make(:marking_scheme_type => 'rubric', :assign_graders_to_criteria => true)
      end

      should 'routing properly' do
          post_as @admin, :download_grader_criteria_mapping,
                          :assignment_id => @assignment.id
          assert_response :success
          assert_recognizes({:controller => 'graders', :assignment_id => '1', :action => 'download_grader_criteria_mapping' },
            {:path => 'assignments/1/graders/download_grader_criteria_mapping', :method => :get})
      end
    end

    should 'doing a POST on :add_grader_to_grouping' do
        @grouping = Grouping.make(:assignment => @assignment)
        @grouping2 = Grouping.make(:assignment => @assignment)
        @ta = Ta.make
        @ta2 = Ta.make
        post_as @admin, :add_grader_to_grouping, {:assignment_id => @assignment.id,
            :grouping_id => @grouping.id,
            :grader_id => @ta.id}
        assert_response :success
        assert @grouping.tas[0].id == @ta.id
        assert @grouping.tas.count == 1
        assert @ta.memberships.count == 1
    end

    context 'with groups table selected doing a' do

      context 'POST on :global_actions on random_assign' do
        setup do
          @grouping1 = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @grouping3 = Grouping.make(:assignment => @assignment)
          @ta1 = Ta.make
          @ta2 = Ta.make
          @ta3 = Ta.make
        end

        should 'and no graders selected' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'random_assign', :current_table => 'groups_table'}
          assert_response :success
          @assignment.groupings do |grouping|
            assert grouping.tas == []
          end
        end

        should 'and no groups selected, at least one grader' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'random_assign', :graders => [@ta1], :current_table => 'groups_table'}
          assert_response :success
          @assignment.groupings do |grouping|
            assert grouping.tas == []
          end
        end

        should 'and no graders are selected, at least one grouping' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'random_assign', :groupings => [@grouping1], :current_table => 'groups_table'}
          assert_response :success
          @assignment.groupings do |grouping|
            assert grouping.tas == []
          end
        end

        should 'and one grader and one grouping is selected' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'random_assign', :groupings => [@grouping1],
            :graders => [@ta1], :current_table => 'groups_table'}
          assert_response :success
          assert @grouping1.tas[0].id == @ta1.id
          assert @grouping2.tas == []
          assert @grouping3.tas == []
        end

        should 'and one grader and multiple groupings are selected' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'random_assign',
            :groupings => [@grouping1, @grouping2],
            :graders => [@ta1],
            :current_table => 'groups_table'}
          assert_response :success
          assert @grouping1.tas[0].id == @ta1.id
          assert @grouping2.tas[0].id == @ta1.id
          assert @grouping3.tas == []
        end

        should 'and two graders and one grouping is selected' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'random_assign',
            :groupings => [@grouping1],
            :graders => [@ta1, @ta2],
            :current_table => 'groups_table'}
          assert_response :success
          assert((@grouping1.tas[0].id == @ta1.id or @grouping1.tas[0].id == @ta2.id))
          assert @grouping2.tas == []
          assert @grouping3.tas == []
        end

        should 'and two graders and two groupings are selected' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'random_assign',
            :groupings => [@grouping1, @grouping2],
            :graders => [@ta1, @ta2],
            :current_table => 'groups_table'}
          assert_response :success
          assert((@grouping1.tas[0].id == @ta1.id or @grouping1.tas[0].id == @ta2.id))
          assert((@grouping2.tas[0].id == @ta1.id or @grouping2.tas[0].id == @ta2.id))
          assert @grouping1.tas[0].id != @grouping2.tas[0].id
          assert @grouping3.tas == []
        end

        should 'and multiple graders and multiple groupings are selected' do
          @ta3 = Ta.make
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'random_assign',
            :groupings => [@grouping1, @grouping2, @grouping3],
            :graders => [@ta1, @ta2, @ta3],
            :current_table => 'groups_table'}
          assert_response :success
          assert @grouping1.tas.size == 1
          assert @grouping2.tas.size == 1
          assert @grouping3.tas.size == 1
        end
      end #random assign

      context 'POST on :global_actions on assign' do
        setup do
          @grouping1 = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @grouping3 = Grouping.make(:assignment => @assignment)
          @ta1 = Ta.make
          @ta2 = Ta.make
          @ta3 = Ta.make
        end

        should 'and no graders selected' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'assign', :current_table => 'groups_table'}
          assert_response :success
          @assignment.groupings do |grouping|
            assert grouping.tas == []
          end
        end

        should 'and no groupings selected, at least one grader' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'assign', :graders => [@ta1], :current_table => 'groups_table'}
          assert_response :success
          @assignment.groupings do |grouping|
            assert grouping.tas == []
          end
        end

        should 'and no graders are selected, at least one grouping' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'assign', :groupings => [@grouping1], :current_table => 'groups_table'}
          assert_response :success
          @assignment.groupings do |grouping|
            assert grouping.tas == []
          end
        end

        should 'and one grader and one grouping is selected' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'assign', :groupings => [@grouping1],
            :graders => [@ta1], :current_table => 'groups_table'}
          assert_response :success
          assert @grouping1.tas[0].id == @ta1.id
          assert @grouping2.tas == []
          assert @grouping3.tas == []
        end

        should 'and one grader and two groupings are selected' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'assign',
            :groupings => [@grouping1, @grouping2],
            :graders => [@ta1],
            :current_table => 'groups_table'}
          assert_response :success
          assert @grouping1.tas[0].id == @ta1.id
          assert @grouping2.tas[0].id == @ta1.id
          assert @grouping3.tas == []
        end

        should 'and two graders and one grouping is selected' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'assign',
            :groupings => [@grouping1],
            :graders => [@ta1, @ta2],
            :current_table => 'groups_table'}
          assert_response :success
          assert @grouping1.tas.length == 2
          assert @grouping1.tas.include?(@ta1)
          assert @grouping1.tas.include?(@ta2)
          assert @grouping2.tas == []
          assert @grouping3.tas == []
        end

        should 'and two graders and two groupings are selected' do
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'assign',
            :groupings => [@grouping1, @grouping2],
            :graders => [@ta1, @ta2],
            :current_table => 'groups_table'}
          assert_response :success
          assert @grouping1.tas.length == 2
          assert @grouping1.tas.include?(@ta1)
          assert @grouping1.tas.include?(@ta2)
          assert @grouping2.tas.length == 2
          assert @grouping2.tas.include?(@ta1)
          assert @grouping2.tas.include?(@ta2)
          assert @grouping3.tas == []
        end

        should 'and multiple graders and multiple groupings are selected' do
          @ta3 = Ta.make
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'assign',
            :groupings => [@grouping1, @grouping2, @grouping3],
            :graders => [@ta1, @ta2, @ta3],
            :current_table => 'groups_table'}
          assert_response :success
          assert @grouping1.tas.length == 3
          assert @grouping1.tas.include?(@ta1)
          assert @grouping1.tas.include?(@ta2)
          assert @grouping1.tas.include?(@ta3)
          assert @grouping2.tas.length == 3
          assert @grouping2.tas.include?(@ta1)
          assert @grouping2.tas.include?(@ta2)
          assert @grouping2.tas.include?(@ta3)
        end

        should 'and some graders are already assigned to some groups' do
          TaMembership.make(:user => @ta1, :grouping => @grouping2)
          TaMembership.make(:user => @ta2, :grouping => @grouping1)
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'assign',
            :groupings => [@grouping1, @grouping2],
            :graders => [@ta1.id.to_s, @ta2.id.to_s],
            :current_table => 'groups_table'}
          assert_response :success
          assert @grouping1.tas.length == 2
          assert @grouping1.tas.include?(@ta1)
          assert @grouping1.tas.include?(@ta2)
          assert @grouping2.tas.length == 2
          assert @grouping2.tas.include?(@ta1)
          assert @grouping2.tas.include?(@ta2)
          assert @grouping3.tas == []
        end
      end #assign

      context 'POST on :global_actions on unassign' do
        setup do
          @grouping1 = Grouping.make(:assignment => @assignment)
          @grouping2 = Grouping.make(:assignment => @assignment)
          @grouping3 = Grouping.make(:assignment => @assignment)
          @ta1 = Ta.make
          @ta2 = Ta.make
          @ta3 = Ta.make
        end

        should 'and no graders or groupings are selected' do
          TaMembership.make(:user => @ta1, :grouping => @grouping1)
          TaMembership.make(:user => @ta2, :grouping => @grouping2)
          post_as @admin, :global_actions, {:assignment_id => @assignment.id,
            :global_actions => 'unassign',
            :current_table => 'groups_table'}
          assert_response :success
          assert @grouping1.tas == [@ta1]
          assert @grouping2.tas == [@ta2]
          assert @grouping3.tas == []
        end

        should 'and all graders from one grouping are selected' do
          ta_memberships = [
            TaMembership.make(user: @ta1, grouping: @grouping1),
            TaMembership.make(user: @ta2, grouping: @grouping1),
            TaMembership.make(user: @ta3, grouping: @grouping1),
          ]
          TaMembership.make(:user => @ta3, :grouping => @grouping3)
          post_as @admin, :global_actions,
                  assignment_id: @assignment.id,
                  global_actions:'unassign',
                  groupings: [@grouping1],
                  grader_memberships: ta_memberships,
                  current_table: 'groups_table'
          assert_response :success
          assert @grouping1.tas == []
          assert @grouping2.tas == []
          assert @grouping3.tas == [@ta3]
        end

        should 'and all groupings from one grader are selected' do
          TaMembership.make(user: @ta1, grouping: @grouping1)
          TaMembership.make(user: @ta2, grouping: @grouping1)
          ta_memberships = [
            TaMembership.make(user: @ta3, grouping: @grouping1),
            TaMembership.make(user: @ta3, grouping: @grouping2),
            TaMembership.make(user: @ta3, grouping: @grouping3)
          ]
          post_as @admin, :global_actions,
                  assignment_id: @assignment.id,
                  global_actions: 'unassign',
                  groupings: [@grouping1, @grouping2, @grouping3],
                  grader_memberships: ta_memberships,
                  current_table: 'groups_table'
          assert_response :success
          assert !@grouping1.tas.include?(@ta3)
          assert !@grouping2.tas.include?(@ta3)
          assert !@grouping3.tas.include?(@ta3)
          assert @grouping1.tas.include?(@ta1)
          assert @grouping1.tas.include?(@ta2)
        end

        should 'and one grader and one grouping is selected where the grader and grouping have other memberships' do
          ta_membership = TaMembership.make(user: @ta1, grouping: @grouping2)
          TaMembership.make(user: @ta1, grouping: @grouping1)
          TaMembership.make(user: @ta2, grouping: @grouping1)
          TaMembership.make(user: @ta3, grouping: @grouping1)
          TaMembership.make(user: @ta2, grouping: @grouping2)
          TaMembership.make(user: @ta3, grouping: @grouping2)
          TaMembership.make(user: @ta1, grouping: @grouping3)
          TaMembership.make(user: @ta2, grouping: @grouping3)
          TaMembership.make(user: @ta3, grouping: @grouping3)
          post_as @admin, :global_actions,
                  assignment_id: @assignment.id,
                  global_actions: 'unassign',
                  groupings: [@grouping2],
                  grader_memberships: ta_membership,
                  current_table: 'groups_table'
          assert_response :success
          assert !@grouping2.tas.include?(@ta1)
          assert @grouping1.tas.include?(@ta1)
          assert @grouping1.tas.include?(@ta2)
          assert @grouping1.tas.include?(@ta3)
          assert @grouping2.tas.include?(@ta2)
          assert @grouping2.tas.include?(@ta3)
          assert @grouping3.tas.include?(@ta1)
          assert @grouping3.tas.include?(@ta2)
          assert @grouping3.tas.include?(@ta3)
        end

        should 'and multiple graders and multiple groupings are selected' do
          ta_memberships = [
            TaMembership.make(user: @ta1, grouping: @grouping1),
            TaMembership.make(user: @ta2, grouping: @grouping1),
            TaMembership.make(user: @ta3, grouping: @grouping1),
            TaMembership.make(user: @ta1, grouping: @grouping2),
            TaMembership.make(user: @ta2, grouping: @grouping2),
            TaMembership.make(user: @ta3, grouping: @grouping2),
            TaMembership.make(user: @ta1, grouping: @grouping3),
            TaMembership.make(user: @ta2, grouping: @grouping3),
            TaMembership.make(user: @ta3, grouping: @grouping3)
          ]
          post_as @admin, :global_actions,
                  assignment_id: @assignment.id,
                  global_actions: 'unassign',
                  groupings: [@grouping1, @grouping2, @grouping3],
                  grader_memberships: ta_memberships,
                  current_table: 'groups_table'
          assert_response :success
          assert @grouping1.tas == []
          assert @grouping2.tas == []
          assert @grouping3.tas == []
        end
      end #unassign

    end #groupings table

    context 'With criteria table selected' do
      context 'with rubric marking scheme doing a' do
        context 'POST on :global_actions on random_assign' do
          setup do
            @criterion1 = RubricCriterion.make(:assignment => @assignment)
            @criterion2 = RubricCriterion.make(:assignment => @assignment)
            @criterion3 = RubricCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          should 'and no graders selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign', :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and no criteria selected, at least one grader' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign', :graders => [@ta1], :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and no graders are selected, at least one criterion' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign', :criteria => [@criterion1], :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and one grader and one criterion is selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign', :criteria => [@criterion1],
              :graders => [@ta1], :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas[0].id == @ta1.id
            assert @criterion2.tas == []
            assert @criterion3.tas == []
          end

          should 'and one grader and multiple criteria are selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign',
              :criteria => [@criterion1, @criterion2],
              :graders => [@ta1],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas[0].id == @ta1.id
            assert @criterion2.tas[0].id == @ta1.id
            assert @criterion3.tas == []
          end

          should 'and two graders and one criterion is selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign',
              :criteria => [@criterion1],
              :graders => [@ta1, @ta2],
              :current_table => 'criteria_table'}
            assert_response :success
            assert((@criterion1.tas[0].id == @ta1.id or @criterion1.tas[0].id == @ta2.id))
            assert @criterion2.tas == []
            assert @criterion3.tas == []
          end

          should 'and two graders and two criteria are selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign',
              :criteria => [@criterion1, @criterion2],
              :graders => [@ta1, @ta2],
              :current_table => 'criteria_table'}
            assert_response :success
            assert((@criterion1.tas[0].id == @ta1.id or @criterion1.tas[0].id == @ta2.id))
            assert ((@criterion2.tas[0].id == @ta1.id or @criterion2.tas[0].id == @ta2.id))
            assert @criterion1.tas[0].id != @criterion2.tas[0].id
            assert @criterion3.tas == []
          end

          should 'and multiple graders and multiple criteria are selected' do
            @ta3 = Ta.make
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign',
              :criteria => [@criterion1, @criterion2, @criterion3],
              :graders => [@ta1, @ta2, @ta3],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas.size == 1
            assert @criterion2.tas.size == 1
            assert @criterion3.tas.size == 1
          end
        end #random assign

        context 'POST on :global_actions on assign' do
          setup do
            @criterion1 = RubricCriterion.make(:assignment => @assignment)
            @criterion2 = RubricCriterion.make(:assignment => @assignment)
            @criterion3 = RubricCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          should 'and no graders selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign', :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and no criteria selected, at least one grader' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign', :graders => [@ta1], :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and no graders are selected, at least one criterion' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign', :criteria => [@criterion1], :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and one grader and one criterion is selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign', :criteria => [@criterion1],
              :graders => [@ta1], :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas[0].id == @ta1.id
            assert @criterion2.tas == []
            assert @criterion3.tas == []
          end

          should 'and one grader and two criteria are selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign',
              :criteria => [@criterion1, @criterion2],
              :graders => [@ta1],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas[0].id == @ta1.id
            assert @criterion2.tas[0].id == @ta1.id
            assert @criterion3.tas == []
          end

          should 'and two graders and one criterion is selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign',
              :criteria => [@criterion1],
              :graders => [@ta1, @ta2],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas.length == 2
            assert @criterion1.tas.include?(@ta1)
            assert @criterion1.tas.include?(@ta2)
            assert @criterion2.tas == []
            assert @criterion3.tas == []
          end

          should 'and two graders and two criteria are selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign',
              :criteria => [@criterion1, @criterion2],
              :graders => [@ta1, @ta2],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas.length == 2
            assert @criterion1.tas.include?(@ta1)
            assert @criterion1.tas.include?(@ta2)
            assert @criterion2.tas.length == 2
            assert @criterion2.tas.include?(@ta1)
            assert @criterion2.tas.include?(@ta2)
            assert @criterion3.tas == []
          end

          should 'and multiple graders and multiple criteria are selected' do
            @ta3 = Ta.make
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign',
              :criteria => [@criterion1, @criterion2, @criterion3],
              :graders => [@ta1, @ta2, @ta3],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas.length == 3
            assert @criterion1.tas.include?(@ta1)
            assert @criterion1.tas.include?(@ta2)
            assert @criterion1.tas.include?(@ta3)
            assert @criterion2.tas.length == 3
            assert @criterion2.tas.include?(@ta1)
            assert @criterion2.tas.include?(@ta2)
            assert @criterion2.tas.include?(@ta3)
          end

          should 'and some graders are already assigned to some criteria' do
            CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion2)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign',
              :criteria => [@criterion1, @criterion2],
              :graders => [@ta1, @ta2],
              :current_table => 'criteria_table'}

            assert_response :success
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            assert @criterion1.tas.length == 2
            assert @criterion1.tas.include?(@ta1)
            assert @criterion1.tas.include?(@ta2)
            assert @criterion2.tas.length == 2
            assert @criterion2.tas.include?(@ta1)
            assert @criterion2.tas.include?(@ta2)
            assert @criterion3.tas == []
          end
        end #assign

        context 'POST on :global_actions on unassign' do
          setup do
            @criterion1 = RubricCriterion.make(:assignment => @assignment)
            @criterion2 = RubricCriterion.make(:assignment => @assignment)
            @criterion3 = RubricCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          should 'and no graders or criteria are selected' do
            CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion2)
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'unassign',
              :current_table => 'criteria_table'}
            assert_response :success
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            assert @criterion1.tas == [@ta1]
            assert @criterion2.tas == [@ta2]
            assert @criterion3.tas == []
          end

          should 'and all graders from one criterion are selected' do
            criterion_tas = [
              CriterionTaAssociation.make(ta: @ta1, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta2, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion1)
            ]
            CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
            post_as @admin, :global_actions,
                    assignment_id: @assignment.id,
                    global_actions: 'unassign',
                    criteria: [@criterion1],
                    criterion_graders: criterion_tas,
                    current_table: 'criteria_table'
            assert_response :success
            @criterion1.reload
            assert @criterion1.tas == []
            @criterion2.reload
            @criterion3.reload
            assert @criterion2.tas == []
            assert @criterion3.tas == [@ta3]
          end

          should 'and all criteria from one grader are selected' do
            CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
            criterion_tas = [
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion2),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion3)
            ]
            post_as @admin, :global_actions,
                    assignment_id: @assignment.id,
                    global_actions: 'unassign',
                    criteria: [@criterion1, @criterion2, @criterion3],
                    criterion_graders: criterion_tas,
                    current_table: 'criteria_table'
            assert_response :success
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            assert !@criterion1.tas.include?(@ta3)
            assert !@criterion2.tas.include?(@ta3)
            assert !@criterion3.tas.include?(@ta3)
            @criterion1.reload
            assert @criterion1.tas.include?(@ta1)
            assert @criterion1.tas.include?(@ta2)
          end

          should 'and one grader and one criterion is selected where the grader and criterion have other memberships' do
            CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
            CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion1)
            criterion_ta =
              CriterionTaAssociation.make(ta: @ta1, criterion: @criterion2)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion2)
            CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion2)
            CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion3)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion3)
            CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
            post_as @admin, :global_actions,
                    assignment_id: @assignment.id,
                    global_actions: 'unassign',
                    criteria: [@criterion2],
                    criterion_graders: criterion_ta,
                    current_table: 'criteria_table'
            assert_response :success
            assert !@criterion2.tas.include?(@ta1)
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

          should 'and multiple graders and multiple criteria are selected' do
            criterion_tas = [
              CriterionTaAssociation.make(ta: @ta1, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta2, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta1, criterion: @criterion2),
              CriterionTaAssociation.make(ta: @ta2, criterion: @criterion2),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion2),
              CriterionTaAssociation.make(ta: @ta1, criterion: @criterion3),
              CriterionTaAssociation.make(ta: @ta2, criterion: @criterion3),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion3)
            ]
            post_as @admin, :global_actions,
                    assignment_id: @assignment.id,
                    global_actions: 'unassign',
                    criteria: [@criterion1, @criterion2, @criterion3],
                    criterion_graders: criterion_tas,
                    current_table: 'criteria_table'
            assert_response :success
            assert @criterion1.tas == []
            assert @criterion2.tas == []
            assert @criterion3.tas == []
          end
        end #unassign

      end #rubric scheme

      context 'with flexible marking scheme doing a' do
        setup do
          @assignment = Assignment.make(:marking_scheme_type => 'flexible')
        end

        context 'POST on :global_actions on random_assign' do
          setup do
            @criterion1 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion2 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion3 = FlexibleCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          should 'and no graders selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign', :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and no criteria selected, at least one grader' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign', :graders => [@ta1], :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and no graders are selected, at least one criterion' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign', :criteria => [@criterion1], :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and one grader and one criterion is selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign', :criteria => [@criterion1],
              :graders => [@ta1], :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas[0].id == @ta1.id
            assert @criterion2.tas == []
            assert @criterion3.tas == []
          end

          should 'and one grader and multiple criteria are selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign',
              :criteria => [@criterion1, @criterion2],
              :graders => [@ta1],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas[0].id == @ta1.id
            assert @criterion2.tas[0].id == @ta1.id
            assert @criterion3.tas == []
          end

          should 'and two graders and one criterion is selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign',
              :criteria => [@criterion1],
              :graders => [@ta1, @ta2],
              :current_table => 'criteria_table'}
            assert_response :success
            assert((@criterion1.tas[0].id == @ta1.id or @criterion1.tas[0].id == @ta2.id))
            assert @criterion2.tas == []
            assert @criterion3.tas == []
          end

          should 'and two graders and two criteria are selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign',
              :criteria => [@criterion1, @criterion2],
              :graders => [@ta1, @ta2],
              :current_table => 'criteria_table'}
            assert_response :success
            assert((@criterion1.tas[0].id == @ta1.id or @criterion1.tas[0].id == @ta2.id))
            assert((@criterion2.tas[0].id == @ta1.id or @criterion2.tas[0].id == @ta2.id))
            assert @criterion1.tas[0].id != @criterion2.tas[0].id
            assert @criterion3.tas == []
          end

          should 'and multiple graders and multiple criteria are selected' do
            @ta3 = Ta.make
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'random_assign',
              :criteria => [@criterion1, @criterion2, @criterion3],
              :graders => [@ta1, @ta2, @ta3],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas.size == 1
            assert @criterion2.tas.size == 1
            assert @criterion3.tas.size == 1
          end
        end #random assign

        context 'POST on :global_actions on assign' do
          setup do
            @criterion1 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion2 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion3 = FlexibleCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          should 'and no graders selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign', :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and no criteria selected, at least one grader' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign', :graders => [@ta1], :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and no graders are selected, at least one criterion' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign', :criteria => [@criterion1], :current_table => 'criteria_table'}
            assert_response :success
            @assignment.get_criteria do |criterion|
              assert criterion.tas == []
            end
          end

          should 'and one grader and one criterion is selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign', :criteria => [@criterion1],
              :graders => [@ta1], :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas[0].id == @ta1.id
            assert @criterion2.tas == []
            assert @criterion3.tas == []
          end

          should 'and one grader and two criteria are selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign',
              :criteria => [@criterion1, @criterion2],
              :graders => [@ta1],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas[0].id == @ta1.id
            assert @criterion2.tas[0].id == @ta1.id
            assert @criterion3.tas == []
          end

          should 'and two graders and one criterion is selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign',
              :criteria => [@criterion1],
              :graders => [@ta1, @ta2],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas.length == 2
            assert @criterion1.tas.include?(@ta1)
            assert @criterion1.tas.include?(@ta2)
            assert @criterion2.tas == []
            assert @criterion3.tas == []
          end

          should 'and two graders and two criteria are selected' do
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign',
              :criteria => [@criterion1, @criterion2],
              :graders => [@ta1, @ta2],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas.length == 2
            assert @criterion1.tas.include?(@ta1)
            assert @criterion1.tas.include?(@ta2)
            assert @criterion2.tas.length == 2
            assert @criterion2.tas.include?(@ta1)
            assert @criterion2.tas.include?(@ta2)
            assert @criterion3.tas == []
          end

          should 'and multiple graders and multiple criteria are selected' do
            @ta3 = Ta.make
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign',
              :criteria => [@criterion1, @criterion2, @criterion3],
              :graders => [@ta1, @ta2, @ta3],
              :current_table => 'criteria_table'}
            assert_response :success
            assert @criterion1.tas.length == 3
            assert @criterion1.tas.include?(@ta1)
            assert @criterion1.tas.include?(@ta2)
            assert @criterion1.tas.include?(@ta3)
            assert @criterion2.tas.length == 3
            assert @criterion2.tas.include?(@ta1)
            assert @criterion2.tas.include?(@ta2)
            assert @criterion2.tas.include?(@ta3)
          end

          should 'and some graders are already assigned to some criteria' do
            CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion2)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'assign',
              :criteria => [@criterion1, @criterion2],
              :graders => [@ta1, @ta2],
              :current_table => 'criteria_table'}
            assert_response :success
            @criterion1.reload
            @criterion2.reload
            assert @criterion1.tas.length == 2
            assert @criterion1.tas.include?(@ta1)
            assert @criterion1.tas.include?(@ta2)
            assert @criterion2.tas.length == 2
            assert @criterion2.tas.include?(@ta1)
            assert @criterion2.tas.include?(@ta2)
            assert @criterion3.tas == []
          end
        end #assign

        context 'POST on :global_actions on unassign' do
          setup do
            @criterion1 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion2 = FlexibleCriterion.make(:assignment => @assignment)
            @criterion3 = FlexibleCriterion.make(:assignment => @assignment)
            @ta1 = Ta.make
            @ta2 = Ta.make
            @ta3 = Ta.make
          end

          should 'and no graders or criteria are selected' do
            CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion2)
            post_as @admin, :global_actions, {:assignment_id => @assignment.id,
              :global_actions => 'unassign',
              :current_table => 'criteria_table'}
            assert_response :success
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            assert @criterion1.tas == [@ta1]
            assert @criterion2.tas == [@ta2]
            assert @criterion3.tas == []
          end

          should 'and all graders from one criterion are selected' do
            criterion_tas = [
              CriterionTaAssociation.make(ta: @ta1, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta2, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion1)
            ]
            CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
            post_as @admin, :global_actions,
                    assignment_id: @assignment.id,
                    global_actions: 'unassign',
                    criteria: [@criterion1],
                    criterion_graders: criterion_tas,
                    current_table: 'criteria_table'
            assert_response :success
            @criterion1.reload
            assert @criterion1.tas == []
            @criterion2.reload
            @criterion3.reload
            assert @criterion2.tas == []
            assert @criterion3.tas == [@ta3]
          end

          should 'and all criteria from one grader are selected' do
            CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
            criterion_tas = [
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion2),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion3)
            ]
            post_as @admin, :global_actions,
                    assignment_id: @assignment.id,
                    global_actions: 'unassign',
                    criteria: [@criterion1, @criterion2, @criterion3],
                    criterion_graders: criterion_tas,
                    current_table: 'criteria_table'
            assert_response :success
            @criterion1.reload
            @criterion2.reload
            @criterion3.reload
            assert !@criterion1.tas.include?(@ta3)
            assert !@criterion2.tas.include?(@ta3)
            assert !@criterion3.tas.include?(@ta3)
            @criterion1.reload
            assert @criterion1.tas.include?(@ta1)
            assert @criterion1.tas.include?(@ta2)
          end

          should 'and one grader and one criterion is selected where the grader and criterion have other memberships' do
            CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion1)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion1)
            CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion1)
            criterion_ta =
              CriterionTaAssociation.make(ta: @ta1, criterion: @criterion2)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion2)
            CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion2)
            CriterionTaAssociation.make(:ta => @ta1, :criterion => @criterion3)
            CriterionTaAssociation.make(:ta => @ta2, :criterion => @criterion3)
            CriterionTaAssociation.make(:ta => @ta3, :criterion => @criterion3)
            post_as @admin, :global_actions,
                    assignment_id: @assignment.id,
                    global_actions: 'unassign',
                    criteria: [@criterion2],
                    criterion_graders: criterion_ta,
                    current_table: 'criteria_table'
            assert_response :success
            @criterion2.reload
            assert !@criterion2.tas.include?(@ta1)
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

          should 'and multiple graders and multiple criteria are selected' do
            criterion_tas = [
              CriterionTaAssociation.make(ta: @ta1, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta2, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion1),
              CriterionTaAssociation.make(ta: @ta1, criterion: @criterion2),
              CriterionTaAssociation.make(ta: @ta2, criterion: @criterion2),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion2),
              CriterionTaAssociation.make(ta: @ta1, criterion: @criterion3),
              CriterionTaAssociation.make(ta: @ta2, criterion: @criterion3),
              CriterionTaAssociation.make(ta: @ta3, criterion: @criterion3)
            ]
            post_as @admin, :global_actions,
                    assignment_id: @assignment.id,
                    global_actions: 'unassign',
                    criteria: [@criterion1, @criterion2, @criterion3],
                    criterion_graders: criterion_tas,
                    current_table: 'criteria_table'
            assert_response :success
            assert @criterion1.tas == []
            assert @criterion2.tas == []
            assert @criterion3.tas == []
          end
        end #unassign

      end #flexible scheme
    end #criteria table

  end #admin context
end
