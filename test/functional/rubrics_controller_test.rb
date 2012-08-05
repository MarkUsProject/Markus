require File.join(File.dirname(__FILE__), 'authenticated_controller_test')
require File.join(File.dirname(__FILE__),'..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')

require 'shoulda'
require 'mocha'
require 'machinist'

class RubricsControllerTest < AuthenticatedControllerTest

  def setup
    clear_fixtures
  end

  RUBRIC_CRITERIA_CSV_STRING = "Algorithm Design,2.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Documentation,2.7,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Testing,2.2,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Correctness,2.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,\n"
  RUBRIC_CRITERIA_UPLOAD_CSV_STRING = "criterion 5,1.0,l0,l1,l2,l3,l4,d0,d1,d2,d3,d4\n"
  RUBRIC_CRITERIA_INCOMPLETE_UPLOAD_CSV_STRING = "criterion 5\ncriterion 6\n"

  context "An unauthenticated and unauthorized user" do

    context "with an assignment" do
      setup do
        @grouping = Grouping.make
        @assignment = @grouping.assignment
      end

      should "be redirected on index" do
        get :index, :assignment_id => @assignment.id
        assert_response :redirect
      end

      should "be redirected on new" do
        get :new, :assignment_id => @assignment.id
        assert_response :redirect
      end

      should "be redirected on :download_csv" do
        get :download_csv, :assignment_id => @assignment.id
        assert_response :redirect
      end

      should "be redirected on :download_yml" do
        get :download_yml, :assignment_id => @assignment.id
        assert_response :redirect
      end

      should "be redirected on :csv_upload" do
        get :csv_upload, :assignment_id => @assignment.id
        assert_response :redirect
      end

     should "be redirected on :update_positions" do
        get :update_positions, :assignment_id => @assignment.id
        assert_response :redirect
      end

      should "be redirected on :move_criterion" do
        get :move_criterion, :assignment_id => @assignment.id, :id => 1
        # FIXME
        assert_response :redirect
      end

      context "and a submission" do
        setup do
          @submission = Submission.make(:grouping => @grouping)
        end

        should "be redirect on edit" do
          get :edit,
              :assignment_id => @assignment.id,
              :submission_id => @submission.id,
              :id => 1
              #FIXME
          assert_response :redirect
        end

        should "be redirected on update" do
          put :update, :assignment_id => @assignment.id, :id => 1
          assert_response :redirect
        end

        should "be redirect on delete" do
          delete :destroy, :assignment_id => @assignment.id, :id => 1
          assert_response :redirect
        end
      end
    end
  end # An unauthenticated and unauthorized user doing a GET

  context "An admin, with an assignment" do

    setup do
      @admin = Admin.make
      @assignment = Assignment.make

    end

    should "upload successfully properly formatted csv file" do
      tempfile = Tempfile.new('rubric_csv')
      tempfile << RUBRIC_CRITERIA_CSV_STRING
      tempfile.rewind
      post_as @admin,
             :csv_upload,
             :assignment_id => @assignment.id,
             :csv_upload => {:rubric => tempfile}
      @assignment.reload

      rubric_criteria = @assignment.rubric_criteria
      assert_not_nil assigns :assignment
      assert_response :redirect
      assert set_the_flash.to( I18n.t('rubric_criteria.upload.success', :nb_updates => 4))
      assert_response :redirect
      assert_equal 4, @assignment.rubric_criteria.size

      assert_equal "Algorithm Design", rubric_criteria[0].rubric_criterion_name
      assert_equal 1, rubric_criteria[0].position
      assert_equal "Documentation", rubric_criteria[1].rubric_criterion_name
      assert_equal 2, rubric_criteria[1].position
      assert_equal "Testing", rubric_criteria[2].rubric_criterion_name
      assert_equal 3, rubric_criteria[2].position
      assert_equal "Correctness", rubric_criteria[3].rubric_criterion_name
      assert_equal 4, rubric_criteria[3].position
    end

    should "deal properly with ill formatted CSV files" do
      tempfile = Tempfile.new('rubric_csv')
      tempfile << RUBRIC_CRITERIA_INCOMPLETE_UPLOAD_CSV_STRING
      tempfile.rewind
      post_as @admin,
              :csv_upload,
              :assignment_id => @assignment.id,
              :csv_upload => {:rubric => tempfile}
      assert_not_nil assigns :assignment
      assert set_the_flash.to(:error => I18n.t('csv_invalid_lines'),
                              :invalid_lines => [
                          "criterion 5: " + I18n.t('criteria.error.incomplete_row'),
                          "criterion 6: " + I18n.t('criteria.error.incomplete_row')])
      assert_response :redirect
    end

    should "have valid values in database after an upload of a UTF-8 encoded file parsed as UTF-8" do
      post_as @admin,
              :csv_upload,
              :assignment_id => @assignment.id,
              :csv_upload => {:rubric => fixture_file_upload('../files/test_rubric_criteria_UTF-8.csv')},
              :encoding => "UTF-8"
      assert_response :redirect
      test_criterion = RubricCriterion.find_by_assignment_id_and_rubric_criterion_name(@assignment.id, "RubricCriteriaÈrÉØrr")
      assert_not_nil test_criterion # rubric criterion should exist
    end

    should "have valid values in database after an upload of a ISO-8859-1 encoded file parsed as ISO-8859-1" do
      post_as @admin,
              :csv_upload,
              :assignment_id => @assignment.id,
              :csv_upload => {:rubric => fixture_file_upload('../files/test_rubric_criteria_ISO-8859-1.csv')},
              :encoding => "ISO-8859-1"
      assert_response :redirect
      test_criterion = RubricCriterion.find_by_assignment_id_and_rubric_criterion_name(@assignment.id, "RubricCriteriaÈrÉØrr")
      assert_not_nil test_criterion # rubric criterion should exist
    end

    should "have valid values in database after an upload of a UTF-8 encoded file parsed as ISO-8859-1" do
      post_as @admin,
              :csv_upload,
              :assignment_id => @assignment.id,
              :csv_upload => {:rubric => fixture_file_upload('../files/test_rubric_criteria_UTF-8.csv')},
              :encoding => "ISO-8859-1"
      assert_response :redirect
      test_criterion = RubricCriterion.find_by_assignment_id_and_rubric_criterion_name(@assignment.id, "RubricCriteriaÈrÉØrr")
      assert_nil test_criterion # rubric criterion should not exist, despite being in file
    end

    should "upload successfully well formatted yml criteria" do
      yml_string = <<END
