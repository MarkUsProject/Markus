class SubmissionsController < ApplicationController
  include SubmissionsHelper
  include RepositoryHelper

  before_action :authorize_only_for_admin,
                except: [:index,
                         :browse,
                         :server_time,
                         :populate_file_manager,
                         :revisions,
                         :file_manager,
                         :update_files,
                         :get_file,
                         :download,
                         :downloads,
                         :download_groupings_files,
                         :manually_collect_and_begin_grading,
                         :repo_browser,
                         :update_submissions,
                         :populate_submissions_table,
                         :populate_peer_submissions_table]
  before_action :authorize_for_ta_and_admin,
                only: [:index,
                       :browse,
                       :manually_collect_and_begin_grading,
                       :revisions,
                       :repo_browser,
                       :download_groupings_files,
                       :update_submissions]
  before_action :authorize_for_student,
                only: [:file_manager]
  before_action :authorize_for_user,
                only: [:download, :downloads, :get_file, :populate_file_manager, :update_files]

  def index
    respond_to do |format|
      format.json do
        assignment = Assignment.find(params[:assignment_id])
        render json: {
          groupings: assignment.current_submission_data(current_user),
          sections: Hash[Section.all.pluck(:id, :name)]
        }
      end
    end
  end

  def repo_browser
    @grouping = Grouping.find(params[:id])
    @collected_revision = nil
    @revision = nil
    @grouping.group.access_repo do |repo|
      collected_submission = @grouping.current_submission_used

      # generate a history of relevant revisions (i.e. only related to the assignment) with date and identifier
      assignment_path = @grouping.assignment.repository_folder
      assignment_revisions = []
      all_revisions = repo.get_all_revisions
      all_revisions.each do |revision|
        # store the assignment-relevant revisions
        next if !revision.path_exists?(assignment_path) || !revision.changes_at_path?(assignment_path)
        assignment_revisions << revision
        # store the collected revision
        if @collected_revision.nil? && collected_submission&.revision_identifier == revision.revision_identifier.to_s
          @collected_revision = revision
        end
        # store the displayed revision
        if @revision.nil?
          if (params[:revision_identifier] &&
            params[:revision_identifier] == revision.revision_identifier.to_s) ||
            (params[:revision_timestamp] &&
              Time.parse(params[:revision_timestamp]).in_time_zone >= revision.server_timestamp)
            @revision = revision
          end
        end
      end
      # find another relevant revision to display if @revision.nil?
      # 1) the latest assignment revision, or 2) the first repo revision
      @revision ||= assignment_revisions[0] || all_revisions[-1]
    end
    render layout: 'assignment_content'
  end

  def revisions
    grouping = Grouping.find(params[:grouping_id])
    grouping.group.access_repo do |repo|
      # generate a history of relevant revisions (i.e. only related to the assignment) with date and identifier
      assignment_path = grouping.assignment.repository_folder
      assignment_revisions = []
      all_revisions = repo.get_all_revisions
      all_revisions.each do |revision|
        # store the assignment-relevant revisions
        next if !revision.path_exists?(assignment_path) || !revision.changes_at_path?(assignment_path)
        assignment_revisions << revision
      end
      revisions_history = assignment_revisions.map do |revision|
        {
          id: revision.revision_identifier.to_s,
          id_ui: revision.revision_identifier_ui,
          timestamp: l(revision.timestamp),
          server_timestamp: l(revision.server_timestamp)
        }
      end
      render json: revisions_history
    end
  end

  def file_manager
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = current_user.accepted_grouping_for(@assignment.id)
    if @grouping.nil? || @assignment.scanned_exam? || @assignment.is_peer_review?
      redirect_to controller: 'assignments',
                  action: 'student_interface',
                  id: params[:assignment_id]
      return
    end

    @path = params[:path] || '/'

    # Some vars need to be set in update_files too, so do this in a
    # helper. See update_files action where this is used as well.
    set_filebrowser_vars(@grouping)

    # generate flash messages
    if @assignment.submission_rule.can_collect_now?(@grouping.inviter.section)
      flash_message(:warning,
                    @assignment.submission_rule.class.human_attribute_name(:after_collection_message))
    elsif @assignment.grouping_past_due_date?(@grouping)
      flash_message(:warning, @assignment.submission_rule.overtime_message(@grouping))
    end

    if !@grouping.is_valid?
      flash_message(:error, t('groups.invalid_group_warning'))
    elsif !@missing_assignment_files.blank?
      flash_message(:warning,
                    partial: 'submissions/missing_assignment_file_toggle_list',
                    locals: {missing_assignment_files: @missing_assignment_files})
    end

    if @assignment.allow_web_submits && @assignment.vcs_submit
      flash_message(:notice, t('submissions.student.version_control_warning'))
    end
    render 'file_manager', layout: 'assignment_content', locals: {}
  end

  def populate_file_manager
    assignment = Assignment.find(params[:assignment_id])
    if current_user.student?
      grouping = current_user.accepted_grouping_for(assignment)
    else
      grouping = assignment.groupings.find(params[:grouping_id])
    end
    entries = []
    grouping.group.access_repo do |repo|
      if current_user.student? || params[:revision_identifier].blank?
        revision = repo.get_latest_revision
      else
        revision = repo.get_revision(params[:revision_identifier])
      end
      entries = get_all_file_data(revision, grouping, '')
    end
    render json: entries
  end

  def manually_collect_and_begin_grading
    @grouping = Grouping.find(params[:id])
    @revision_identifier = params[:current_revision_identifier]
    apply_late_penalty = params[:apply_late_penalty].nil? ?
                         false : params[:apply_late_penalty]
    SubmissionsJob.perform_now([@grouping],
                               apply_late_penalty: apply_late_penalty,
                               revision_identifier: @revision_identifier)

    submission = @grouping.reload.current_submission_used
    redirect_to edit_assignment_submission_result_path(
      assignment_id: @grouping.assignment_id,
      submission_id: submission.id,
      id: submission.get_latest_result.id)
  end

  def uncollect_all_submissions
    assignment = Assignment.includes(:groupings).find(params[:assignment_id])
    @current_job = UncollectSubmissions.perform_later(assignment)
    session[:job_id] = @current_job.job_id

    respond_to do |format|
      format.js { render 'shared/_poll_job.js.erb' }
    end
  end

  def collect_submissions
    if !params.has_key?(:groupings) || params[:groupings].empty?
      flash_now(:error, t('groups.select_a_group'))
      head 400
      return
    end
    assignment = Assignment.includes(:groupings).find(params[:assignment_id])
    groupings = assignment.groupings.find(params[:groupings])
    collectable = []
    some_before_due = false
    some_released = Grouping.joins(current_submission_used: :results)
                            .where('results.released_to_students': true)
                            .where(id: groupings)
                            .pluck(:id).to_set
    collection_dates = assignment.all_grouping_collection_dates
    is_scanned_exam = assignment.scanned_exam
    groupings.each do |grouping|
      unless is_scanned_exam
        collect_now = collection_dates[grouping.id] <= Time.current
        some_before_due = true unless collect_now
        next unless collect_now
      end
      next if params[:override] != 'true' && grouping.is_collected?
      next if some_released.include?(grouping.id)

      collectable << grouping
    end
    success = ''
    if collectable.count > 0
      current_job = SubmissionsJob.perform_later(collectable,
                                                 collection_dates: collection_dates.transform_keys(&:to_s))
      # TODO: Re-enable this after investigating activejob-status behaviour.
      # session[:job_id] = current_job.job_id
      success = I18n.t('submissions.collect.collection_job_started_for_groups',
                       assignment_identifier: assignment.short_identifier)
    end
    if some_before_due
      error = I18n.t('submissions.collect.could_not_collect_some_due',
                     assignment_identifier: assignment.short_identifier)
      flash_now(:error, error)
    end
    if some_released.present?
      error = I18n.t('submissions.collect.could_not_collect_some_released',
                     assignment_identifier: assignment.short_identifier)
      flash_now(:error, error)
    end
    flash_now(:success, success) unless success.empty?
    render 'shared/_poll_job.js.erb'
  end

  def run_tests
    if !params.has_key?(:groupings) || params[:groupings].empty?
      flash_now(:error, t('groups.select_a_group'))
      head 400
      return
    end
    assignment = Assignment.includes(groupings: :current_submission_used).find(params[:assignment_id])
    groupings = assignment.groupings.find(params[:groupings])
    # .where.not(current_submission_used: nil) potentially makes find fail with RecordNotFound
    test_runs = groupings.select(&:has_submission?)
                         .map { |g| { grouping_id: g.id, submission_id: g.current_submission_used.id } }
    success = ''
    error = ''
    begin
      if !test_runs.empty?
        authorize! assignment, to: :run_tests?
        AutotestRunJob.perform_later(request.protocol + request.host_with_port, current_user.id, test_runs)
        success = I18n.t('automated_tests.tests_running', assignment_identifier: assignment.short_identifier)
      else
        error = I18n.t('automated_tests.need_submission')
      end
    rescue StandardError => e
      error = e.is_a?(ActionPolicy::Unauthorized) ? e.result.reasons.full_messages.join(' ') : e.message
    end
    unless success.blank?
      flash_message(:success, success)
    end
    unless error.blank?
      flash_message(:error, error)
    end
    render json: { success: success, error: error }
  end

  # The table of submissions for an assignment and related actions and links.
  def browse
    @assignment = Assignment.find(params[:assignment_id])
    self.class.layout 'assignment_content'

    return if current_user.ta?
    return if @assignment.scanned_exam

    if @assignment.past_all_collection_dates?
      flash_now(:success, t('submissions.grading_can_begin'))
      return
    end

    if @assignment.section_due_dates_type
      section_due_dates = Hash.new
      now = Time.zone.now
      Section.find_each do |section|
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
        if collection_time == now
          flash_now(:success, t('submissions.grading_can_begin_for_sections',
                                sections: sections))
        else
          flash_now(:warning, t('submissions.grading_can_begin_after_for_sections',
                                time: l(collection_time),
                                sections: sections))
        end
      end
    else
      collection_time = @assignment.submission_rule.calculate_collection_time
      flash_now(:warning, t('submissions.grading_can_begin_after',
                            time: l(collection_time)))
    end
  end

  # update_files action handles transactional submission of files.
  def update_files
    assignment_id = params[:assignment_id]
    begin
      @assignment = Assignment.find(assignment_id)
      if current_user.student? && !@assignment.allow_web_submits
        raise t('student.submission.external_submit_only')
      end
      @path = params[:path].blank? ? '/' : params[:path]

      if current_user.student?
        @grouping = current_user.accepted_grouping_for(assignment_id)
        unless @grouping.is_valid?
          set_filebrowser_vars(@grouping)
          return
        end
      else
        @grouping = @assignment.groupings.find(params[:grouping_id])
      end

      # The files that will be deleted
      delete_files = params[:delete_files] || []

      # The files that will be added
      new_files = params[:new_files] || []

      # The folders that will be added
      new_folders = params[:new_folders] || []

      # The folders that will be deleted
      delete_folders = params[:delete_folders] || []

      unless delete_folders.empty? && new_folders.empty?
        authorize! to: :manage_subdirectories?
      end

      if delete_files.empty? && new_files.empty? && new_folders.empty? && delete_folders.empty?
        flash_message(:warning, I18n.t('student.submission.no_action_detected'))
      else
        messages = []
        @grouping.group.access_repo do |repo|
          # Create transaction, setting the author.  Timestamp is implicit.
          txn = repo.get_transaction(current_user.user_name)
          should_commit = true
          path = Pathname.new(@grouping.assignment.repository_folder).join(@path.gsub(%r{^/}, ''))
          only_required = @grouping.assignment.only_required_files
          required_files = only_required ? @grouping.assignment.assignment_files.pluck(:filename) : nil
          if delete_files.present?
            success, msgs = remove_files(delete_files, current_user, repo, path: path, txn: txn)
            should_commit &&= success
            messages.concat msgs
          end
          if new_files.present?
            success, msgs = add_files(new_files, current_user, repo,
                                      path: path, txn: txn, check_size: true, required_files: required_files)
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
          end
        end
        flash_repository_messages messages
        set_filebrowser_vars(@grouping)
      end
    ensure
      redirect_back(fallback_location: root_path)
    end
  end

  def get_file
    assignment = Assignment.find(params[:assignment_id])
    submission = Submission.find(params[:id])
    grouping = submission.grouping

    if !@current_user.is_a_reviewer?(assignment.pr_assignment) && @current_user.student? &&
        @current_user.accepted_grouping_for(assignment.id).id != grouping.id
      flash_message(:error,
                    t('submission_file.error.no_access',
                          submission_file_id: params[:submission_file_id]))
      redirect_back(fallback_location: root_path)
      return
    end

    file = SubmissionFile.find(params[:submission_file_id])
    if file.is_supported_image?
      render json: { type: 'image' }
    elsif file.is_pdf?
      render json: { type: 'pdf' }
    else
      grouping.group.access_repo do |repo|
        revision = repo.get_revision(submission.revision_identifier)
        raw_file = revision.files_at_path(file.path)[file.filename]
        if raw_file.nil?
          file_contents = I18n.t('student.submission.missing_file',
                                 file_name: file.filename)
        else
          file_contents = repo.download_as_string(raw_file)
          file_contents.encode!('UTF-8', invalid: :replace, undef: :replace, replace: '�')
        end

        if SubmissionFile.is_binary?(file_contents)
          # If the file appears to be binary, display a warning
          render json: { content: I18n.t('submissions.cannot_display').to_json, type: 'unknown' }
        else
          render json: { content: file_contents.to_json, type: file.get_file_type }
        end
      end
    end
  end

  def download
    @assignment = Assignment.find(params[:id])
    # find_appropriate_grouping can be found in SubmissionsHelper
    @grouping = find_appropriate_grouping(@assignment.id, params)

    revision_identifier = params[:revision_identifier]
    path = params[:path] || '/'
    @grouping.group.access_repo do |repo|
      if revision_identifier.nil?
        @revision = repo.get_latest_revision
      else
        @revision = repo.get_revision(revision_identifier)
      end

      begin
        file = @revision.files_at_path(File.join(@assignment.repository_folder,
                                                 path))[params[:file_name]]
        file_contents = repo.download_as_string(file)
      rescue Exception => e
        render plain: I18n.t('student.submission.missing_file',
                            file_name: params[:file_name], message: e.message)
        return
      end

      send_data file_contents,
                disposition: 'attachment',
                filename: params[:file_name]
    end
  end

  ##
  # Download all files from groupings with id in +params[:groupings]+ in a .zip file.
  ##
  def download_groupings_files
    assignment = Assignment.find(params[:assignment_id])

    ## create the zip name with the user name to have less chance to delete
    ## a currently downloading file
    short_id = assignment.short_identifier
    zip_name = Pathname.new(short_id + '_' + current_user.user_name + '.zip')
    zip_path = Pathname.new('tmp') + zip_name

    ## delete the old file if it exists
    File.delete(zip_path) if File.exist?(zip_path)

    groupings = Grouping.includes(:group, :current_submission_used).where(id: params[:groupings]&.map(&:to_i))

    if current_user.ta?
      groupings = groupings.joins(:ta_memberships).where('memberships.user_id': current_user.id)
    end

    Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
      groupings.each do |grouping|
        revision_id = grouping.current_submission_used&.revision_identifier
        group_name = grouping.group.repo_name
        grouping.group.access_repo do |repo|
          revision = repo.get_revision(revision_id)
          repo.send_tree_to_zip(assignment.repository_folder, zip_file, zip_name + group_name, revision)
        end
      end
    end

    ## Send the Zip file
    send_file zip_path, disposition: 'inline', filename: zip_name.to_s
  end

  ##
  # Download all files from a repository folder in a Zip file.
  ##
  def downloads
    assignment = Assignment.find(params[:assignment_id])
    if current_user.student?
      grouping = current_user.accepted_grouping_for(assignment)
    else
      grouping = assignment.groupings.find(params[:grouping_id])
    end
    zip_name = "#{assignment.short_identifier}-#{grouping.group.group_name}"
    grouping.group.access_repo do |repo|
      if current_user.student? || params[:revision_identifier].nil?
        revision = repo.get_latest_revision
      else
        begin
          revision = repo.get_revision(params[:revision_identifier])
        rescue Repository::RevisionDoesNotExist
          flash_message(:error, t('submissions.student.no_revision_available'))
          redirect_back(fallback_location: root_path)
          return
        end
      end

      files = revision.files_at_path(assignment.repository_folder)
      if files.count == 0
        flash_message(:error, t('submissions.no_files_available'))
        redirect_back(fallback_location: root_path)
        return
      end

      zip_path = "tmp/#{assignment.short_identifier}_#{grouping.group.group_name}_"\
                 "#{revision.revision_identifier}.zip"
      # Open Zip file and fill it with all the files in the repo_folder
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
        repo.send_tree_to_zip(assignment.repository_folder, zip_file, zip_name, revision)
      end

      send_file zip_path, filename: zip_name + '.zip'
    end
  end

  # Release or unrelease submissions
  def update_submissions
    if !params.has_key?(:groupings) || params[:groupings].empty?
      flash_now(:error, t('groups.select_a_group'))
      head 400
      return
    end
    assignment = Assignment.find(params[:assignment_id])
    groupings = assignment.groupings.where(id: params[:groupings])
    release = params[:release_results] == 'true'

    begin
      changed = assignment.is_peer_review? ?
          set_pr_release_on_results(groupings, release) :
          set_release_on_results(groupings, release)

      if changed > 0
        assignment.update_results_stats
        assignment.update_remark_request_count

        # These flashes don't get rendered. Find another way to display?
        flash_now(:success, I18n.t('submissions.successfully_changed',
                                   changed: changed))
        if release
          MarkusLogger.instance.log(
            'Marks released for assignment' +
            " '#{assignment.short_identifier}', ID: '" +
            "#{assignment.id}' for #{changed} group(s).")
        else
          MarkusLogger.instance.log(
            'Marks unreleased for assignment' +
            " '#{assignment.short_identifier}', ID: '" +
            "#{assignment.id}' for #{changed} group(s).")
        end
      end

      head :ok
    rescue => e
      flash_now(:error, e.message)
      head 400
    end
  end

  # See Assignment.get_repo_checkout_commands for details
  def download_repo_checkout_commands
    assignment = Assignment.find(params[:assignment_id])
    svn_commands = assignment.get_repo_checkout_commands
    send_data svn_commands.join("\n"),
              disposition: 'attachment',
              type: 'application/vnd.ms-excel',
              filename: "#{assignment.short_identifier}_repo_checkouts"
  end

  # See Assignment.get_repo_list for details
  def download_repo_list
    assignment = Assignment.find(params[:assignment_id])
    send_data assignment.get_repo_list,
              disposition: 'attachment',
              type: 'text/plain',
              filename: "#{assignment.short_identifier}_repo_list"
  end

  # This action is called periodically from file_manager.
  def server_time
    render plain: l(Time.zone.now)
  end

  private

  # Used in update_files and file_manager actions
  def set_filebrowser_vars(grouping)
    grouping.group.access_repo do |repo|
      @revision = repo.get_latest_revision
      @files = @revision.files_at_path(File.join(grouping.assignment.repository_folder, @path))
      @missing_assignment_files = grouping.missing_assignment_files(@revision)
    end
  end

  # Recursively return data for all files in a submission.
  # Based on Submission#populate_with_submission_files.
  def get_all_file_data(revision, grouping, path)
    full_path = File.join(grouping.assignment.repository_folder, path)
    return [] unless revision.path_exists?(full_path)

    entries = revision.tree_at_path(full_path).sort do |a, b|
      a[0].count(File::SEPARATOR) <=> b[0].count(File::SEPARATOR) # less nested first
    end
    entries.map do |file_name, file_obj|
      if file_obj.is_a? Repository::RevisionFile
        dirname, basename = File.split(file_name)
        dirname = '' if dirname == '.'
        data = get_file_info(basename, file_obj, grouping.assignment.id,
                             revision.revision_identifier, dirname, grouping.id)
        next if data.nil?
        data[:key] = file_name
        data[:modified] = data[:last_revised_date]
        data
      else
        { key: "#{file_name}/" }
      end
    end.compact
  end
end
