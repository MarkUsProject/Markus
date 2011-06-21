module Api

  #=== Description
  # Allows for pushing of test results into MarkUs (e.g. from automated test runs).
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class TestResultsController < MainApiController

    #=== Description
    # Triggered by a HTTP POST request to /api/test_results(.:format).
    # Creates a new TestResult instance. Requires the following parameters:
    #   group_name:   Name of the group to which the test result should be associated to
    #   assignment:   Short identifier of the assignment
    #   filename:     Filename of the test result
    #   file_content: Content of the test results
    #=== Returns
    # An XML response, indicating the success/failure for the request
    def create
      if !request.post?
        # pretend this URL does not exist
        render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
        return
      end
      if !has_required_http_params_including_file_content?(params)
        # incomplete/invalid HTTP params
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end
      # check if there's a valid submission
      submission = Submission.get_submission_by_group_and_assignment(params[:group_name],
                                                                      params[:assignment])
      if submission.nil?
        # no such submission
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end
      # Request seems good. Check if filename already exists.
      # If it does, update it instead of creating a new one.
      new_test_result = submission.test_results.find_by_filename(params[:filename])
      if new_test_result.nil?
        if TestResult.create(:filename => params[:filename],
           :file_content => params[:file_content],
           :submission_id => submission.id)
          # All good, so return a success response
          render :file => "#{RAILS_ROOT}/public/200.xml", :status => 200
          return
        else
          # Some other error occurred
          render :file => "#{RAILS_ROOT}/public/500.xml", :status => 500
          return
        end
      else
        new_test_result.file_content = params[:file_content]
        if new_test_result.save
          # All good, so return a success response
          render :file => "#{RAILS_ROOT}/public/200.xml", :status => 200
          return
        else
          # Some other error occurred
          render :file => "#{RAILS_ROOT}/public/500.xml", :status => 500
          return
        end
      end
    end

    #=== Description
    # Triggered by a HTTP DELETE request to /api/test_results(.:format).
    # Deletes a TestResult instance. Requires the following parameters:
    #   group_name:   Name of the group to which the test result should be associated to
    #   assignment:   Short identifier of the assignment
    #   filename:     Filename of the test result to be deleted
    #=== Returns
    # An XML response, indicating the success/failure for the request
    def destroy
      if !request.delete?
        # pretend this URL does not exist
        render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
        return
      end
      if !has_required_http_params?(params)
        # incomplete/invalid HTTP params
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end
      # check if there's a valid submission
      submission = Submission.get_submission_by_group_and_assignment(params[:group_name],
                                                                      params[:assignment])
      if submission.nil?
        # no such submission
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end
      # request seems good
      test_result = submission.test_results.find_by_filename(params[:filename])
      if !test_result.nil?
        if test_result.destroy
          # Everything went fine; report success
          render :file => "#{RAILS_ROOT}/public/200.xml", :status => 200
          return
        else
          # Some other error occurred
          render :file => "#{RAILS_ROOT}/public/500.xml", :status => 500
          return
        end
      end
      # The test result in question does not exist
      render :file => "#{RAILS_ROOT}/public/404.xml", :status => 404
      return
    end

    #=== Description
    # Triggered by a HTTP PUT request to /api/test_results(.:format).
    # Updates (overwrites) a TestResult instance. Requires the following parameters:
    #   group_name:   Name of the group to which the test result should be associated to
    #   assignment:   Short identifier of the assignment
    #   filename:     Filename of the test result, which content should be updated
    #   file_content: New content of the test result
    #=== Returns
    # An XML response, indicating the success/failure for the request
    def update
      if !request.put?
        # pretend this URL does not exist
        render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
        return
      end
      if !has_required_http_params_including_file_content?(params)
        # incomplete/invalid HTTP params
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end
      # check if there's a valid submission
      submission = Submission.get_submission_by_group_and_assignment(params[:group_name],
                                                                      params[:assignment])
      if submission.nil?
        # no such submission
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end
      # request seems good
      test_result = submission.test_results.find_by_filename(params[:filename])
      if !test_result.nil?
        if test_result.update_file_content(params[:file_content])
          # Everything went fine; report success
          render :file => "#{RAILS_ROOT}/public/200.xml", :status => 200
          return
        else
          # Some other error occurred
          render :file => "#{RAILS_ROOT}/public/500.xml", :status => 500
          return
        end
      end
      # The test result in question does not exist
      render :file => "#{RAILS_ROOT}/public/404.xml", :status => 404
      return
    end

    #=== Description
    # Triggered by a HTTP GET request to /api/test_results(.:format).
    # Shows a TestResult instance. Requires the following parameters:
    #   group_name:   Name of the group to which the test result should be associated to
    #   assignment:   Short identifier of the assignment
    #   filename:     New filename of the test result
    #=== Returns
    # The content of the test result file in question
    def show
      if !request.get?
        # pretend this URL does not exist
        render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
        return
      end
      if !has_required_http_params?(params)
        # incomplete/invalid HTTP params
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end
      # check if there's a valid submission
      submission = Submission.get_submission_by_group_and_assignment(params[:group_name],
                                                                      params[:assignment])
      if submission.nil?
        # no such submission
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end
      # request seems good
      test_result = submission.test_results.find_by_filename(params[:filename])
      if !test_result.nil?
        # Everything went fine; send file_content
        send_data test_result.file_content, :disposition => 'inline',
                                            :filename => test_result.filename
        return
      end
      # The test result in question does not exist
      render :file => "#{RAILS_ROOT}/public/404.xml", :status => 404
      return
    end

    private

    # Helper method to check for required HTTP parameters
    def has_required_http_params?(param_hash)
      # Note: The blank? method is a Rails extension.
      # Specific keys have to be present, and their values
      # must not be blank.
      if !param_hash[:filename].blank? &&
   !param_hash[:assignment].blank? &&
   !param_hash[:group_name].blank?
  return true
      else
        return false
      end
    end

    # Helper method to check for required HTTP parameters including the
    # file_content parameter
    def has_required_http_params_including_file_content?(param_hash)
      if has_required_http_params?(param_hash)
        if !param_hash[:file_content].blank?
          return true
        end
      end
      return false
    end

  end # end TestResultsController

end