cr1:
  weight: 5
  level_0:
    name: what?
    description: fail
  level_1:
    name: hmm
    description: almost fail
  level_2:
    name: average
    description: average joe
  level_3:
    name: good
    description: alright
  level_4:
    name: poor
    description: I expected more
cr2:
  weight: 2
END
      post_as @admin,
              :yml_upload,
              :assignment_id => @assignment.id,
              :yml_upload => {:rubric => yml_string}

      assert_response :redirect
      assert_not_nil set_the_flash.to((I18n.t('rubric_criteria.upload.success',
                                      :nb_updates => 2)))
      @assignment.reload
      cr1 = @assignment.rubric_criteria.find_by_rubric_criterion_name("cr1")
      cr2 = @assignment.rubric_criteria.find_by_rubric_criterion_name("cr2")
      assert_equal(@assignment.rubric_criteria.length, 2)
      assert_equal(2, cr2.weight)
      assert_equal(5, cr1.weight)
      assert_equal("what?", cr1.level_0_name)
      assert_equal("fail", cr1.level_0_description)
      assert_equal("hmm", cr1.level_1_name)
      assert_equal("almost fail", cr1.level_1_description)
      assert_equal("average", cr1.level_2_name)
      assert_equal("average joe", cr1.level_2_description)
      assert_equal("good", cr1.level_3_name)
      assert_equal("alright", cr1.level_3_description)
      assert_equal("poor", cr1.level_4_name)
      assert_equal("I expected more", cr1.level_4_description)
    end

    should "deal with bad weight on yaml file" do
      post_as @admin,
              :yml_upload,
              :assignment_id => @assignment.id,
              :yml_upload => {:rubric =>
                "cr1:\n  weight: monstrously heavy\n"}

      assert_response  :redirect
      assert_not_nil set_the_flash.to(
          I18n.t('rubric_criteria.upload.error') + " " + "cr1")
      @assignment.reload
      new_categories_list = @assignment.annotation_categories
      assert_equal [], @assignment.rubric_criteria

    end

    should "deal properly with yml syntax error" do
     post_as @admin,
             :yml_upload,
             :assignment_id => @assignment.id,
             :yml_upload => {:rubric => "cr1:\n  weight: 5\na"}

      assert_response :redirect
      assert_not_nil set_the_flash.to(I18n.t('rubric_criteria.upload.error') + "  " + I18n.t('rubric_criteria.upload.syntax_error', :error => "syntax error on line 2, col 1: `'"))
      @assignment.reload
      new_categories_list = @assignment.annotation_categories
      assert_equal(@assignment.rubric_criteria.length, 0)
    end

    should "deal properly with empty yml file" do
      post_as @admin,
              :yml_upload,
              :assignment_id => @assignment.id,
              :yml_upload => {:rubric => ""}
      assert_response :redirect
      @assignment.reload
      new_categories_list = @assignment.annotation_categories
      assert_equal(@assignment.rubric_criteria.length, 0)

    end

    context "with a criterion" do
      setup do
        @criterion = RubricCriterion.make(:rubric_criterion_name => 'Algorithm',
                                          :assignment => @assignment)
      end

      should "see index" do
        get_as @admin, :index, :assignment_id => @assignment.id
        assert assigns :assignment
        assert assigns :criteria
        assert render_template :index
        assert_response :success
      end

      should "be able to get on :edit" do
        get_as @admin, :edit, :assignment_id => 1, :id => @criterion.id
        assert assigns :criterion
        assert render_template :edit
        assert_response :success
      end

      should "be able to save with errors" do
        RubricCriterion.any_instance.expects(:save).once.returns(false)
        RubricCriterion.any_instance.expects(:errors).once.returns('error msg')
        get_as @admin,
              :update,
              :assignment_id => @assignment.id,
              :id => @criterion.id,
              :rubric_criterion => {:rubric_criterion_name => 'one',
                                    :weight => 10}
        assert assigns :criterion
        assert render_template 'errors'
        assert_response :success
      end

      should "be able to  save without errors" do
        get_as @admin,
              :update,
              :assignment_id => @assignment.id,
              :id => @criterion.id,
              :rubric_criterion => {:rubric_criterion_name => 'one',
                                    :weight => 10}
        assert assigns :criterion
        assert_equal I18n.t('criterion_saved_success'), flash[:success]
        assert render_template :update
      end

      should "be able to get the form for new rubric" do
        get_as @admin, :new, :assignment_id => @assignment.id
        assert assigns :assignment
        assert render_template :new
        assert_response :success
      end

      should "be able to save with error" do
        RubricCriterion.any_instance.expects(:save).once.returns(false)
        post_as @admin,
                :create,
                :assignment_id => @assignment.id,
                :rubric_criterion => {:rubric_criterion_name => 'first',
                                      :weight => 10}
        assert assigns :assignment
        assert assigns :criterion
        assert assigns :errors
        assert render_template 'rubrics/add_criterion_error'
        assert_response :success
      end

      should "save without error on an assignment as the first criterion" do
        assignment = Assignment.make
        # XXX move elsewhere -> does not need this context
        post_as @admin,
                :create,
                :assignment_id => assignment.id,
                :rubric_criterion => {:rubric_criterion_name => 'first',
                                      :weight => 10}
        assert assigns :assignment
        assert assigns :criterion
        assert render_template 'rubrics/create_and_edit'
        assert respond_with :success
      end

      should "save without errors" do
        post_as @admin,
                :create,
                :assignment_id => @assignment.id,
                :rubric_criterion => {:rubric_criterion_name => 'first',
                                      :weight => 10}
        assert assigns :assignment
        assert assigns :criterion
        assert render_template 'rubrics/create_and_edit'
        assert_response :success
      end

      should "delete criterion" do
        delete_as @admin, :destroy, :assignment_id => 1, :id => @criterion.id

        assert assigns :criterion
        assert_equal flash[:success], I18n.t('criterion_deleted_success')
        assert_response :success

        assert_raise ActiveRecord::RecordNotFound do
          RubricCriterion.find(@criterion.id)
        end
      end


      should "download rubrics as CSV" do
        get_as @admin, :download_csv, :assignment_id => @assignment.id
        assert assigns :assignment
        assert respond_with_content_type 'text/csv'
        assert_response :success
        assert_equal "Algorithm,1.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,\n",
                      @response.body
      end

      should "upload yml file without deleting preexisting criteria" do
        post_as @admin,
                :yml_upload,
                :assignment_id => @assignment.id,
                :yml_upload => {:rubric => "cr1:\n  weight: 5\ncr2:\n  weight: 2\n"}


        assert_response :redirect
        assert set_the_flash.to((I18n.t('rubric_criteria.upload.success',
                                        :nb_updates => 2)))
        @assignment.reload
        assert_equal(@assignment.rubric_criteria.length, 3)
        assert_equal(@assignment.rubric_criteria[0].weight, 1.0)
      end


      context "with another criterion" do
        setup do
          @criterion2 = RubricCriterion.make(:assignment => @assignment,
                                            :position => 2)
        end

        should "be able to update_positions" do
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

        context "And yet another" do
          setup do
            criterion = RubricCriterion.make(:assignment => @assignment,
                                            :position => 3)
            @criteria = @assignment.rubric_criteria
          end

          should "be able to move up top criteria" do
            criterion = @criteria[0]
            post_as @admin,
                    :move_criterion,
                    :assignment_id => @assignment,
                    :id => criterion,
                    :position => criterion.position,
                    :direction => 'up'
            @criteria.reload
            assert_equal 1, criterion.position
            assert render_template ''
            assert_response :success
          end

          should "be able to move down top criteria" do
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
      end # with another submission
    end 
  end # An admin, with an assignment, and a rubric criterion
end
