# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class AutomatedTestsController < ApplicationController
  include AutomatedTestsHelper

  # This is the waiting list for automated testing. Once a test is requested,
  # it is enqueued and it is waiting for execution. Resque manages this queue.
  @queue = :test_waiting_list

  # Index is called when a test run is requested
  def index                               
         
    submission_id = params[:submission_id]
    @submission = Submission.find(submission_id)
    @grouping = @submission.grouping
    @assignment = @grouping.assignment
    @group = @grouping.group
    
    @repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name)
    export_group_repo(@group, @repo_dir)
                                    
    # TODO: call_on should be passed to index as a parameter. 
    list_call_on = %w(submission request collection)
    call_on = list_call_on[0]
    
    @list_run_scripts = scripts_to_run(@assignment, call_on)
    
    self.async_test_request(submission_id, call_on)
    
    #render :test_replace,
    #       :locals => {:test_result_files => @test_result_files,
    #                   :result => @result}

  end

  #Update is called when files are added to the assigment
  def update
      @assignment = Assignment.find(params[:assignment_id])

      #perform transaction, if errors, none of new config saved
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
          render action => :manage
        end
     end
  end

  # Manage is called when the Test Framework UI is loaded
  def manage
    @assignment = Assignment.find(params[:assignment_id])

    #this is breaking, not actually doing anything so commenting
    #out for now
    # Create test scripts for testing if no script is available
    #if @assignment && @assignment.test_scripts.empty?
     # create_test_scripts(@assignment)
    #end
    
  end

  # This function should only be called by self.perform()
  # Pick a server, launch the Test Runner and wait for the result
  # Then store the result into the database
  def perform(submission_id, call_on)

    @submission = Submission.find(submission_id)
    @grouping = @submission.grouping
    @assignment = @grouping.assignment
    @group = @grouping.group
    @repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name)

    @list_of_servers = MarkusConfigurator.markus_ate_test_server_hosts.split(' ')
    
    while true
      @test_server_id = choose_test_server()
      if @test_server_id >= 0 
        break
      else
        sleep 5               # if no server is available, sleep for 5 second before it checks again
      end  
    end

    result, status = launch_test(@test_server_id, @assignment, @repo_dir, call_on)
    
    process_result(result)

  end
  
  # Perform a job for automated testing. This code is run by
  # the Resque workers - it should not be called from other functions.
  def self.perform(submission_id, call_on)
    # After we enqueue the job to Resque, we wait for a Resque worker
    # to pick up the job. It creates a new instance of the current class
    # and calls perform, where we actually do our work. 
    new().perform(submission_id, call_on)
  end

  # Request an automated test. Ask Resque to enqueue a job.
  def async_test_request(submission_id, call_on)
    if has_permission?
      if files_available? 
        Resque.enqueue(AutomatedTestsController, submission_id, call_on)
      end
    end
  end

end
