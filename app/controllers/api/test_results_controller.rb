module Api

  # Allows for pushing and downloading of TestResults
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class TestResultsController < MainApiController

    # Returns a list of TesResults associated with a group's assignment submission
    # Requires: assignment_id, group_id, test_script_result_id
    def index
      submission = Submission.get_submission_by_grouping_id_and_assignment_id(
        params[:group_id], params[:assignment_id])
      
      test_results = submission.test_script_results
                    .includes(:test_results)
                    .find(params[:test_script_result_id])
                    .test_results

      respond_to do |format|
        format.xml{render xml: test_results.to_xml(root:
          'test_results', skip_types: 'true')}
        format.json{render json: test_results.to_json}
      end
      rescue ActiveRecord::RecordNotFound => e
        # Could not find submission or test script result
        render 'shared/http_status', locals: {code: '404', message:
          e}, status: 404
    end

    # Sends the contents of the specified Test Result
    # Requires: assignment_id, group_id, test_script_result_id, id
    def show
      submission = Submission.get_submission_by_grouping_id_and_assignment_id(
        params[:group_id], params[:assignment_id])

      test_result = submission.test_script_results
                            .includes(:test_results)
                            .find(params[:test_script_result_id])
                            .test_results.find(params[:id])

      respond_to do |format|
        format.xml{render xml: test_result.to_xml(root:
          'test_result', skip_types: 'true')}
        format.json{render json: test_result.to_json}
      end
      rescue ActiveRecord::RecordNotFound => e
        # Could not find submission or test script result or test result
        render 'shared/http_status', locals: {code: '404', message:
          e}, status: 404
    end

    # Creates a new test result for a group's latest assignment submission
    # Requires:
    #  - assignment_id
    #  - group_id
    #  - file_content: Contents of the test results file to be uploaded
    def create
      submission = Submission.get_submission_by_grouping_id_and_assignment_id(
        params[:group_id], params[:assignment_id])

      test_script_result = submission.test_script_results
                            .includes(:test_results)
                            .find(params[:test_script_result_id])

      if test_script_result.test_results.create(test_result_params)
        render 'shared/http_status', locals: {code: '201', message:
          HttpStatusHelper::ERROR_CODE['message']['201']}, status: 201
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
      rescue ActiveRecord::RecordNotFound => e
        # Could not find submission or test script result
        render 'shared/http_status', locals: {code: '404', message:
          e}, status: 404
    end

    # Deletes a TestResult instance
    # Requires: assignment_id, group_id, test_script_result_id, id
    def destroy
      submission = Submission.get_submission_by_grouping_id_and_assignment_id(
        params[:group_id], params[:assignment_id])

      test_result = submission.test_script_results
                            .includes(:test_results)
                            .find(params[:test_script_result_id])
                            .test_results.find(params[:id])

      if test_result.destroy
        # Successfully deleted the TestResult; render success
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200']}, status: 200
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
      rescue ActiveRecord::RecordNotFound => e
        # Could not find submission or test script result or test result
        render 'shared/http_status', locals: {code: '404', message:
          e}, status: 404
    end

    # Updates a TestResult instance
    # Requires: assignment_id, group_id, test_script_result_id, id,
    # Optional: name, completion_status, marks_earned,
    # input, actual_output, expected_output, created_at, updated_at
    def update
      submission = Submission.get_submission_by_grouping_id_and_assignment_id(
        params[:group_id], params[:assignment_id])

      test_result = submission.test_script_results
                            .includes(:test_results)
                            .find(params[:test_script_result_id])
                            .test_results.find(params[:id])

      # Update filename if provided
      test_result.update_attributes(test_result_params)

      if test_result.save
        # Everything went fine; report success
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200']}, status: 200
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
      rescue ActiveRecord::RecordNotFound => e
        # Could not find submission or test script result or test result
        render 'shared/http_status', locals: {code: '404', message:
          e}, status: 404
    end

    # User params for create & update
    def test_result_params
      params.permit(:name, :completion_status, :marks_earned,
                    :input, :actual_output, :expected_output, :created_at,
                    :updated_at)
    end

  end # end TestResultsController
end
