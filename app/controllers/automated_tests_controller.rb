# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class AutomatedTestsController < ApplicationController
  include AutomatedTestsHelper

  # This is the waiting list for automated testing. Once a test is requested,
  # it is enqueued and it is waiting for execution. Resque manages this queue.
  @queue = :test_waiting_list

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
    self.async_test_request
  end

  # Perform a job for automated testing. This code is run by
  # the Resque workers - it should not be called from other functions.
  # Collect all the required files from the given paths and launch
  # the Test Runner on another server
  def self.perform()
    @test_server_id = choose_test_server()#@test_servers
    result, status = launch_test(@test_server_id, @group, @assignment)#there are more parameters...

    # process test result code {{
    test = AutomatedTests.new
    results_xml = results_xml ||
      File.read(Rails.root.to_s + "/automated-tests-files/test.xml")
    parser = XML::Parser.string(results_xml)
    doc = parser.parse

    # get assignment_id
    assignment_node = doc.find_first("/test/assignment-id")
    if not assignment_node or assignment_node.empty?
      raise "Test result does not have assignment id"
    else
      test.assignment_id = assignment_node.content
    end

    # get group id
    group_id_node = doc.find_first("/test/group-id")
    if not group_id_node or group_id_node.empty?
      raise "Test result has no group id"
    else
      test.group_id = group_id_node.content
    end

    # get pretests
    pretest_results = ""
    doc.find("/test/pretest").each { |pretest_node|
      pretest_results += pretest_node.to_s
    }
    test.pretest_result = pretest_results

    # get builds
    build_results = ""
    doc.find("/test/build").each { |build_node|
      build_results += build_node.to_s
    }
    test.build_result = build_results

    # get tests
    test_script_results = ""
    doc.find("/test/test-script").each { |test_script_node|
      test_script_results += test_script_node.to_s
    }
    test.test_script_result = test_script_results
    puts test.inspect
    test.save
    # }}
  end

  # Request an automated test. Ask Resque to enqueue a job.
  def async_test_request
    if has_permission?
      if files_available? 
        Resque.enqueue(AutomatedTestsController)
      else
        #TODO: error message
      end
      #TODO: error message
    end
  end

end
