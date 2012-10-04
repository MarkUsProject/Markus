# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class AutomatedTestsController < ApplicationController
  include AutomatedTestsHelper

  # This is the waiting list for automated testing. Once a test is requested,
  # it is enqueued and it is waiting for execution. Resque manages this queue. 
  #@queue = :test_waiting_list

  # TODO: REWRITE THIS FOR THE NEW DESIGN
  def index
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
  end

  # TODO: REWRITE THIS FOR THE NEW DESIGN
  #Update function called when files are added to the assigment

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

  # TODO: REWRITE THIS FOR THE NEW DESIGN
  def manage
    @assignment = Assignment.find(params[:assignment_id])

    # Create ant test files required by Testing Framework
    create_ant_test_files(@assignment)

  end

  # Perform a job for automated testing. This code is run by
  # the Resque workers - it should not be called from other functions.
  # Collect all the required files from the given paths and launch 
  # the Test Runner on another server 
  def self.perform()
    
    choose_test_server()
    launch_test()
    
    # BRIAN: busy waiting for result? Another idea will be creating another kind of jobs that check for the result
    if result_available?
      process_result()
    end
    
  end

  # Request an automated test. Ask Resque to enqueue a job.
  def async_test_request
    Resque.enqueue(automated_tests_controller)
  end

end
