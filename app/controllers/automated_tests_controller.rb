# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class AutomatedTestsController < ApplicationController
  include AutomatedTestsHelper

  # This is the waiting list for automated testing. Once a test is requested,
  # it is enqueued and it is waiting for execution. Resque manages this queue.
  @queue = :test_waiting_list

  # Index is called when a test run is requested
  def index
    
    result_id = params[:result]
    @result = Result.find(result_id)
    @submission = @result.submission
    @assignment = @submission.assignment
    @grouping = @submission.grouping
    @group = @grouping.group
    @test_result_files = @submission.test_results
    
    @repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name)
    export_group_repo(@group, @repo_dir)
    
    # BRIAN: How do I know when this is called? Whether at submission, upon request, or after due date??
    # Then I need to figure out which scripts to run (using db columns run_on_*)
    # For now, just assume I have 
    list_call_on = %w(submission request collection)
    call_on = list_call_on[0]
    
    @list_run_scripts = scripts_to_run(@assignment, call_on)
    
    # JUST FOR TESTING: send 5 test requests to Resque
    for i in 1..5
      self.async_test_request(result_id, call_on)
      sleep 3
    end
    
    render :test_replace,
           :locals => {:test_result_files => @test_result_files,
                       :result => @result}

=begin
    result_id = params[:result]
    @result = Result.find(result_id)
    @assignment = @result.submission.assignment
    @submission = @result.submission
    @grouping = @result.submission.grouping
    @group = @grouping.group
    @test_result_files = @submission.test_results
    
    if can_run_test?
      export_repository(@group, File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name))
      copy_ant_files(@assignment, File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name))
      export_configuration_files(@assignment, @group, File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name))
      child_pid = fork {
        run_ant_file(@result, @assignment, File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name))
        Process.exit!(0)
      }
      Process.detach(child_pid) unless child_pid.nil?
    end
    render :test_replace,
           :locals => {:test_result_files => @test_result_files,
                       :result => @result}
=end
  end

  # TODO: REWRITE THIS FOR THE NEW DESIGN
  #Update is called when files are added to the assigment

  def update
      @assignment = Assignment.find(params[:assignment_id])

      @assignment.transaction do

        begin
          # Process testing framework form for validation
          @assignment = process_test_form(@assignment, params)
        rescue Exception, RuntimeError => e
          @assignment.errors.add(:base, I18n.t("assignment.error",
                                               :message => e.message))
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
  def perform(result_id, call_on)
    
    @result = Result.find(result_id)
    @submission = @result.submission
    @assignment = @submission.assignment
    @grouping = @submission.grouping
    @group = @grouping.group
    @repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name)
    
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
  def self.perform(result_id, call_on)
    # After we enqueue the job to Resque, we wait for a Resque worker
    # to pick up the job. It creates a new instance of the current class
    # and calls perform, where we actually do our work. 
    new().perform(result_id, call_on)
  end

  # Request an automated test. Ask Resque to enqueue a job.
  def async_test_request(result_id, call_on)
    if has_permission?
      if files_available? 
        Resque.enqueue(AutomatedTestsController, result_id, call_on)
      else
        #TODO: error message
      end
      #TODO: error message
    end
  end

end
