module Api

  # Allows for pushing and downloading of TestResults
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class TestScriptResultsController < MainApiController

    # Returns a list of TesResults associated with a group's assignment submission
    # Requires: submission_id
    def index
      if has_missing_params?([:submission_id])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: {code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422']}, status: 422
        return
      end

      submission = Submission.find(params[:submission_id])
      test_script_results = submission.test_script_results.includes(:test_results)

      respond_to do |format|
        format.xml{render xml: test_script_results.to_xml(root:
          'test_script_results', skip_types: 'true', include: {test_results: {}})}
        format.json{render json: test_script_results.to_json(include: {test_results: {}})}
      end
      rescue ActiveRecord::RecordNotFound => e
        # Could not find submission
        render 'shared/http_status', locals: {code: '404', message:
          e}, status: 404
    end

    # Sends the contents of the specified Test Script Result
    # Requires: id
    def show

      test_script_result = TestScriptResult.find(params[:id])

      respond_to do |format|
        format.xml{render xml: test_script_result.to_xml(root:
          'test_script_result', skip_types: 'true', include: {test_results: {}})}
        format.json{render json: test_script_result
                                 .to_json(include: {test_results: {}})}
      end
      rescue ActiveRecord::RecordNotFound => e
        # Could not find submission or test script result
        render 'shared/http_status', locals: {code: '404', message:
          e}, status: 404
    end

    # Creates a new test result for a group's latest assignment submission
    # Requires:
    #  - assignment_id
    #  - group_id
    #  - file_content: Contents of the test results file to be uploaded
    # Optional:
    #  - submission_id
    def create
      # TODO This code should really be in test_results
      if has_missing_params?([:file_content, :test_scripts])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: {code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422']}, status: 422
        return
      end

      if params[:submission_id].nil?
        submission = nil
        group = Group.find(params[:group_id])
        grouping = group.grouping_for_assignment(params[:assignment_id])
        assignment = Assignment.find(params[:assignment_id])
      else
        submission = Submission.find(params[:submission_id])
        grouping = submission.grouping
        assignment = submission.assignment
      end

      begin
        AutomatedTestsClientHelper.process_test_result(params[:file_content], params[:test_scripts], assignment,
                                                       grouping, submission)
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

    # Deletes a Test Script Result instance
    # Requires: id
    def destroy

      test_script_result = TestScriptResult.find(params[:id])

      if test_script_result.destroy
        # Successfully deleted the TestResult; render success
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200']}, status: 200
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
    end

    # Updates a Test Script Result instance. Deletes the current test script
    #  result and its test results and reprocess the xml test harness file. 
    # This is basically a delete followed by a create
    # Requires: assignment_id, group_id, id
    #  - file_content: New contents of the test results file
    # Optional: submission_id
    def update
      if has_missing_params?([:id, :file_content])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: {code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422']}, status: 422
        return
      end

      test_script_result = TestScriptResult.find(params[:id])
      if params[:submission_id].nil?
        submission = nil
        group = Group.find(params[:group_id])
        grouping = group.grouping_for_assignment(params[:assignment_id])
        assignment = Assignment.find(params[:assignment_id])
      else
        submission = Submission.find(params[:submission_id])
        grouping = submission.grouping
        assignment = submission.assignment
      end

      if AutomatedTestsClientHelper.process_test_result(params[:file_content],
                                                        assignment,
                                                        grouping,
                                                        submission) &&
          test_script_result.destroy
        render 'shared/http_status', locals: {code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200']}, status: 200
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
    end

  end # end TestResultsController
end
