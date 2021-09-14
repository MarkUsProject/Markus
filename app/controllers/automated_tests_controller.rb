class AutomatedTestsController < ApplicationController
  include AutomatedTestsHelper

  before_action { authorize! }

  content_security_policy only: :manage do |p|
    # required because jquery-ui-timepicker-addon inserts style
    # dynamically. TODO: remove this when possible
    p.style_src :self, "'unsafe-inline'"
    # required because @rjsf/core uses ajv which calls
    # eval (javascript) and creates an image as a blob.
    # TODO: remove this when possible
    p.script_src :self, "'strict-dynamic'", "'unsafe-eval'"
  end

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
      @authorized = flash_allowance(:notice,
                                    allowance_to(:run_tests?,
                                                 current_user,
                                                 context: { assignment: @assignment, grouping: @grouping })).value
    end

    render layout: 'assignment_content'
  end

  def execute_test_run
    assignment = Assignment.find(params[:id])
    grouping = current_user.accepted_grouping_for(assignment.id)
    grouping.refresh_test_tokens
    allowed = flash_allowance(:error, allowance_to(:run_tests?,
                                                   current_user,
                                                   context: { assignment: assignment, grouping: grouping })).value
    if allowed
      grouping.decrease_test_tokens
      @current_job = AutotestRunJob.perform_later(request.protocol + request.host_with_port,
                                                  current_user.id,
                                                  assignment.id,
                                                  [grouping.group_id],
                                                  collected: false)
      session[:job_id] = @current_job.job_id
      flash_message(:notice, I18n.t('automated_tests.tests_running'))
    end
  rescue StandardError => e
    flash_message(:error, e.message)
  ensure
    redirect_to action: :student_interface, id: params[:id]
  end

  def get_test_runs_students
    @grouping = current_user.accepted_grouping_for(params[:assignment_id])
    test_runs = @grouping.test_runs_students
    test_runs.each do |test_run|
      test_run['test_runs.created_at'] = I18n.l(test_run['test_runs.created_at'])
    end
    render json: test_runs.group_by { |t| t['test_runs.id'] }
  end

  def populate_autotest_manager
    assignment = Assignment.find(params[:assignment_id])
    testers_schema_path = File.join(Settings.autotest.client_dir, 'testers.json')
    files_dir = Pathname.new assignment.autotest_files_dir
    file_keys = []
    files_data = assignment.autotest_files.map do |file|
      if files_dir.join(file).directory?
        { key: "#{file}/" }
      else
        file_keys << file
        time = ''
        if files_dir.join(file).exist?
          time = I18n.l(File.mtime(files_dir.join(file)).in_time_zone(current_user.time_zone))
        end
        { key: file, size: 1, submitted_date: time,
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
    assignment_data['token_start_date'] ||= Time.current
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

    upload_files_helper(new_folders, new_files, unzip: unzip) do |f|
      if f.is_a?(String) # is a directory
        folder_path = File.join(assignment.autotest_files_dir, params[:path], f)
        FileUtils.mkdir_p(folder_path)
      else
        if f.size > Settings.max_file_size
          flash_now(:error, t('student.submission.file_too_large',
                              file_name: f.original_filename,
                              max_size: (Settings.max_file_size / 1_000_000.00).round(2)))
          next
        elsif f.size == 0
          flash_now(:warning, t('student.submission.empty_file_warning', file_name: f.original_filename))
        end
        file_path = File.join(assignment.autotest_files_dir, params[:path], f.original_filename)
        FileUtils.mkdir_p(File.dirname(file_path))
        file_content = f.read
        File.write(file_path, file_content, mode: 'wb')
      end
    end
    delete_folders.each do |f|
      folder_path = File.join(assignment.autotest_files_dir, f)
      FileUtils.rm_rf(folder_path)
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
      specs = JSON.parse File.read(file_path)
      specs['testers']&.each do |tester_info|
        tester_info['test_data']&.each do |test_info|
          test_info['extra_info']&.delete('test_group_id')
        end
      end
      send_data specs.to_json, filename: TestRun::SPECS_FILE
    else
      send_data '{}', filename: TestRun::SPECS_FILE
    end
  end

  def upload_specs
    assignment = Assignment.find(params[:assignment_id])
    if params[:specs_file].respond_to? :read
      file_content = params[:specs_file].read
      begin
        test_specs = JSON.parse file_content
        update_test_groups_from_specs(assignment, test_specs)
      rescue JSON::ParserError
        flash_now(:error, I18n.t('automated_tests.invalid_specs_file'))
        head :unprocessable_entity
      rescue StandardError => e
        flash_now(:error, e.message)
        head :unprocessable_entity
      else
        @current_job = AutotestSpecsJob.perform_later(request.protocol + request.host_with_port, assignment)
        session[:job_id] = @current_job.job_id
        render 'shared/_poll_job.js.erb'
      end
    else
      head :unprocessable_entity
    end
  end

  protected

  def implicit_authorization_target
    OpenStruct.new policy_class: AutomatedTestPolicy
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
