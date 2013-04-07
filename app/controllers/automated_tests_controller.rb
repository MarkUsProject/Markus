# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class AutomatedTestsController < ApplicationController
  include AutomatedTestsHelper

  before_filter      :authorize_only_for_admin,
                     :only => [:manage, :update]
  before_filter      :authorize_for_user,
                     :only => [:index]
                     
  # This is not being used right now. It was the calling interface to 
  # request a test run, however, now you can just call
  # AutomatedTestsHelper.request_a_test_run to send a test request.
  def index                               
    submission_id = params[:submission_id]
    
    # TODO: call_on should be passed to index as a parameter. 
    list_call_on = %w(submission request collection)
    call_on = list_call_on[0]
    
    AutomatedTestsHelper.request_a_test_run(submission_id, call_on, @current_user)
    
    # TODO: render a new partial page
    #render :test_replace,
    #       :locals => {:test_result_files => @test_result_files,
    #                   :result => @result}
  end
  
  # Update is called when files are added to the assigment
  def update
    @assignment = Assignment.find(params[:assignment_id])

    create_test_repo(@assignment)
    
    # Perform transaction, if errors, none of new config saved
    @assignment.transaction do

      begin
        # Process testing framework form for validation
        @assignment = process_test_form(@assignment, params)
      rescue Exception, RuntimeError => e
        @assignment.errors.add(:base, I18n.t("assignment.error",
                                             :message => e.message))
        render :manage
        return        
      end

      # Save assignment and associated test files
      if @assignment.save
        flash[:success] = I18n.t("assignment.update_success")
        redirect_to :action => 'manage',
                    :assignment_id => params[:assignment_id]
      else
        render :manage
      end
        
    end
  end

  # Manage is called when the Automated Test UI is loaded
  def manage
    @assignment = Assignment.find(params[:assignment_id])
  end
  
  def student_interface
    @assignment = Assignment.find(params[:id])
    @student = current_user
    @grouping = @student.accepted_grouping_for(@assignment.id)

    if !@grouping.nil?
      # Look up submission information
      repo = @grouping.group.repo
      @revision  = repo.get_latest_revision
      @revision_number = @revision.revision_number
      
      @test_script_results = TestScriptResult.find_by_grouping_id(@grouping.id)
      
      @token = Token.find_by_grouping_id(@grouping.id)
      if @token
        @token.reassign_tokens_if_new_day()
      end
      
      # For running tests
      if params[:run_tests] && @token && @token.tokens > 0
        run_tests(@grouping.id)
        flash[:notice] = I18n.t("automated_tests.tests_running")
      end
    end
  end
  
  def run_tests(grouping_id)
    changed = 0
    begin
      AutomatedTestsHelper.request_a_test_run(grouping_id, 'request', @current_user)
      return true
    rescue Exception => e
      return false
    end
  end

end
