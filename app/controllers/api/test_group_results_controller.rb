module Api

  # Allows for pushing and downloading of TestResults
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class TestGroupResultsController < MainApiController

    # Returns a list of TestResults associated with a group's assignment submission
    # Requires: submission_id
    def index
      if has_missing_params?([:submission_id])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: {code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422']}, status: 422
        return
      end

      submission = Submission.find(params[:submission_id])
      test_group_results = submission.test_group_results.includes(:test_results)

      respond_to do |format|
        format.xml{render xml: test_group_results.to_xml(root:
          'test_script_results', skip_types: 'true', include: {test_results: {}})}
        format.json{render json: test_group_results.to_json(include: {test_results: {}})}
      end
      rescue ActiveRecord::RecordNotFound => e
        # Could not find submission
        render 'shared/http_status', locals: {code: '404', message:
          e}, status: 404
    end

    # Sends the contents of the specified Test Group Result
    # Requires: id
    def show
      test_group_result = TestGroupResult.find(params[:id])

      respond_to do |format|
        format.xml{render xml: test_group_result.to_xml(root:
          'test_group_result', skip_types: 'true', include: {test_results: {}})}
        format.json{render json: test_group_result
                                 .to_json(include: {test_results: {}})}
      end
      rescue ActiveRecord::RecordNotFound => e
        # Could not find submission or test group result
        render 'shared/http_status', locals: {code: '404', message:
          e}, status: 404
    end

    # Creates a new test result for a group's assignment submission
    # Requires:
    #  - test_run_id: The id of the test run that generated these results
    #  - test_output: The test results in json format
    def create
      if has_missing_params?([:test_output, :test_run_id])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: {code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422']}, status: 422
        return
      end
      test_run = TestRun.find(params[:test_run_id])
      begin
        test_run.create_test_group_results_from_json(params[:test_output])
        render 'shared/http_status', locals: {code: '201', message:
            HttpStatusHelper::ERROR_CODE['message']['201']}, status: 201
      rescue
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
      rescue ActiveRecord::RecordNotFound => e
        # Could not find submission
        render 'shared/http_status', locals: {code: '404', message:
          e}, status: 404
    end

    # Deletes a Test Group Result instance
    # Requires: id
    def destroy

      test_group_result = TestGroupResult.find(params[:id])

      if test_group_result.destroy
        # Successfully deleted the TestResult; render success
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200']}, status: 200
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
    end

    # Updates a Test Group Result instance. Deletes the current test group
    #  result and its test results and reprocess the json test output.
    # This is basically a delete followed by a create
    # Requires: test_run_id, id
    #  - test_output: New contents of the test results
    def update
      if has_missing_params?([:id, :test_output, :test_run_id])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: {code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422']}, status: 422
        return
      end

      test_group_result = TestGroupResult.find(params[:id])
      test_run = TestRun.find(params[:test_run_id])
      if test_run.create_test_group_results_from_json(params[:test_output]) && test_group_result.destroy
        render 'shared/http_status', locals: {code: '200', message: HttpStatusHelper::ERROR_CODE['message']['200']},
                                     status: 200
      else
        # Some other error occurred
        render 'shared/http_status', locals: {code: '500', message: HttpStatusHelper::ERROR_CODE['message']['500']},
                                     status: 500
      end
    end

  end # end TestResultsController
end
