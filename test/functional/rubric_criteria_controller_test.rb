# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__),'..', 'test_helper'))

require 'shoulda'
require 'machinist'

class RubricCriteriaControllerTest < AuthenticatedControllerTest

  context 'An unauthenticated and unauthorized user' do

    context 'with an assignment' do
      setup do
        @grouping = Grouping.make
        @assignment = @grouping.assignment
      end

      should 'be redirected on index' do
        get :index, assignment_id: @assignment.id
        assert_response :redirect
      end

      should 'be redirected on :download_csv' do
        get :download_csv, assignment_id: @assignment.id
        assert_response :redirect
      end

      should 'be redirected on :download_yml' do
        get :download_yml, assignment_id: @assignment.id
        assert_response :redirect
      end

      should 'be redirected on :csv_upload' do
        get :csv_upload, assignment_id: @assignment.id
        assert_response :redirect
      end

      context 'and a submission' do
        setup do
          @submission = Submission.make(grouping: @grouping)
        end
      end
    end
  end # An unauthenticated and unauthorized user doing a GET

  context 'An admin, with an assignment' do

    setup do
      @admin = Admin.make
      @assignment = Assignment.make

    end

    should 'upload successfully properly formatted csv file' do
      tempfile = fixture_file_upload('files/rubric.csv')
      post_as @admin,
             :csv_upload,
             assignment_id: @assignment.id,
             csv_upload: {rubric: tempfile}
      @assignment.reload

      rubric_criteria = @assignment.get_criteria
      assert_not_nil assigns :assignment
      assert_response :redirect
      assert set_flash.to(t('rubric_criteria.upload.success', nb_updates: 4))
      assert_response :redirect
      assert_equal 4, @assignment.get_criteria.size

      assert_equal 'Algorithm Design', rubric_criteria[0].name
      assert_equal 1, rubric_criteria[0].position
      assert_equal 'Documentation', rubric_criteria[1].name
      assert_equal 2, rubric_criteria[1].position
      assert_equal 'Testing', rubric_criteria[2].name
      assert_equal 3, rubric_criteria[2].position
      assert_equal 'Correctness', rubric_criteria[3].name
      assert_equal 4, rubric_criteria[3].position
    end

    should 'deal properly with ill formatted CSV files' do
      tempfile = fixture_file_upload('files/rubric_incomplete.csv')
      post_as @admin,
              :csv_upload,
              assignment_id: @assignment.id,
              csv_upload: {rubric: tempfile}
      assert_not_nil assigns :assignment
      assert_not_empty flash[:error]
      assert_response :redirect
    end

    should 'deal properly with malformed CSV files' do
      tempfile = fixture_file_upload('files/malformed.csv')
      post_as @admin,
              :csv_upload,
              assignment_id: @assignment.id,
              csv_upload: { rubric: tempfile }

      assert_not_nil assigns :assignment
      assert_equal(flash[:error], [I18n.t('csv.upload.malformed_csv')])
      assert_response :redirect
    end

    should 'deal properly with a non csv file with a csv extension' do
      tempfile = fixture_file_upload('files/pdf_with_csv_extension.csv')
      post_as @admin,
              :csv_upload,
              assignment_id: @assignment.id,
              csv_upload: { rubric: tempfile },
              encoding: 'UTF-8'

      assert_not_nil assigns :assignment
      assert_equal(flash[:error],
                   [I18n.t('csv.upload.non_text_file_with_csv_extension')])
      assert_response :redirect
    end

    should 'have valid values in database after an upload of a UTF-8 encoded file parsed as UTF-8' do
      post_as @admin,
              :csv_upload,
              assignment_id: @assignment.id,
              csv_upload: {rubric: fixture_file_upload('files/test_rubric_criteria_UTF-8.csv')},
              encoding: 'UTF-8'
      assert_response :redirect
      test_criterion = @assignment.get_criteria.select{ |criterion| criterion.name == 'RubricCriteriaÈrÉØrr' }
      assert_not_empty test_criterion # rubric criterion should exist
    end

    should 'have valid values in database after an upload of a ISO-8859-1 encoded file parsed as ISO-8859-1' do
      post_as @admin,
              :csv_upload,
              assignment_id: @assignment.id,
              csv_upload: {rubric: fixture_file_upload('files/test_rubric_criteria_ISO-8859-1.csv')},
              encoding: 'ISO-8859-1'
      assert_response :redirect
      test_criterion = @assignment.get_criteria.select{ |criterion| criterion.name == 'RubricCriteriaÈrÉØrr' }
      assert_not_empty test_criterion # rubric criterion should exist
    end

    should 'have valid values in database after an upload of a UTF-8 encoded file parsed as ISO-8859-1' do
      post_as @admin,
              :csv_upload,
              assignment_id: @assignment.id,
              csv_upload: {rubric: fixture_file_upload('files/test_rubric_criteria_UTF-8.csv')},
              encoding: 'ISO-8859-1'
      assert_response :redirect
      test_criterion = @assignment.get_criteria.select{ |criterion| criterion.name == 'RubricCriteriaÈrÉØrr' }
      assert_empty test_criterion # rubric criterion should not exist, despite being in file
    end

    should 'upload successfully well formatted yml criteria' do
      yml_string = <<END
