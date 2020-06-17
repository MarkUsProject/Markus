class AssignmentsController < ApplicationController
  include RepositoryHelper
  responders :flash

  before_action      :authorize_only_for_admin,
                     except: [:index,
                              :show,
                              :peer_review,
                              :summary,
                              :switch_assignment,
                              :start_timed_assignment]

  before_action      :authorize_for_ta_and_admin,
                     only: [:summary]

  before_action      :authorize_for_student,
                     only: [:show,
                            :peer_review,
                            :start_timed_assignment]

  before_action      :authorize_for_user,
                     only: [:index, :switch_assignment]

  # Publicly accessible actions ---------------------------------------

  def show
    assignment = Assignment.find(params[:id])
    @assignment = assignment.is_peer_review? ? assignment.parent_assignment : assignment
    if @assignment.is_hidden
      render 'shared/http_status',
             formats: [:html],
             locals: {
               code: '404',
               message: HttpStatusHelper::ERROR_CODE['message']['404']
             },
             status: 404,
             layout: false
      return
    end

    @grouping = current_user.accepted_grouping_for(@assignment.id)

    if @grouping.nil?
      if @assignment.scanned_exam
        flash_now(:notice, t('assignments.scanned_exam.under_review'))
      elsif @assignment.group_max == 1
        begin
          current_user.create_group_for_working_alone_student(@assignment.id)
        rescue StandardError => e
          flash_message(:error, e.message)
          redirect_to controller: :assignments
        end
        @grouping = @current_user.accepted_grouping_for(@assignment.id)
      end
    end
    set_repo_vars(@assignment, @grouping) unless @grouping.nil?
    render layout: 'assignment_content'
  end

  def peer_review
    assignment = Assignment.find(params[:id])
    @assignment = assignment.is_peer_review? ? assignment : assignment.pr_assignment
    if @assignment.nil? || @assignment.is_hidden
      render 'shared/http_status',
             formats: [:html],
             locals: {
                 code: '404',
                 message: HttpStatusHelper::ERROR_CODE['message']['404']
             },
             status: 404,
             layout: false
      return
    end

    @student = current_user
    @grouping = current_user.accepted_grouping_for(@assignment.id)
    @prs = current_user.grouping_for(@assignment.parent_assignment.id)&.
        peer_reviews&.where(results: { released_to_students: true })
    if @prs.nil?
      @prs = []
    end

    if @assignment.past_all_collection_dates?
      flash_now(:notice, t('submissions.grading_can_begin'))
    else
      if @assignment.section_due_dates_type
        section_due_dates = Hash.new
        now = Time.zone.now
        Section.all.each do |section|
          collection_time = @assignment.submission_rule.calculate_collection_time(section)
          collection_time = now if now >= collection_time
          if section_due_dates[collection_time].nil?
            section_due_dates[collection_time] = Array.new
          end
          section_due_dates[collection_time].push(section.name)
        end
        section_due_dates.each do |collection_time, sections|
          sections = sections.join(', ')
          if collection_time == now
            flash_now(:notice, t('submissions.grading_can_begin_for_sections',
                                 sections: sections))
          else
            flash_now(:notice, t('submissions.grading_can_begin_after_for_sections',
                                 time: l(collection_time),
                                 sections: sections))
          end
        end
      else
        collection_time = @assignment.submission_rule.calculate_collection_time
        flash_now(:notice, t('submissions.grading_can_begin_after',
                             time: l(collection_time)))
      end
    end
  end

  # Displays "Manage Assignments" page for creating and editing assignment information.
  # Acts as dashboard for students and TAs.
  def index
    if current_user.student?
      @a_id_results = {}
      accepted_groupings = current_user.accepted_groupings.includes(:assignment, { current_submission_used: :results })
      accepted_groupings.each do |grouping|
        if !grouping.assignment.is_hidden && grouping.has_submission?
          submission = grouping.current_submission_used
          if submission.has_remark? && submission.remark_result.released_to_students
            @a_id_results[grouping.assignment.id] = submission.remark_result
          elsif submission.has_result? && submission.get_original_result.released_to_students
            @a_id_results[grouping.assignment.id] = submission.get_original_result
          end
        end
      end

      @g_id_entries = {}
      current_user.grade_entry_students.where(released_to_student: true).includes(:grade_entry_form).each do |g|
        unless g.grade_entry_form.is_hidden
          @g_id_entries[g.assessment_id] = g
        end
      end

      render :student_assignment_list, layout: 'assignment_content'
    else
      render :index, layout: 'assignment_content'
    end
  end

  # Called on editing assignments (GET)
  def edit
    @assignment = Assignment.find_by_id(params[:id])
    past_date = @assignment.section_names_past_due_date
    @assignments = Assignment.all
    @sections = Section.all

    unless @assignment.scanned_exam
      if @assignment.past_collection_date?
        flash_now(:notice, t('assignments.due_date.final_due_date_passed'))
      elsif !past_date.blank?
        flash_now(:notice, t('assignments.due_date.past_due_date_notice') + past_date.join(', '))
      end
    end
    # build section_due_dates for each section that doesn't already have a due date
    Section.all.each do |s|
      unless SectionDueDate.find_by(assessment_id: @assignment.id, section_id: s.id)
        @assignment.section_due_dates.build(section: s)
      end
    end
    @section_due_dates = @assignment.section_due_dates
                                    .sort_by { |s| [SectionDueDate.due_date_for(s.section, @assignment), s.section.name] }
  end

  # Called when editing assignments form is submitted (PUT).
  def update
    @assignment = Assignment.find_by_id(params[:id])
    @assignments = Assignment.all
    @sections = Section.all

    begin
      new_required_files = false
      @assignment.transaction do
        @assignment, new_required_files = process_assignment_form(@assignment)
        @assignment.save!
      end
      if new_required_files && !Rails.configuration.x.repository.hooks.empty?
        # update list of required files in all repos only if there is a hook that will use that list
        @current_job = UpdateRepoRequiredFilesJob.perform_later(@assignment.id, current_user.user_name)
        session[:job_id] = @current_job.job_id
      end
    rescue
    end
    respond_with @assignment, location: -> { edit_assignment_path(@assignment) }
  end

  # Called in order to generate a form for creating a new assignment.
  # i.e. GET request on assignments/new
  def new
    @assignments = Assignment.all
    @assignment = Assignment.new
    if params[:scanned].present?
      @assignment.scanned_exam = true
    end
    if params[:timed].present?
      @assignment.is_timed = true
    end
    @clone_assignments = Assignment.joins(:assignment_properties)
                                   .where(assignment_properties: { vcs_submit: true })
                                   .order(:id)
    @sections = Section.all

    # build section_due_dates for each section
    Section.all.each { |s| @assignment.section_due_dates.build(section: s)}
    @section_due_dates = @assignment.section_due_dates
                                    .sort_by { |s| s.section.name }

    # set default value if web submits are allowed
    @assignment.allow_web_submits = !Rails.configuration.x.repository.external_submits_only
    render :new
  end

  # Called after a new assignment form is submitted.
  def create
    @assignment = Assignment.new
    @assignment.transaction do
      begin
        @assignment, new_required_files = process_assignment_form(@assignment)
        @assignment.token_start_date = @assignment.due_date
        @assignment.token_period = 1
      rescue Exception, RuntimeError => e
        @assignment.errors.add(:base, e.message)
        new_required_files = false
      end
      unless @assignment.save
        @assignments = Assignment.all
        @sections = Section.all
        @clone_assignments = Assignment.joins(:assignment_properties)
                                       .where(assignment_properties: { vcs_submit: true })
                                       .order(:id)
        respond_with @assignment, location: -> { new_assignment_path(@assignment) }
        return
      end
      if params[:persist_groups_assignment]
        clone_warnings = @assignment.clone_groupings_from(params[:persist_groups_assignment])
        unless clone_warnings.empty?
          clone_warnings.each { |w| flash_message(:warning, w) }
        end
      end
      if new_required_files && !Rails.configuration.x.repository.hooks.empty?
        # update list of required files in all repos only if there is a hook that will use that list
        @current_job = UpdateRepoRequiredFilesJob.perform_later(@assignment.id, current_user.user_name)
        session[:job_id] = @current_job.job_id
      end
    end
    respond_with @assignment, location: -> { edit_assignment_path(@assignment) }
  end

  def summary
    @assignment = Assignment.find(params[:id])
    respond_to do |format|
      format.html { render layout: 'assignment_content' }
      format.json { render json: @assignment.summary_json(@current_user) }
      format.csv do
        data = @assignment.summary_csv(@current_user)
        filename = "#{@assignment.short_identifier}_summary.csv"
        send_data data,
                  disposition: 'attachment',
                  type: 'text/csv',
                  filename: filename
      end
    end
  end

  def stop_test
    test_id = params[:test_run_id].to_i
    assignment_id = params[:id]
    @current_job = AutotestCancelJob.perform_later(request.protocol + request.host_with_port, assignment_id, [test_id])
    session[:job_id] = @current_job.job_id
    redirect_back(fallback_location: root_path)
  end

  def stop_batch_tests
    test_runs = TestRun.where(test_batch_id: params[:test_batch_id]).pluck(:id)
    assignment_id = params[:id]
    @current_job = AutotestCancelJob.perform_later(request.protocol + request.host_with_port, assignment_id, test_runs)
    session[:job_id] = @current_job.job_id
    redirect_back(fallback_location: root_path)
  end

  def batch_runs
    @assignment = Assignment.find(params[:id])

    respond_to do |format|
      format.html
      format.json do
        user_ids = current_user.admin? ? Admin.pluck(:id) : current_user.id
        test_runs = TestRun.left_outer_joins(:test_batch, grouping: [:group, :current_result])
                           .where(test_runs: {user_id: user_ids},
                                  'groupings.assessment_id': @assignment.id)
                           .pluck_to_hash(:id,
                                          :test_batch_id,
                                          :time_to_service,
                                          :grouping_id,
                                          :submission_id,
                                          'test_batches.created_at',
                                          'test_runs.created_at',
                                          'groups.group_name',
                                          'results.id')
        status_hash = TestRun.statuses(test_runs.map { |tr| tr[:id] })
        test_batches = TestBatch.where(id: (test_runs.map { |tr| tr[:test_batch_id] }).compact.uniq)
        time_to_completion_hashes = test_batches.map(&:time_to_completion_hash)
        time_estimates = time_to_completion_hashes.empty? ? Hash.new : time_to_completion_hashes.inject(&:merge)
        test_runs.each do |test_run|
          created_at_raw = test_run.delete('test_batches.created_at') || test_run.delete('test_runs.created_at')
          test_run['created_at'] = I18n.l(created_at_raw)
          test_run['status'] = status_hash[test_run['id']]
          test_run['time_to_completion'] = time_estimates[test_run['id']] || ''
          test_run['group_name'] = test_run.delete('groups.group_name')
          test_run['result_id'] = test_run.delete('results.id')
        end
        render json: test_runs
      end
    end
  end

  # Refreshes the grade distribution graph
  def refresh_graph
    @assignment = Assignment.find(params[:id])
    @assignment.assignment_stat.refresh_grade_distribution
    respond_to do |format|
      format.js
    end
  end

  def view_summary
    @assignment = Assignment.find(params[:id])
    @current_ta = @assignment.tas.first
    @tas = @assignment.tas unless @assignment.nil?
  end

  def download
    format = params[:format]
    case format
    when 'csv'
      output = Assignment.get_assignment_list(format)
      send_data(output,
                filename: 'assignments.csv',
                type: 'text/csv',
                disposition: 'attachment')
    when 'yml'
      output = Assignment.get_assignment_list(format)
      send_data(output,
                filename: 'assignments.yml',
                type: 'text/yml',
                disposition: 'attachment')
    else
      flash[:error] = t('download_errors.unrecognized_format', format: format)
      redirect_to action: 'index', id: params[:id]
    end
  end

  def upload
    begin
      data = process_file_upload
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      if data[:type] == '.csv'
        result = Assignment.upload_assignment_list('csv', data[:file].read)
        flash_message(:error, result[:invalid_lines]) unless result[:invalid_lines].empty?
        flash_message(:success, result[:valid_lines]) unless result[:valid_lines].empty?
      elsif data[:type] == '.yml'
        result = Assignment.upload_assignment_list('yml', data[:contents])
        if result.is_a?(StandardError)
          flash_message(:error, result.message)
        end
      end
    end
    redirect_to action: 'index'
  end

  def populate_file_manager
    assignment = Assignment.find(params[:id])
    entries = []
    assignment.access_starter_code_repo do |repo|
      revision = repo.get_latest_revision
      entries = get_all_file_data(revision, assignment, '')
    end
    entries.reject! { |f| Repository.get_class.internal_file_names.include? f[:raw_name] }
    render json: entries
  end

  def upload_starter_code
    unless Rails.configuration.starter_code_on
      raise t('student.submission.external_submit_only') #TODO: Update this
    end

    @assignment = Assignment.find(params[:id])

    path = params[:path] || '/'
    path = Pathname.new(@assignment.repository_folder).join(path.gsub(%r{^/}, ''))

    # The files that will be deleted
    delete_files = params[:delete_files] || []

    # The files that will be added
    new_files = params[:new_files] || []

    # The folders that will be added
    new_folders = params[:new_folders] || []

    # The folders that will be deleted
    delete_folders = params[:delete_folders] || []

    if delete_files.empty? && new_files.empty? && new_folders.empty? && delete_folders.empty?
      flash_message(:warning, I18n.t('student.submission.no_action_detected'))
      redirect_back(fallback_location: root_path)
    else
      messages = []
      @assignment.access_starter_code_repo do |repo|
        # Create transaction, setting the author.
        txn = repo.get_transaction(current_user.user_name, I18n.t('repo.commits.starter_code',
                                                                  assignment: @assignment.short_identifier))
        should_commit = true
        if delete_files.present?
          success, msgs = remove_files(delete_files, current_user, repo, path: path, txn: txn)
          should_commit &&= success
          messages.concat msgs
        end
        if new_files.present?
          success, msgs = add_files(new_files, current_user, repo, path: path, txn: txn, check_size: true)
          should_commit &&= success
          messages.concat msgs
        end
        if new_folders.present?
          success, msgs = add_folders(new_folders, current_user, repo, path: path, txn: txn)
          should_commit &&= success
          messages = messages.concat msgs
        end
        if delete_folders.present?
          success, msgs = remove_folders(delete_folders, current_user, repo, path: path, txn: txn)
          should_commit &&= success
          messages = messages.concat msgs
        end
        if should_commit
          commit_success, commit_msg = commit_transaction(repo, txn)
          flash_message(:success, I18n.t('flash.actions.update_files.success')) if commit_success
          messages << commit_msg
        else
          commit_success = should_commit
        end

        flash_repository_messages messages

        if should_commit && commit_success
          if new_files.present?
            @current_job = UpdateStarterCodeJob.perform_later(@assignment.id,
                                                              params.fetch(:overwrite, 'false') == 'true')
            session[:job_id] = @current_job.job_id
            redirect_back(fallback_location: root_path)
          else
            head :ok
          end
        else
          head :bad_request
        end
      end
    end
  end

  def download_starter_code
    assignment = Assignment.find(params[:id])
    # find_appropriate_grouping can be found in SubmissionsHelper

    revision_identifier = params[:revision_identifier]
    path = params[:path] || '/'
    assignment.access_starter_code_repo do |repo|
      if revision_identifier.nil?
        revision = repo.get_latest_revision
      else
        revision = repo.get_revision(revision_identifier)
      end

      begin
        file = revision.files_at_path(File.join(assignment.repository_folder,
                                                path))[params[:file_name]]
        file_contents = repo.download_as_string(file)
      rescue Exception => e
        render plain: t('student.submission.missing_file',
                        file_name: params[:file_name], message: e.message)
        return
      end

      send_data_download file_contents, filename: params[:file_name]
    end
  end

  def switch_assignment
    # TODO: Make this dependent on the referer URL.
    if current_user.admin?
      redirect_to edit_assignment_path(params[:id])
    elsif current_user.ta?
      redirect_to summary_assignment_path(params[:id])
    else # current_user.student?
      redirect_to assignment_path(params[:id])
    end
  end

  def set_boolean_graders_options
    assignment = Assignment.find(params[:id])
    attributes = graders_options_params
    return head 400 if attributes.empty? || attributes[:assignment_properties_attributes].empty?

    unless assignment.update(attributes)
      flash_now(:error, assignment.errors.full_messages.join(' '))
      head 422
      return
    end
    head :ok
  end

  # Updates the duration and/or start_time for the grouping with id +params[:grouping_id]+
  def update_grouping_timed_settings
    grouping = Grouping.find(params[:grouping_id])
    return head 400 if grouping.nil?

    duration = params[:hours].to_i.hours + params[:minutes].to_i.minutes
    unless grouping.update(duration: duration, start_time: params[:start_time])
      flash_now(:error, grouping.errors.full_messages.join(' '))
    end
    redirect_to assignment_path(params[:id])
  end

  def start_timed_assignment
    grouping = Grouping.find(params[:grouping_id])
    unless grouping.update(start_time: Time.current)
      flash_now(:error, grouping.errors.full_messages.join(' '))
    end
    redirect_to action: :show
  end

  private

    def sanitize_file_name(file_name)
      # If file_name is blank, return the empty string
      return '' if file_name.nil?
      File.basename(file_name).gsub(
          SubmissionFile::FILENAME_SANITIZATION_REGEXP,
          SubmissionFile::SUBSTITUTION_CHAR)
    end

  def set_repo_vars(assignment, grouping)
    grouping.group.access_repo do |repo|
      @revision = repo.get_revision_by_timestamp(Time.current, assignment.repository_folder)
      @last_modified_date = @revision&.server_timestamp
      files = @revision.tree_at_path(assignment.repository_folder, with_attrs: false)
                       .select do |_, obj|
                         obj.is_a?(Repository::RevisionFile) &&
                           !Repository.get_class.internal_file_names.include?(obj.name)
                       end
      @num_submitted_files = files.length
      missing_assignment_files = grouping.missing_assignment_files(@revision)
      @num_missing_assignment_files = missing_assignment_files.length
    end
  end

  # Recursively return data for all starter code files.
  # TODO: remove code duplication with the equivalent SubmissionsController method.
  def get_all_file_data(revision, assignment, path)
    full_path = File.join(assignment.repository_folder, path)
    return [] unless revision.path_exists?(full_path)

    entries = revision.tree_at_path(full_path).sort do |a, b|
      a[0].count(File::SEPARATOR) <=> b[0].count(File::SEPARATOR) # less nested first
    end
    entries.map do |file_name, file_obj|
      if file_obj.is_a? Repository::RevisionFile
        dirname, basename = File.split(file_name)
        dirname = '' if dirname == '.'
        data = get_file_info(basename, file_obj, assignment.id, dirname)
        next if data.nil?
        data[:key] = file_name
        data[:modified] = data[:last_revised_date]
        data
      else
        { key: "#{file_name}/", last_modified_revision: file_obj.last_modified_revision }
      end
    end.compact
  end

  def get_file_info(file_name, file, assignment_id, path)
    {
      id: file.object_id,
      url: download_starter_code_assignment_url(
        id: assignment_id,
        file_name: file_name,
        path: path,
      ),
      filename: view_context.image_tag('icons/page_white_text.png') +
        view_context.link_to(file_name,
                             action: 'download_starter_code',
                             id: assignment_id,
                             file_name: file_name,
                             path: path),
      raw_name: file_name,
      last_revised_date: l(file.last_modified_date),
      last_modified_revision: file.last_modified_revision,
      revision_by: file.user_id,
      submitted_date: I18n.l(file.submitted_date)
    }
  end

  def process_assignment_form(assignment)
    num_files_before = assignment.assignment_files.length
    short_identifier = assignment_params[:short_identifier]
    # remove potentially invalid periods before updating
    periods = submission_rule_params['submission_rule_attributes']['periods_attributes'].to_h.values.map { |h| h[:id] }
    assignment.submission_rule.periods.where.not(id: periods).each(&:destroy)
    assignment.assign_attributes(assignment_params)
    process_timed_duration(assignment) if assignment.is_timed
    assignment.repository_folder = short_identifier unless assignment.is_peer_review?
    assignment.save!
    new_required_files = assignment.saved_change_to_only_required_files? ||
                         assignment.saved_change_to_is_hidden? ||
                         assignment.assignment_files.any?(&:saved_changes?) ||
                         num_files_before != assignment.assignment_files.length
    # if there are no section due dates, destroy the objects that were created
    if ['0', nil].include? params[:assignment][:assignment_properties_attributes][:section_due_dates_type]
      assignment.section_due_dates.each(&:destroy)
      assignment.section_due_dates_type = false
      assignment.section_groups_only = false
    else
      assignment.section_due_dates_type = true
      assignment.section_groups_only = true
    end

    if params[:is_group_assignment] == 'true'
      # Is the instructor forming groups?
      if assignment_params[:assignment_properties_attributes][:student_form_groups] == '0'
        assignment.invalid_override = true
      else
        assignment.student_form_groups = true
        assignment.invalid_override = false
        assignment.group_name_autogenerated = true
      end
    else
      assignment.student_form_groups = false
      assignment.invalid_override = false
      assignment.group_min = 1
      assignment.group_max = 1
    end

    return assignment, new_required_files
  end

  # Convert the hours and minutes value given in the params to a duration value
  # and assign it to the duration attribute of +assignment+.
  def process_timed_duration(assignment)
    durs = duration_params['assignment_properties_attributes']['duration']
    assignment.duration = durs['hours'].to_i.hours + durs['minutes'].to_i.minutes
  end

  def graders_options_params
    params.require(:attribute)
          .permit(assignment_properties_attributes: [
                    :assign_graders_to_criteria,
                    :anonymize_groups,
                    :hide_unassigned_criteria
                  ])
  end

  def assignment_params
    params.require(:assignment).permit(
      :short_identifier,
      :description,
      :message,
      :due_date,
      :is_hidden,
      assignment_properties_attributes: [
        :id,
        :allow_web_submits,
        :vcs_submit,
        :display_median_to_students,
        :display_grader_names_to_students,
        :group_min,
        :group_max,
        :student_form_groups,
        :group_name_autogenerated,
        :allow_remarks,
        :remark_due_date,
        :remark_message,
        :section_groups_only,
        :enable_test,
        :enable_student_tests,
        :has_peer_review,
        :assign_graders_to_criteria,
        :group_name_displayed,
        :invalid_override,
        :section_groups_only,
        :only_required_files,
        :section_due_dates_type,
        :scanned_exam,
        :is_timed,
        :start_time
      ],
      section_due_dates_attributes: [
        :_destroy,
        :id,
        :section_id,
        :due_date,
        :start_time
      ],
      assignment_files_attributes:  [
        :_destroy,
        :id,
        :filename
      ],
      submission_rule_attributes: [
        :_destroy,
        :id,
        :type,
        { periods_attributes: [
          :id,
          :deduction,
          :interval,
          :hours,
          :_destroy
        ] }
      ]
    )
  end

  def duration_params
    params.require(:assignment).permit(
      assignment_properties_attributes: [
        duration: [
          :hours,
          :minutes
        ]
      ]
    )
  end

  def submission_rule_params
    params.require(:assignment)
          .permit(submission_rule_attributes: [
            :_destroy,
            :id,
            :type,
            { periods_attributes: [
              :id,
              :deduction,
              :interval,
              :hours,
              :_destroy
            ] }
          ])
  end

  def flash_interpolation_options
    { resource_name: @assignment.short_identifier.blank? ? @assignment.model_name.human : @assignment.short_identifier,
      errors: @assignment.errors.full_messages.join('; ') }
  end
end
