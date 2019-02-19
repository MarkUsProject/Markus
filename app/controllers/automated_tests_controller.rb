class AutomatedTestsController < ApplicationController
  include AutomatedTestsClientHelper

  before_action      :authorize_only_for_admin,
                     only: [:manage, :update, :download]
  before_action      :authorize_for_student,
                     only: [:student_interface,
                            :get_test_runs_students]

  # Update is called when files are added to the assignment
  def update
    @assignment = Assignment.find(params[:assignment_id])
    create_test_repo(@assignment)

    begin
      @assignment.transaction do
        new_files = process_test_form(@assignment, params, assignment_params)
        run_job = !new_files.empty? || @assignment.test_groups.any?(&:marked_for_destruction?)
        if @assignment.save
          # write the uploaded files
          new_files.each do |file|
            File.open(file[:path], 'wb') { |f| f.write(file[:upload].read) }
            # delete a replaced file if it was renamed
            if file.key?(:delete) && File.exist?(file[:delete])
              File.delete(file[:delete])
            end
          end
          if run_job
            AutotestSpecsJob.perform_later(request.protocol + request.host_with_port, @assignment.id)
          end
          flash_message(:success, t('assignment.update_success'))
        else
          flash_message(:error, @assignment.errors.full_messages)
        end
      end
    rescue => e
      flash_message(:error, e.message)
    ensure
      # TODO the page is not correctly drawn when using render
      redirect_to action: 'manage', assignment_id: params[:assignment_id]
    end
  end

  # Manage is called when the Automated Test UI is loaded
  def manage
    @assignment = Assignment.find(params[:assignment_id])
    @assignment.test_groups.build
    @student_tests_on = MarkusConfigurator.autotest_student_tests_on?
  end

  def student_interface
    @assignment = Assignment.find(params[:id])
    @student = current_user
    @grouping = @student.accepted_grouping_for(@assignment.id)

    unless @grouping.nil?
      @grouping.refresh_test_tokens
      # authorization
      begin
        authorize! @assignment, to: :run_tests? # TODO: Remove it when reasons will have the dependent policy details
        authorize! @grouping, to: :run_tests?
        @authorized = true
      rescue ActionPolicy::Unauthorized => e
        @authorized = false
        flash_now(:notice, e.result.reasons.full_messages.join(' '))
      end
    end

    render layout: 'assignment_content'
  end

  def execute_test_run
    begin
      assignment = Assignment.find(params[:id])
      grouping = current_user.accepted_grouping_for(assignment.id)
      grouping.refresh_test_tokens
      authorize! assignment, to: :run_tests? # TODO: Remove it when reasons will have the dependent policy details
      authorize! grouping, to: :run_tests?
      grouping.decrease_test_tokens
      test_group_ids = assignment.select_test_groups(current_user).pluck(:id)
      test_specs_name = assignment.get_test_specs_name
      hooks_script_name = assignment.get_hooks_script_name
      test_run = grouping.create_test_run!(user: current_user)
      AutotestRunJob.perform_later(request.protocol + request.host_with_port, current_user.id, test_group_ids,
                                   test_specs_name, hooks_script_name, [{ id: test_run.id }])
      flash_message(:notice, I18n.t('automated_tests.tests_running'))
    rescue StandardError => e
      message = e.is_a?(ActionPolicy::Unauthorized) ? e.result.reasons.full_messages.join(' ') : e.message
      flash_message(:error, message)
    end
    redirect_to action: :student_interface, id: params[:id]
  end

  # Download is called when an admin wants to download a test file
  def download
    assignment = Assignment.find(params[:assignment_id])
    file_path = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, assignment.short_identifier, params[:filename])
    if File.exist?(file_path)
      file_contents = IO.read(file_path)
      send_file file_path,
                type: (SubmissionFile.is_binary?(file_contents) ? 'application/octet-stream' : 'text/plain'),
                x_sendfile: true
    else
      flash_message(:error, I18n.t('automated_tests.download_wrong_place_or_unreadable'))
      redirect_to action: 'manage'
    end
  end

  def get_test_runs_students
    @grouping = current_user.accepted_grouping_for(params[:assignment_id])
    test_runs = @grouping.test_runs_students
    render json: test_runs.group_by { |t| t['test_runs.id'] }
  end

  # TODO use authorizations from here on
  # TODO change test_scripts save action + select from existing files
  def fetch_testers
    AutotestTestersJob.perform_later
    head :no_content
  end

  def populate_file_manager
    assignment = Assignment.find(params[:assignment_id])
    autotest_path = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, assignment.short_identifier)
    autotest_files = Dir.entries(autotest_path) - ['.', '..']
    data = autotest_files.map do |file|
      { key: file, size: 1,
        url: download_file_assignment_automated_tests_url(assignment_id: assignment.id, file_name: file) }
    end
    render json: data
  end

  def download_file
    assignment = Assignment.find(params[:assignment_id])
    file_path = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, assignment.short_identifier, params[:file_name])
    if File.exists?(file_path)
      send_file file_path, filename: params[:file_name]
    else
      render plain: t('student.submission.missing_file', file_name: params[:file_name])
    end
  end

  def upload_files
    assignment = Assignment.find(params[:assignment_id])
    delete_files = params[:delete_files] || []
    new_files = params[:new_files] || []
    autotest_path = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, assignment.short_identifier)

    new_files.each do |f|
      if f.size > MarkusConfigurator.markus_config_max_file_size
        flash_message(:error, t('student.submission.file_too_large', file_name: f.original_filename,
                                max_size: (MarkusConfigurator.markus_config_max_file_size / 1_000_000.00).round(2)))
        next
      elsif f.size == 0
        flash_message(:warning, t('student.submission.empty_file_warning', file_name: f.original_filename))
      end
      file_path = File.join(autotest_path, f.original_filename)
      file_content = f.read
      mode = SubmissionFile.is_binary?(file_content) ? 'wb' : 'w'
      File.write(file_path, file_content, mode: mode)
    end
    delete_files.each do |f|
      file_path = File.join(autotest_path, f)
      File.delete(file_path)
    end

    flash_message(:success, t('update_files.success'))
    if new_files
      redirect_back(fallback_location: root_path)
    else
      head :ok
    end
  end

  private

  def assignment_params
    params.require(:assignment)
      .permit(:enable_test,
              :enable_student_tests,
              :assignment_id,
              :tokens_per_period,
              :token_period,
              :token_start_date,
              :non_regenerating_tokens,
              :unlimited_tokens,
              test_groups_attributes:
                [:id, :assignment_id, :name, :run_by_instructors, :run_by_students, :display_output, :criterion_id,
                 :_destroy])
              # test_support_files_attributes:
              #   [:id, :file_name, :assignment_id, :description, :_destroy])
  end
end