cr1:
  max_mark: 5
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
  max_mark: 2
END
      post_as @admin,
              :yml_upload,
              assignment_id: @assignment.id,
              yml_upload: {rubric: yml_string}

      assert_response :redirect
      assert_not_nil set_flash.to(t('rubric_criteria.upload.success',
                                    nb_updates: 2))
      @assignment.reload
      cr1 = @assignment.get_criteria.find_by(name: 'cr1')
      cr2 = @assignment.get_criteria.find_by(name: 'cr2')
      assert_equal(@assignment.get_criteria.length, 2)
      assert_equal(8, cr2.max_mark) # We get four times what we entered because we entered the weight
      assert_equal(20, cr1.max_mark)
      assert_equal('what?', cr1.level_0_name)
      assert_equal('fail', cr1.level_0_description)
      assert_equal('hmm', cr1.level_1_name)
      assert_equal('almost fail', cr1.level_1_description)
      assert_equal('average', cr1.level_2_name)
      assert_equal('average joe', cr1.level_2_description)
      assert_equal('good', cr1.level_3_name)
      assert_equal('alright', cr1.level_3_description)
      assert_equal('poor', cr1.level_4_name)
      assert_equal('I expected more', cr1.level_4_description)
    end

    should 'deal with bad weight on yaml file' do
      post_as @admin,
              :yml_upload,
              assignment_id: @assignment.id,
              yml_upload: {rubric:
                "cr1:\n  max_mark: monstrously heavy\n"}

      assert_response  :redirect
      assert_not_nil set_flash.to(
        t('rubric_criteria.upload.error') + ' cr1')
      @assignment.reload
      new_categories_list = @assignment.annotation_categories
      assert_equal [], @assignment.get_criteria

    end

    should 'deal properly with yml syntax error' do
     post_as @admin,
             :yml_upload,
             assignment_id: @assignment.id,
             yml_upload: {rubric: "cr1:\n  max_mark: 5\na"}

      assert_response :redirect
      assert_not_nil set_flash.to(t('rubric_criteria.upload.error') + '  ' +
                                  t('rubric_criteria.upload.syntax_error',
                                    error: "syntax error on line 2, col 1: `'"))
      @assignment.reload
      new_categories_list = @assignment.annotation_categories
      assert_equal(@assignment.get_criteria.length, 0)
    end

    should 'deal properly with empty yml file' do
      post_as @admin,
              :yml_upload,
              assignment_id: @assignment.id,
              yml_upload: {rubric: ''}
      assert_response :redirect
      @assignment.reload
      new_categories_list = @assignment.annotation_categories
      assert_equal(@assignment.get_criteria.length, 0)

    end

    context 'with a criterion' do
      setup do
        @criterion = RubricCriterion.make(name: 'Algorithm',
                                          assignment: @assignment)
      end

      should 'download rubric_criteria as CSV' do
        get_as @admin, :download_csv, assignment_id: @assignment.id
        assert assigns :assignment
        assert_equal response.header['Content-Type'], 'text/csv'
        assert_response :success
        assert_equal "Algorithm,4.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,\n",
                      @response.body
      end

      should 'upload yml file without deleting preexisting criteria' do
        post_as @admin,
                :yml_upload,
                assignment_id: @assignment.id,
                yml_upload: {rubric: "cr1:\n  max_mark: 5\ncr2:\n  max_mark: 2\n"}


        assert_response :redirect
        assert set_flash.to(t('rubric_criteria.upload.success',
                              nb_updates: 2))
        @assignment.reload
        assert_equal(@assignment.get_criteria.length, 3)
        assert_equal(@assignment.get_criteria[0].max_mark, 4.0)
      end

    end
  end # An admin, with an assignment, and a rubric criterion
end
