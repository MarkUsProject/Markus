require 'base64'


class AssignmentsController < ApplicationController
  include RepositoryHelper
  responders :flash

  before_action      :authorize_only_for_admin,
                     except: [:index,
                              :student_interface,
                              :update_collected_submissions,
                              :render_feedback_file,
                              :peer_review,
                              :summary,
                              :switch_assignment]

  before_action      :authorize_for_ta_and_admin,
                     only: [:summary]

  before_action      :authorize_for_student,
                     only: [:student_interface,
                            :peer_review]

  before_action      :authorize_for_user,
                     only: [:index, :render_feedback_file, :switch_assignment]

  # Publicly accessible actions ---------------------------------------

  def render_feedback_file
    @feedback_file = FeedbackFile.find(params[:feedback_file_id])

    # Students can use this action only, when marks have been released
    if current_user.student? &&
        (@feedback_file.submission.grouping.membership_status(current_user).nil? ||
         !@feedback_file.submission.get_latest_result.released_to_students)
      flash_message(:error, t('feedback_file.error.no_access',
                              feedback_file_id: @feedback_file.id))
      head :forbidden
      return
    end

    if @feedback_file.mime_type.start_with? 'image'
      content = Base64.encode64(@feedback_file.file_content)
    else
      content = @feedback_file.file_content
    end

    render plain: content
  end

  def student_interface
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

    @student = current_user
    @grouping = @student.accepted_grouping_for(@assignment.id)
    @penalty = SubmissionRule.find_by_assignment_id(@assignment.id)
    @enum_penalty = Period.where(submission_rule_id: @penalty.id).sort
    @due_date = @student.due_date_for_assignment(@assignment)
    if @student.has_pending_groupings_for?(@assignment.id)
      @pending_grouping = @student.pending_groupings_for(@assignment.id)
    end
    if @grouping.nil?
      if @assignment.group_max == 1 && !@assignment.scanned_exam
        begin
          @student.create_group_for_working_alone_student(@assignment.id)
        rescue RuntimeError => error
          flash_message(:error, error.message)
        end
        redirect_to action: 'student_interface', id: @assignment.id
      else
        if @assignment.scanned_exam
          flash_now(:notice, t('assignments.scanned_exam.under_review'))
        end
        render :student_interface
      end
    else
      # We look for the information on this group...
      # The members
      @studentmemberships = @grouping.student_memberships
      # The group name
      @group = @grouping.group
      # The inviter
      @inviter = @grouping.inviter

      # Look up submission information
      set_repo_vars(@assignment, @grouping)
    end
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
    @grouping = @student.accepted_grouping_for(@assignment.id)
    @penalty = @assignment.submission_rule
    @enum_penalty = Period.where(submission_rule_id: @penalty.id).sort
    @due_date = @student.due_date_for_assignment(@assignment)
    @prs = @student.grouping_for(@assignment.parent_assignment.id)&.
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
          collection_time = @assignment.submission_rule
                                .calculate_collection_time(section)
          collection_time = now if now >= collection_time
          if section_due_dates[collection_time].nil?
            section_due_dates[collection_time] = Array.new
          end
          section_due_dates[collection_time].push(section.name)
        end
        section_due_dates.each do |collection_time, sections|
          sections = sections.join(', ')
          if(collection_time == now)
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

  # Displays "Manage Assignments" page for creating and editing
  # assignment information
  def index
    if current_user.student?
      @grade_entry_forms = GradeEntryForm.where(is_hidden: false).order(:id)
      @assignments = Assignment.where(is_hidden: false).order(:id)
      @marking_schemes = MarkingScheme.none
      #get the section of current user
      @section = current_user.section
      # get results for assignments for the current user
      @a_id_results = Hash.new()
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

      # Get the grades for grade entry forms for the current user
      @g_id_entries = Hash.new()
      @grade_entry_forms.each do |g|
        grade_entry_student = g.grade_entry_students.find_by_user_id(
                                    current_user.id )
        if !grade_entry_student.nil? &&
             grade_entry_student.released_to_student
          @g_id_entries[g.id] = grade_entry_student
        end
      end

      render :student_assignment_list, layout: 'assignment_content'
    elsif current_user.ta?
      @grade_entry_forms = GradeEntryForm.order(:id)
      @assignments = Assignment.includes(:submission_rule).order(:id)
      render :grader_index, layout: 'assignment_content'
      @marking_schemes = MarkingScheme.all
    else
      @grade_entry_forms = GradeEntryForm.order(:id)
      @assignments = Assignment.includes(:submission_rule).order(:id)
      render :index, layout: 'assignment_content'
      @marking_schemes = MarkingScheme.all
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
      unless SectionDueDate.find_by_assignment_id_and_section_id(@assignment.id, s.id)
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
      if new_required_files && !MarkusConfigurator.markus_config_repository_hooks.empty?
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
    @clone_assignments = Assignment.where(vcs_submit: true)
                                   .order(:id)
    @sections = Section.all
    @assignment.build_submission_rule
    @assignment.build_assignment_stat

    # build section_due_dates for each section
    Section.all.each { |s| @assignment.section_due_dates.build(section: s)}
    @section_due_dates = @assignment.section_due_dates
                                    .sort_by { |s| s.section.name }

    # set default value if web submits are allowed
    @assignment.allow_web_submits =
        !MarkusConfigurator.markus_config_repository_external_submits_only?
    render :new
  end

  # Called after a new assignment form is submitted.
  def create
    @assignment = Assignment.new
    @assignment.build_assignment_stat
    @assignment.build_submission_rule
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
        @clone_assignments = Assignment.where(vcs_submit: true)
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
      if new_required_files && !MarkusConfigurator.markus_config_repository_hooks.empty?
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
      format.html {
        render layout: 'assignment_content'
      }
      format.json {
        render json: @assignment.summary_json(@current_user)
      }
    end
  end

  def stop_test
    test_id = params[:test_run_id].to_i
    @current_job = AutotestCancelJob.perform_later(request.protocol + request.host_with_port, [test_id])
    session[:job_id] = @current_job.job_id
    redirect_back(fallback_location: root_path)
  end

  def stop_batch_tests
    test_runs = TestRun.where(test_batch_id: params[:test_batch_id]).pluck(:id)
    @current_job = AutotestCancelJob.perform_later(request.protocol + request.host_with_port, test_runs)
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
                                  'groupings.assignment_id': @assignment.id)
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

  def csv_summary
    assignment = Assignment.find(params[:id])
    data = assignment.summary_csv(@current_user)
    filename = "#{assignment.short_identifier}_summary.csv"
    send_data data,
              disposition: 'attachment',
              type: 'text/csv',
              filename: filename
  end

  # Methods for the student interface

  def update_collected_submissions
    @assignments = Assignment.all
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
    unless MarkusConfigurator.markus_starter_code_on
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

      send_data file_contents,
                disposition: 'attachment',
                filename: params[:file_name]
    end
  end

  def switch_assignment
    # TODO: Make this dependent on the referer URL.
    if current_user.admin?
      redirect_to edit_assignment_path(params[:id])
    elsif current_user.ta?
      redirect_to summary_assignment_path(params[:id])
    else # curret_user.student?
      redirect_to student_interface_assignment_path
    end
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
    assignment.assign_attributes(assignment_params)
    assignment.repository_folder = assignment_params[:short_identifier] unless assignment.is_peer_review?
    assignment.save!
    new_required_files = assignment.saved_change_to_only_required_files? ||
                         assignment.saved_change_to_is_hidden? ||
                         assignment.assignment_files.any?(&:saved_changes?) ||
                         num_files_before != assignment.assignment_files.length
    # if there are no section due dates, destroy the objects that were created
    if ['0', nil].include? params[:assignment][:section_due_dates_type]
      assignment.section_due_dates.each(&:destroy)
      assignment.section_due_dates_type = false
      assignment.section_groups_only = false
    else
      assignment.section_due_dates_type = true
      assignment.section_groups_only = true
    end

    if params[:is_group_assignment] == 'true'
      # Is the instructor forming groups?
      if assignment_params[:student_form_groups] == '0'
        assignment.invalid_override = true
        # Increase group_max so that create_all_groups button is not displayed
        # in the groups view.
        assignment.group_max = 2
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

    # Due to some funkiness, we need to handle submission rules separately
    # from the main attribute update
    # First, figure out what kind of rule has been requested
    rule_attributes = params[:assignment][:submission_rule_attributes]
    if rule_attributes.nil?
      rule_name = assignment.submission_rule.class.to_s
    else
      rule_name = rule_attributes[:type]
    end

    [NoLateSubmissionRule, GracePeriodSubmissionRule,
     PenaltyPeriodSubmissionRule, PenaltyDecayPeriodSubmissionRule]
    if SubmissionRule.const_defined?(rule_name)
      potential_rule = SubmissionRule.const_get(rule_name)
    else
      raise SubmissionRule::InvalidRuleType, rule_name
    end

    # If the submission rule was changed, we need to do a more complicated
    # dance with the database in order to get things updated.
    if assignment.submission_rule.class != potential_rule

      # In this case, the easiest thing to do is nuke the old rule along
      # with all the periods and a new submission rule...this may cause
      # issues with foreign keys in the future, but not with the current
      # schema
      assignment.submission_rule.delete
      assignment.submission_rule = potential_rule.create!(assignment: assignment)

      # this part of the update is particularly hacky, because the incoming
      # data will include some mix of the old periods and new periods; in
      # the case of purely new periods the input is only an array, but in
      # the case of a mixture the input is a hash, and if there are no
      # periods at all then the periods_attributes will be nil
      periods = submission_rule_params[:submission_rule_attributes][:periods_attributes]
      begin
        periods = periods.to_h
      rescue
      end
      periods = case periods
                when Hash
                  # in this case, we do not care about the keys, because
                  # the new periods will have nonsense values for the key
                  # and the old periods are being discarded
                  periods.map { |_, p| p }.reject { |p| p.has_key?(:id) }
                when Array
                  periods
                else
                  []
                end
      # now that we know what periods we want to keep, we can create them
      periods.each do |p|
        new_period = assignment.submission_rule.periods.build(p)
        new_period.submission_rule = assignment.submission_rule
        new_period.save!
      end
    elsif !submission_rule_params.blank? # TODO: do this in a more Rails way
      periods = submission_rule_params[:submission_rule_attributes][:periods_attributes]
      begin
        periods = periods.to_h
      rescue
      end
      periods = case periods
                when Hash
                  periods.map { |_, p| p }.select { |p| p.key?(:hours) }
                when Array
                  periods
                else
                  []
                end
      assignment.submission_rule.periods_attributes = periods
      assignment.submission_rule.periods.each do |period|
        period.submission_rule = assignment.submission_rule
        period.save
      end
      assignment.submission_rule.save
    end

    return assignment, new_required_files
  end

  def assignment_params
    params.require(:assignment).permit(
        :short_identifier,
        :description,
        :message,
        :due_date,
        :allow_web_submits,
        :vcs_submit,
        :display_median_to_students,
        :display_grader_names_to_students,
        :is_hidden,
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
        :scanned_exam,
        section_due_dates_attributes: [:_destroy,
                                       :id,
                                       :section_id,
                                       :due_date],
        assignment_files_attributes:  [:_destroy,
                                       :id,
                                       :filename]
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
