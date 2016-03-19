module Api

  # Allows for pushing and downloading of TestResults
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class TestResultsController < MainApiController
    # Define default fields for index method
    @@default_fields = [:id, :grouping_id]

    # Returns a list of TesResults associated with a group's assignment submission
    # Requires: assignment_id, group_id
    # Optional: filter, fields
    def index
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      collection = submission.test_script_results.includes(:test_results)
      test_script_results = get_collection(TestScriptResult, collection)
      fields = fields_to_render(@@default_fields)

      respond_to do |format|
        format.xml{render xml: test_script_results.to_xml(root:
          'test_script_results', skip_types: 'true', include: {test_results: {}})}
        format.json{render json: test_script_results.to_json(include: {test_results: {}})}
      end
    end

    # Sends the contents of the specified Test Script Result
    # Requires: assignment_id, group_id, id
    def show
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      test_script_result = submission.test_script_results.includes(:test_results).find_by_id(params[:id])
     

      #debugger
      #fields = fields_to_render(@@default_fields)

      # Render error if the TestResult does not exist
      if test_script_result.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Test script result was not found'}, status: 404
        return
      end

      respond_to do |format|
        format.xml{render xml: test_script_result.to_xml(root:
          'test_script_result', skip_types: 'true', include: {test_results: {}})}
        format.json{render json: test_script_result.to_json(include: {test_results: {}})}
      end
    end

    # Creates a new test result for a group's latest assignment submission
    # Requires:
    #  - assignment_id
    #  - group_id
    #  - filename: Name of the file to be uploaded
    #  - file_content: Contents of the test results file to be uploaded
    def create
      if has_missing_params?([:file_content])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: {code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422']}, status: 422
        return
      end

      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?
      
      grouping = submission.grouping
      assignment = submission.assignment

      

      if AutomatedTestsHelper.process_result(params[:file_content],
                                          'submission',
                                          assignment,
                                          grouping,
                                          submission)
        render 'shared/http_status', locals: {code: '201', message:
          HttpStatusHelper::ERROR_CODE['message']['201']}, status: 201
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
    end

    # Deletes a Test Script Result instance
    # Requires: assignment_id, group_id, id
    def destroy
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      test_script_result = submission.test_script_results.find_by_id(params[:id])

      # Render error if the TestResult does not exist
      if test_script_result.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Test script result was not found'}, status: 404
        return
      end

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

    # Updates a TestResult instance
    # Requires: assignment_id, group_id, id
    # Optional:
    #  - filename: New name for the file
    #  - file_content: New contents of the test results file
    def update
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      test_result = submission.test_results.find_by_id(params[:id])

      # Render error if the TestResult does not exist
      if test_result.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Test result was not found'}, status: 404
        return
      end

      # Render error if the filename is used by another TestResult for that submission
      existing_file = submission.test_results.find_by_filename(params[:filename])
      if !existing_file.nil? && existing_file.id != params[:id]
        render 'shared/http_status', locals: {code: '409', message:
          'A TestResult with that filename already exists'}, status: 409
        return
      end

      # Update filename if provided
      test_result.filename = params[:filename] if !params[:filename].nil?

      if test_result.save && test_result.update_file_content(params[:file_content])
        # Everything went fine; report success
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200']}, status: 200
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
    end

    # Given assignment and group id's, returns the submission if found, or nil
    # otherwise. Also renders appropriate responses on error.
    def get_submission(assignment_id, group_id)
      assignment = Assignment.find_by_id(assignment_id)
      if assignment.nil?
        # No assignment with that id
        render 'shared/http_status', locals: {code: '404', message:
          'No assignment exists with that id'}, status: 404
        return nil
      end

      group = Group.find_by_id(group_id)
      if group.nil?
        # No group exists with that id
        render 'shared/http_status', locals: {code: '404', message:
          'No group exists with that id'}, status: 404
        return nil
      end

      submission = Submission.get_submission_by_group_and_assignment(
        group[:group_name], assignment[:short_identifier])
      if submission.nil?
        # No assignment submission by that group
        render 'shared/http_status', locals: {code: '404', message:
          'Submission was not found'}, status: 404
      end

      submission
    end

  end # end TestResultsController
end
