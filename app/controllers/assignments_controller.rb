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
                            :peer_review]

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
    unless @grouping.nil?
      flash_message(:warning, I18n.t('assignments.starter_file.changed_warning')) if @grouping.starter_file_changed
      if @assignment.is_timed && !@grouping.start_time.nil? && !@grouping.past_collection_date?
        flash_message(:note, I18n.t('assignments.timed.started_message_html'))
        flash_message(:note, I18n.t('assignments.timed.starter_file_prompt'))
      end
      set_repo_vars(@assignment, @grouping)
    end
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

  def starter_file
    @assignment = Assignment.find_by_id(params[:id])
    if @assignment.nil?
      render 'shared/http_status',
             locals: { code: '404', message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404
    else
      render layout: 'assignment_content'
    end
  end

  def populate_starter_file_manager
    assignment = Assignment.find(params[:id])
    if assignment.groupings.exists?
      flash_message(:warning,
                    I18n.t('assignments.starter_file.groupings_exist_warning_html'))
    end
    file_data = []
    assignment.starter_file_groups.order(:id).each do |g|
      file_data << { id: g.id,
                     name: g.name,
                     entry_rename: g.entry_rename,
                     use_rename: g.use_rename,
                     files: starter_file_group_file_data(g) }
    end
    section_data = Section.left_outer_joins(:starter_file_groups)
                          .order(:id)
                          .pluck_to_hash('sections.id as section_id',
                                         'sections.name as section_name',
                                         'starter_file_groups.id as group_id',
                                         'starter_file_groups.name as group_name')
    data = { files: file_data,
             sections: section_data,
             starterfileType: assignment.starter_file_type,
             defaultStarterFileGroup: assignment.default_starter_file_group&.id || '' }
    render json: data
  end

  def update_starter_file
    assignment = Assignment.find(params[:id])
    all_changed = false
    success = true
    ApplicationRecord.transaction do
      assignment.assignment_properties.update!(starter_file_assignment_params)
      all_changed = assignment.assignment_properties.saved_changes?
      starter_file_section_params.each do |section_params|
        Section.find_by(id: section_params[:section_id])
               &.update_starter_file_group(assignment.id, section_params[:group_id])
      end
      starter_file_group_params.each do |group_params|
        starter_file_group = assignment.starter_file_groups.find_by(id: group_params[:id])
        starter_file_group.update!(group_params)
        all_changed ||= starter_file_group.saved_changes? || assignment.assignment_properties.saved_changes?
      end
      assignment.assignment_properties.update!(starter_file_updated_at: Time.zone.now)
    rescue ActiveRecord::RecordInvalid => e
      flash_message(:error, e.message)
      success = false
      raise ActiveRecord::Rollback
    rescue StandardError => e
      flash_message(:error, e.message)
      success = false
      raise ActiveRecord::Rollback
    end
    if success
      flash_message(:success, I18n.t('flash.actions.update.success',
                                     resource_name: I18n.t('assignments.starter_file.title')))
    end
    # mark all groupings with starter files that were changed as changed
    assignment.groupings.update_all(starter_file_changed: true) if success && all_changed
  end

  def download_starter_file_mappings
    assignment = Assignment.find(params[:id])
    mappings = assignment.starter_file_mappings
    file_out = MarkusCsv.generate(mappings, [mappings.first&.keys].compact, &:values)
    send_data(file_out,
              type: 'text/csv',
              filename: "#{assignment.short_identifier}_starter_file_mappings.csv",
              disposition: 'inline')
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

  # Start timed assignment for the current user's grouping for this assignment
  def start_timed_assignment
    grouping = current_user.try(:accepted_grouping_for, params[:id])
    return head 400 if grouping.nil?
    authorize! grouping
    unless grouping.update(start_time: Time.current)
      flash_message(:error, grouping.errors.full_messages.join(' '))
    end
    redirect_to action: :show
  end

  private

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

  def starter_file_group_file_data(starter_file_group)
    starter_file_group.files_and_dirs.map do |file|
      if (starter_file_group.path + file).directory?
        { key: "#{file}/" }
      else
        { key: file, size: 1,
          url: download_file_assignment_starter_file_group_url(starter_file_group.assignment.id,
                                                               starter_file_group.id,
                                                               file_name: file) }
      end
    end
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

  def starter_file_assignment_params
    params.require(:assignment).permit(:starter_file_type, :default_starter_file_group_id)
  end

  def starter_file_section_params
    params.permit(sections: [:section_id, :group_id]).require(:sections)
  end

  def starter_file_group_params
    params.permit(starter_file_groups: [:id, :name, :entry_rename, :use_rename])
          .require(:starter_file_groups)
  end

  def flash_interpolation_options
    { resource_name: @assignment.short_identifier.blank? ? @assignment.model_name.human : @assignment.short_identifier,
      errors: @assignment.errors.full_messages.join('; ') }
  end
end
