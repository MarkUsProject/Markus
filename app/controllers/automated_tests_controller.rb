class AutomatedTestsController < ApplicationController
  include AutomatedTestsHelper

  before_action      :authorize_only_for_admin,
                     except: [:student_interface,
                              :get_test_runs_students,
                              :execute_test_run]

  before_action      :authorize_for_student,
                     only: [:student_interface,
                            :get_test_runs_students,
                            :execute_test_run]

  def update
    assignment = Assignment.find(params[:assignment_id])
    test_specs = params[:schema_form_data]
    Assignment.transaction do
      assignment.update! assignment_params
      update_test_groups_from_specs(assignment, test_specs)
      @current_job = AutotestSpecsJob.perform_later(request.protocol + request.host_with_port, assignment)
      session[:job_id] = @current_job.job_id
    rescue StandardError => e
      flash_message(:error, e.message)
      raise ActiveRecord::Rollback
    end
    # TODO: the page is not correctly drawn when using render
    redirect_to action: 'manage', assignment_id: params[:assignment_id]
  end

  # Manage is called when the Automated Test UI is loaded
  def manage
    @assignment = Assignment.find(params[:assignment_id])
    @assignment.test_groups.build
    render layout: 'assignment_content'
  end

  def student_interface
    @assignment = Assignment.find(params[:id])
    @student = current_user
    @grouping = @student.accepted_grouping_for(@assignment.id)

    unless @grouping.nil?
      @grouping.refresh_test_tokens
      # authorization
      begin
        authorize! @assignment, to: :run_tests?
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
      authorize! assignment, to: :run_tests?
      authorize! grouping, to: :run_tests?
      grouping.decrease_test_tokens
      test_run = grouping.create_test_run!(user: current_user)
      @current_job = AutotestRunJob.perform_later(request.protocol + request.host_with_port,
                                                  current_user.id,
                                                  assignment.id,
                                                  [{ id: test_run.id }])
      session[:job_id] = @current_job.job_id
      flash_message(:notice, I18n.t('automated_tests.tests_running'))
    rescue StandardError => e
      message = e.is_a?(ActionPolicy::Unauthorized) ? e.result.reasons.full_messages.join(' ') : e.message
      flash_message(:error, message)
    end
    redirect_to action: :student_interface, id: params[:id]
  end

  def get_test_runs_students
    @grouping = current_user.accepted_grouping_for(params[:assignment_id])
    test_runs = @grouping.test_runs_students
    render json: test_runs.group_by { |t| t['test_runs.id'] }
  end

  def populate_autotest_manager
    assignment = Assignment.find(params[:assignment_id])
    testers_schema_path = File.join(Rails.configuration.x.autotest.client_dir, 'testers.json')
    files_dir = Pathname.new assignment.autotest_files_dir
    file_keys = []
    files_data = assignment.autotest_files.map do |file|
      if files_dir.join(file).directory?
        { key: "#{file}/" }
      else
        file_keys << file
        { key: file, size: 1,
          url: download_file_assignment_automated_tests_url(assignment_id: assignment.id, file_name: file) }
      end
    end
    if File.exist? testers_schema_path
      schema_data = JSON.parse(File.open(testers_schema_path, &:read))
      fill_in_schema_data!(schema_data, file_keys, assignment)
    else
      flash_now(:notice, I18n.t('automated_tests.loading_specs'))
      @current_job = AutotestTestersJob.perform_later
      session[:job_id] = @current_job.job_id
      schema_data = {}
    end
    test_specs_path = assignment.autotest_settings_file
    test_specs = File.exist?(test_specs_path) ? JSON.parse(File.open(test_specs_path, &:read)) : {}
    assignment_data = assignment.assignment_properties.attributes.slice(*required_params.map(&:to_s))
    assignment_data['token_start_date'] ||= Time.zone.now
    assignment_data['token_start_date'] = assignment_data['token_start_date'].strftime('%Y-%m-%d %l:%M %p')
    data = { schema: schema_data, files: files_data, formData: test_specs }.merge(assignment_data)
    render json: data
  end

  def download_file
    assignment = Assignment.find(params[:assignment_id])
    file_path = File.join(assignment.autotest_files_dir, params[:file_name])
    filename = File.basename params[:file_name]
    if File.exist?(file_path)
      send_file_download file_path, filename: filename
    else
      render plain: t('student.submission.missing_file', file_name: filename)
    end
  end

  ##
  # Download all files from the assignment.autotest_files_dir directory as a zip file
  ##
  def download_files
    assignment = Assignment.find(params[:assignment_id])
    zip_path = assignment.zip_automated_test_files(current_user)
    send_file zip_path, filename: File.basename(zip_path)
  end

  def upload_files
    assignment = Assignment.find(params[:assignment_id])
    new_folders = params[:new_folders] || []
    delete_folders = params[:delete_folders] || []
    delete_files = params[:delete_files] || []
    new_files = params[:new_files] || []
    unzip = params[:unzip] == 'true'

    if unzip
      zdirs, zfiles = new_files.map do |f|
        next unless File.extname(f.path).casecmp?('.zip')
        unzip_uploaded_file(f.path)
      end.compact.transpose.map(&:flatten)
      new_files.reject! { |f| File.extname(f.path).casecmp?('.zip') }
      new_folders.push(*zdirs)
      new_files.push(*zfiles)
    end

    new_folders.each do |f|
      folder_path = File.join(assignment.autotest_files_dir, params[:path], f)
      FileUtils.mkdir_p(folder_path)
    end
    delete_folders.each do |f|
      folder_path = File.join(assignment.autotest_files_dir, f)
      FileUtils.rm_rf(folder_path)
    end
    new_files.each do |f|
      if f.size > Rails.configuration.max_file_size
        flash_now(:error, t('student.submission.file_too_large',
                            file_name: f.original_filename,
                            max_size: (Rails.configuration.max_file_size / 1_000_000.00).round(2)))
        next
      elsif f.size == 0
        flash_now(:warning, t('student.submission.empty_file_warning', file_name: f.original_filename))
      end
      file_path = File.join(assignment.autotest_files_dir, params[:path], f.original_filename)
      file_content = f.read
      File.write(file_path, file_content, mode: 'wb')
    end
    delete_files.each do |f|
      file_path = File.join(assignment.autotest_files_dir, f)
      File.delete(file_path)
    end
    render partial: 'update_files'
  end

  def download_specs
    assignment = Assignment.find(params[:assignment_id])
    file_path = assignment.autotest_settings_file
    if File.exist?(file_path)
      send_file file_path, filename: params[:file_name]
    else
      send_data '{}', filename: file_path
    end
  end

  def upload_specs
    assignment = Assignment.find(params[:assignment_id])
    if params[:specs_file].respond_to? :read
      file_content = params[:specs_file].read
      begin
        JSON.parse file_content
      rescue JSON::ParserError
        flash_now(:error, I18n.t('automated_tests.invalid_specs_file'))
        head :unprocessable_entity
      else
        File.write(assignment.autotest_settings_file, file_content, mode: 'wb')
        @current_job = AutotestSpecsJob.perform_later(request.protocol + request.host_with_port, assignment)
        session[:job_id] = @current_job.job_id
        render 'shared/_poll_job.js.erb'
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def required_params
    [:enable_test, :enable_student_tests, :tokens_per_period, :token_period, :token_start_date,
     :non_regenerating_tokens, :unlimited_tokens]
  end

  def assignment_params
    params.require(:assignment).permit(*required_params)
  end
end
