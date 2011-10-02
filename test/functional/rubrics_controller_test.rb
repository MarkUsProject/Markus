require File.join(File.dirname(__FILE__), 'authenticated_controller_test')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')

require 'shoulda'
require 'mocha'
require 'machinist'

class RubricsControllerTest < AuthenticatedControllerTest

  fixtures :all

  RUBRIC_CRITERIA_CSV_STRING = "Algorithm Design,2.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Documentation,2.7,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Testing,2.2,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Correctness,2.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,\n"
  RUBRIC_CRITERIA_UPLOAD_CSV_STRING = "criterion 5,1.0,l0,l1,l2,l3,l4,d0,d1,d2,d3,d4\n"
  RUBRIC_CRITERIA_INCOMPLETE_UPLOAD_CSV_STRING = "criterion 5\ncriterion 6\n"

  context "An unauthenticated and unauthorized user doing a GET" do

    context "on :index" do
      setup do
        get :index, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :edit" do
      setup do
        get :edit, :assignment_id => 1, :submission_id => 1, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update" do
      setup do
        get :update, :assignment_id => 1, :id => 1
      end
      should respond_with :redirect
    end

    context "on :new" do
      setup do
        get :new, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :delete" do
      setup do
        delete :destroy, :assignment_id => 1, :id => 1
      end
      should respond_with :redirect
    end

    context "on :download_csv" do
      setup do
        get :download_csv, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :download_yml" do
      setup do
        get :download_yml, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :csv_upload" do
      setup do
        get :csv_upload, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :update_positions" do
      setup do
        get :update_positions, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :move_criterion" do
      setup do
        get :move_criterion, :assignment_id => 1, :id => 1
      end
      should respond_with :redirect
    end

  end # An unauthenticated and unauthorized user doing a GET

  context "An unauthenticated and unauthorized user doing a POST" do

    context "on :index" do
      setup do
        post :index, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :edit" do
      setup do
        get :edit, :assignment_id => 1, :submission_id => 1, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update" do
      setup do
        put :update, :assignment_id => 1, :id => 1
      end
      should respond_with :redirect
    end

    context "on :new" do
      setup do
        get :new, :assignment_id => 1, :submission_id => 1
      end
      should respond_with :redirect
    end

    context "on :delete" do
      setup do
        delete :destroy, :assignment_id => 1, :submission_id => 1, :id => 1
      end
      should respond_with :redirect
    end

    context "on :download_csv" do
      setup do
        post :download_csv, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :download_yml" do
      setup do
        post :download_yml, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :csv_upload" do
      setup do
        post :csv_upload, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :update_positions" do
      setup do
        post :update_positions, :assignment_id => 1
      end
      should respond_with :redirect
    end

    context "on :move_criterion" do
      setup do
        post :move_criterion,:assignment_id => 1, :id => 1
      end
      should respond_with :redirect
    end

  end # An unauthenticated and unauthorized user doing a POST

  context "An authenticated and authorized admin doing a GET" do
    fixtures :users, :assignments, :rubric_criteria, :marks, :results

    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:assignment_1)
      @criterion = rubric_criteria(:c1)
    end

    context "on :index" do
      setup do
        get_as @admin, :index, :assignment_id => @assignment.id
      end
      should assign_to :assignment
      should assign_to :criteria
      should render_template :index
      should respond_with :success
    end

    context "on :edit" do
      setup do
        get_as @admin, :edit, :assignment_id => 1, :id => @criterion.id
      end
      should assign_to :criterion
      should render_template :edit
      should respond_with :success
    end

    should "be able to save with errors" do
      RubricCriterion.any_instance.expects(:save).once.returns(false)
      RubricCriterion.any_instance.expects(:errors).once.returns('error msg')
      get_as @admin,
             :update,
             :assignment_id => 1,
             :id => @criterion.id,
             :rubric_criterion => {:rubric_criterion_name => 'one',
                                   :weight => 10}
      assert assign_to :criterion
      assert render_template 'errors'
      assert_response :success
    end

    should "be able to  save without errors" do
      get_as @admin,
             :update,
             :assignment_id => 1,
             :id => @criterion.id,
             :rubric_criterion => {:rubric_criterion_name => 'one', :weight => 10}
      assert assign_to :criterion
      assert_equal I18n.t('criterion_saved_success'), flash[:success]
      assert render_template :update
    end

    context "on :new" do
      setup do
        get_as @admin, :new, :assignment_id => @assignment.id
      end
      should assign_to :assignment
      should render_template :new
      should respond_with :success
    end

    context "on: download" do
      setup do
        get_as @admin, :download_csv, :assignment_id => @assignment.id
      end
      should assign_to :assignment
      should respond_with_content_type 'text/csv'
      should respond_with :success
      should "respond with appropriate content" do
        assert_equal RUBRIC_CRITERIA_CSV_STRING, @response.body
      end
    end

    context "on :csv_upload" do
      setup do
        get_as @admin, :csv_upload, :assignment_id => @assignment.id, :csv_upload => {:rubric => ""}
      end
      should assign_to :assignment
      should respond_with :redirect
    end

    should "be able to update_positions" do
      @criterion2 = rubric_criteria(:c2)
      get_as @admin,
             :update_positions,
             :rubric_criteria_pane_list => [@criterion2.id,
                                            @criterion.id],
             :assignment_id => @assignment.id
      assert render_template ''
      assert_response :success

      c1 = RubricCriterion.find(@criterion.id)
      assert_equal 1, c1.position
      c2 = RubricCriterion.find(@criterion2.id)
      assert_equal 2, c2.position
    end

    should "be able to move_criterion up" do
      @criterion2 = rubric_criteria(:c2)
      get_as @admin,
             :move_criterion,
             :assignment_id => @assignment.id,
             :id => @criterion2.id,
             :position => @criterion2.position,
             :direction => :up
      assert render_template ''
      assert_response :success

      c1 = RubricCriterion.find(@criterion.id)
      assert_equal 1, c1.position
      c2 = RubricCriterion.find(@criterion2.id)
      assert_equal 2, c2.position
    end

    should "be able to move_criterion down" do
      @criterion2 = rubric_criteria(:c2)
      get_as @admin,
             :move_criterion,
             :assignment_id => @assignment.id,
             :id => @criterion.id,
             :position => @criterion.position,
             :direction => :up
      assert render_template ''
      assert_response :success

      c1 = RubricCriterion.find(@criterion.id)
      assert_equal 1, c1.position
      c2 = RubricCriterion.find(@criterion2.id)
      assert_equal 2, c2.position
    end

  end # An authenticated and authorized admin doing a GET

  context "An admin, with an assignment" do
    setup do
      clear_fixtures
      @admin = Admin.make
      @assignment = Assignment.make
    end

    context "with several rubric" do
      setup do
        3.times do |i|
          criterion = RubricCriterion.make(:assignment => @assignment)
          criterion.position = i
          criterion.save
        end
        @criteria = @assignment.rubric_criteria
      end

      should "be able to move down a criteria" do
        criterion = @criteria[1]
        other_criterion = @criteria[2]
        post_as @admin,
                :move_criterion,
                :assignment_id => @assignment,
                :id => criterion,
                :position => criterion.position,
                :direction => 'down'
        @criteria.reload
        assert_equal criterion, @criteria[criterion.position + 1]
        assert_equal other_criterion, @criteria[criterion.position]
        assert render_template ''
        assert_response :success
      end

      should "be able to move up a criteria" do
        criterion = @criteria[1]
        other_criterion = @criteria[criterion.position - 1]
        post_as @admin,
                :move_criterion,
                :assignment_id => @assignment,
                :id => criterion,
                :position => criterion.position,
                :direction => 'up'
        @criteria.reload
        assert_equal criterion, @criteria[criterion.position - 1]
        assert_equal other_criterion, @criteria[criterion.position]
        assert render_template ''
        assert_response :success
      end

      should "not be able to move up top criteria" do
        criterion = @criteria[0]
        post_as @admin,
                :move_criterion,
                :assignment_id => @assignment,
                :id => criterion,
                :position => criterion.position,
                :direction => 'up'
        @criteria.reload
        assert_equal 0, criterion.position
        assert render_template ''
        assert_response :success
      end

      should "not be able to move down top criteria" do
        criterion = @criteria.last
        position = criterion.position
        post_as @admin,
                :move_criterion,
                :assignment_id => @assignment,
                :id => criterion,
                :position => criterion.position,
                :direction => 'down'
        @criteria.reload
        assert_equal position, criterion.position
        assert render_template ''
        assert_response :success
      end

    end
  end  # An admin, with an assignment

  context "An authenticated and authorized admin doing a POST" do
    fixtures :users, :assignments, :rubric_criteria, :marks, :results

    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:assignment_1)
      @criterion = rubric_criteria(:c1)
    end

    should "on :index" do
      post_as @admin, :index, :assignment_id => @assignment.id
      assert assign_to :assignment
      assert assign_to :criteria
      assert render_template :index
      assert_response :success
    end

    should "on :edit" do
      post_as @admin,
              :edit,
              :assignment_id => @assignment.id,
              :id => @criterion.id
      assert assign_to :criterion
      assert render_template :edit
      assert_response :success
    end

    context "on :new" do
      should "with save error" do
        RubricCriterion.any_instance.expects(:save).once.returns(false)
        post_as @admin,
                :create,
                :assignment_id => @assignment.id,
                :rubric_criterion => {:rubric_criterion_name => 'first',
                                      :weight => 10}
        assert assign_to :assignment
        assert assign_to :criterion
        assert assign_to :errors
        assert render_template 'rubrics/add_criterion_error'
        assert_response :success
      end

      context "without error on an assignment as the first criterion" do
        setup do
          assignment = assignments(:assignment_3)
          post_as @admin,
                  :create,
                  :assignment_id => assignment.id,
                  :rubric_criterion => {:rubric_criterion_name => 'first', :weight => 10}
        end
        should assign_to :assignment
        should assign_to :criterion
        should render_template 'rubrics/create_and_edit'
        should respond_with :success
      end

      context "without error on an assignment that already has criteria" do
        setup do
          post_as @admin,
                  :create,
                  :assignment_id => @assignment.id,
                  :rubric_criterion => {:rubric_criterion_name => 'first', :weight => 10}
        end
        should assign_to :assignment
        should assign_to :criterion
        should render_template 'rubrics/create_and_edit'
        should respond_with :success
      end
    end

    context "on: download" do
      setup do
        post_as @admin, :download_csv, :assignment_id => @assignment.id
      end
      should assign_to :assignment
      should respond_with_content_type 'text/csv'
      should respond_with :success
      should "respond with appropriate content" do
        assert_equal RUBRIC_CRITERIA_CSV_STRING, @response.body
      end
    end

    context "on :csv_upload" do
      context "with file containing incomplete records" do
        setup do
          tempfile = Tempfile.new('rubric_csv')
          tempfile << RUBRIC_CRITERIA_INCOMPLETE_UPLOAD_CSV_STRING
          tempfile.rewind
          post_as @admin,
                  :csv_upload,
                  :assignment_id => @assignment.id,
                  :csv_upload => {:rubric => tempfile}
        end
        should assign_to :assignment
        should set_the_flash.to( :error => I18n.t('csv_invalid_lines'),
                                :invalid_lines => ["criterion 5: " + I18n.t('criteria.error.incomplete_row'),
                                                   "criterion 6: " + I18n.t('criteria.error.incomplete_row')])
        should respond_with :redirect
      end

      context "with file containing full records" do
        setup do
          # Destroy any existing criteria
          RubricCriterion.destroy_all
          tempfile = Tempfile.new('rubric_csv')
          tempfile << RUBRIC_CRITERIA_CSV_STRING
          tempfile.rewind
          post_as @admin,
                  :csv_upload,
                  :assignment_id => @assignment.id,
                  :csv_upload => {:rubric => tempfile}
          @assignment.reload
          @rubric_criteria = @assignment.rubric_criteria
        end
        should assign_to :assignment
        should set_the_flash.to( I18n.t('rubric_criteria.upload.success', :nb_updates => 4))
        should respond_with :redirect
        should "have successfully uploaded criteria" do
            assert_equal 4, @assignment.rubric_criteria.size
        end

        should "keep ordering of uploaded criteria" do
            assert_equal "Algorithm Design", @rubric_criteria[0].rubric_criterion_name
            assert_equal 1, @rubric_criteria[0].position
            assert_equal "Documentation", @rubric_criteria[1].rubric_criterion_name
            assert_equal 2, @rubric_criteria[1].position
            assert_equal "Testing", @rubric_criteria[2].rubric_criterion_name
            assert_equal 3, @rubric_criteria[2].position
            assert_equal "Correctness", @rubric_criteria[3].rubric_criterion_name
            assert_equal 4, @rubric_criteria[3].position
        end
      end
    end

   should "be able to update_positions" do
      @criterion2 = rubric_criteria(:c2)
      post_as @admin,
              :update_positions,
              :rubric_criteria_pane_list => [@criterion2.id,
                                             @criterion.id],
              :assignment_id => @assignment.id
      assert render_template ''
      assert_response :success

      c1 = RubricCriterion.find(@criterion.id)
      assert_equal 2, c1.position
      c2 = RubricCriterion.find(@criterion2.id)
      assert_equal 1, c2.position
    end

    context "on :yml_upload" do
      setup do
        clear_fixtures
        @assignment = Assignment.make
        @admin = Admin.make
      end

      context "with no problems and no preexisting criteria" do
        setup do
          post_as @admin, :yml_upload, :assignment_id => @assignment.id, :yml_upload => {:rubric =>
           "cr1:\n  weight: 5\n  level_0:\n    name: what?\n    description: fail\n  level_1:\n    name: hmm\n    description: almost fail\n  level_2:\n    name: average\n    description: average joe\n  level_3:\n    name: good\n    description: alright\n  level_4:\n    name: poor\n    description: I expected more\ncr2:\n  weight: 2\n"}
        end

        should respond_with :redirect
        should set_the_flash.to((I18n.t('rubric_criteria.upload.success', :nb_updates => 2)))
        should "have added 2 criteria" do
          @assignment.reload
          assert_equal(@assignment.rubric_criteria.length, 2)
        end
        should "have got the weights right" do
          @assignment.reload
          assert_equal(@assignment.rubric_criteria[0].weight, 5)
          assert_equal(@assignment.rubric_criteria[1].weight, 2)
        end
        should "have got names and descriptions right" do
          @assignment.reload
          assert_equal(@assignment.rubric_criteria[0].level_0_name, "what?")
          assert_equal(@assignment.rubric_criteria[0].level_0_description, "fail")
          assert_equal(@assignment.rubric_criteria[0].level_1_name, "hmm")
          assert_equal(@assignment.rubric_criteria[0].level_1_description, "almost fail")
          assert_equal(@assignment.rubric_criteria[0].level_2_name, "average")
          assert_equal(@assignment.rubric_criteria[0].level_2_description, "average joe")
          assert_equal(@assignment.rubric_criteria[0].level_3_name, "good")
          assert_equal(@assignment.rubric_criteria[0].level_3_description, "alright")
          assert_equal(@assignment.rubric_criteria[0].level_4_name, "poor")
          assert_equal(@assignment.rubric_criteria[0].level_4_description, "I expected more")
        end
      end

      context "with preexisting criteria" do
        setup do
          RubricCriterion.make(:assignment => @assignment, :rubric_criterion_name => "cr2", :weight => 7)
          post_as @admin, :yml_upload, :assignment_id => @assignment.id, :yml_upload => {:rubric =>
           "cr1:\n  weight: 5\ncr2:\n  weight: 2\n"}
        end

        should respond_with :redirect
        should set_the_flash.to((I18n.t('rubric_criteria.upload.success', :nb_updates => 2)))
        should "now have 2 criteria" do
          @assignment.reload
          assert_equal(@assignment.rubric_criteria.length, 2)
        end
        should "have updated the already existing criterion" do
          @assignment.reload
          assert_equal(@assignment.rubric_criteria[0].weight, 2)
        end
      end

      context "with bad weight" do
        setup do
          post_as @admin, :yml_upload, :assignment_id => @assignment.id, :yml_upload => {:rubric =>
           "cr1:\n  weight: monstrously heavy\n"}
        end

        should respond_with :redirect
        should set_the_flash.to(I18n.t('rubric_criteria.upload.error') + " " + "cr1")
        should "have added 0 criteria" do
          @assignment.reload
          new_categories_list = @assignment.annotation_categories
          assert_equal(@assignment.rubric_criteria.length, 0)
        end
      end
      context "with syntax error" do
        setup do
          post_as @admin, :yml_upload, :assignment_id => @assignment.id, :yml_upload => {:rubric =>
           "cr1:\n  weight: 5\na"}
        end

        should respond_with :redirect
        should set_the_flash.to(I18n.t('rubric_criteria.upload.error') + "  " + I18n.t('rubric_criteria.upload.syntax_error', :error => "syntax error on line 2, col 1: `'"))
        should "have added 0 criteria" do
          @assignment.reload
          new_categories_list = @assignment.annotation_categories
          assert_equal(@assignment.rubric_criteria.length, 0)
        end
      end
      context "with empty file" do
        setup do
          post_as @admin, :yml_upload, :assignment_id => @assignment.id, :yml_upload => {:rubric =>
           ""}
        end

        should respond_with :redirect
        should "have added 0 criteria" do
          @assignment.reload
          new_categories_list = @assignment.annotation_categories
          assert_equal(@assignment.rubric_criteria.length, 0)
        end
      end
    end#YML Upload
  end # An authenticated and authorized admin doing a POST

  context "An authenticated and authorized admin doing a DELETE" do
    fixtures :users, :assignments, :rubric_criteria, :marks, :results

    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:assignment_1)
      @criterion = rubric_criteria(:c1)
      @mark = marks(:mark_11)
    end

    should "be able to delete a criterion" do
      delete_as @admin, :destroy, :assignment_id => 1, :id => @criterion.id

      assert assign_to :criterion
      assert_equal flash[:success], I18n.t('criterion_deleted_success')
      assert_response :success

      assert_raise ActiveRecord::RecordNotFound do
        RubricCriterion.find(@criterion.id)
      end
      assert_raise ActiveRecord::RecordNotFound do
        Mark.find(@mark.id)
      end
    end

  end

end
