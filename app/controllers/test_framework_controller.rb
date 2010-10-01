# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class TestFrameworkController < ApplicationController
  include TestFrameworkHelper

  def index
    result_id = params[:result]
    @result = Result.find(result_id)
    @assignment = @result.submission.assignment
    @submission = @result.submission
    @grouping = @result.submission.grouping
    @group = @grouping.group
    @test_result_files = @submission.test_results
    if can_run_test?
      # Ant Execution (Enhancement: Fork another process here to handle this)
      export_repository(@group, File.join(MarkusConfigurator.markus_config_test_framework_repository, @group.repo_name))
	  copy_ant_files(@assignment, File.join(MarkusConfigurator.markus_config_test_framework_repository, @group.repo_name))
      export_configuration_files(@assignment, @group, File.join(MarkusConfigurator.markus_config_test_framework_repository, @group.repo_name))
      run_ant_file(@result, @assignment, File.join(MarkusConfigurator.markus_config_test_framework_repository, @group.repo_name))
    end
    render :action => 'test_replace', :locals => {:test_result_files => @test_result_files, :result => @result}
  end

  def manage
    @assignment = Assignment.find_by_id(params[:id])

    # Create ant test files required by Testing Framework
    create_ant_test_files(@assignment)

    if !request.post?
      return
    end

    @assignment.transaction do

      begin
        # Process testing framework form for validation
        @assignment = process_test_form(@assignment, params)
      rescue Exception, RuntimeError => e
        @assignment.errors.add_to_base(I18n.t("assignment.error", :message => e.message))
        return
      end

      # Save assignment and associated test files
      if @assignment.save
        flash[:success] = I18n.t("assignment.update_success")
        redirect_to :action => 'manage', :id => params[:id]
      else
        render :action => 'manage'
      end
    end
  end

end
