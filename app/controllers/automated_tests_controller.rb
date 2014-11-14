# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class AutomatedTestsController < ApplicationController
  include AutomatedTestsHelper

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
           format: :js,
           locals: { test_result_files: @test_result_files,
                     result: @result }
  end


  #Update function called when files are added to the assignment

  def update
      @assignment = Assignment.find(params[:assignment_id])

      @assignment.transaction do

        begin
          # Process testing framework form for validation
          @assignment = process_test_form(@assignment, assignment_params)
        rescue Exception, RuntimeError => e
          @assignment.errors.add(:base, I18n.t('assignment.error',
            message: e.message))
          return redirect_to action: 'manage',
            assignment_id: params[:assignment_id]
        end

        # Save assignment and associated test files
        if @assignment.save
          flash[:success] = I18n.t('assignment.update_success')
          redirect_to action: 'manage',
            assignment_id: params[:assignment_id]
        else
          render :manage
        end
     end
  end


  def manage
    @assignment = Assignment.find(params[:assignment_id])

    # Create ant test files required by Testing Framework
    create_ant_test_files(@assignment)

  end

  private

  def assignment_params
    params.require(:assignment)
          .permit(:enable_test,
                  :assignment_id,
                  test_files_attributes:
                  [:id, :filename, :filetype, :is_private, :_destroy])
  end
end
