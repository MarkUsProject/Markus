class SubmissionsController < ApplicationController
  include SubmissionsHelper

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
                         :check_collect_status,
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
                       :check_collect_status,
                       :update_submissions,
                       :populate_submissions_table]
  before_action :authorize_for_student,
                only: [:file_manager,
                       :populate_peer_submissions_table]
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
    repo = @grouping.group.repo
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

    repo.close

    render layout: 'assignment_content'
  end

  def revisions
    grouping = Grouping.find(params[:grouping_id])
    repo = grouping.group.repo

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

    repo.close

    render json: revisions_history
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
      flash_message(:notice, t('student.submission.version_control_warning'))
    end
    render layout: 'assignment_content'
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
    partition = groupings.partition do |grouping|
      section = grouping.inviter.present? ? grouping.inviter.section : nil
      assignment.submission_rule.can_collect_now?(section)
    end
    success = ''
    error = ''
    if partition[0].count > 0
      current_job = SubmissionsJob.perform_later(partition[0])
      session[:job_id] = current_job.job_id
      success = I18n.t('submissions.collect.collection_job_started_for_groups',
                       assignment_identifier: assignment.short_identifier)
    end
    if partition[1].count > 0
      error = I18n.t('submissions.collect.could_not_collect_some',
                     assignment_identifier: assignment.short_identifier)
    end
    flash_now(:success, success) unless success.empty?
    flash_now(:error, error) unless error.empty?

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
        test_scripts, hooks_script = AutomatedTestsClientHelper.authorize_test_run(current_user, assignment)
        AutotestRunJob.perform_later(request.protocol + request.host_with_port, current_user.id, test_scripts,
                                     hooks_script, test_runs)
        success = I18n.t('automated_tests.tests_running', assignment_identifier: assignment.short_identifier)
      else
        error = I18n.t('automated_tests.need_submission')
      end
    rescue StandardError => e
      error = e.message
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

    if current_user.ta?
      return
    end

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

  def populate_peer_submissions_table
    assignment_in = Assignment.find(params[:assignment_id])
    assignment = assignment_in.is_peer_review? ? assignment_in : assignment_in.pr_assignment
    groupings = Grouping.get_groupings_for_assignment(assignment,
                                                      current_user)

    render json: get_submissions_table_info(assignment, groupings)
  end

  # update_files action handles transactional submission of files.
  def update_files
    assignment_id = params[:assignment_id]
    begin
      @assignment = Assignment.find(assignment_id)
      if current_user.student? && !@assignment.allow_web_submits
        raise t('student.submission.external_submit_only')
      end

      required_files = AssignmentFile.where(assignment_id: @assignment).pluck(:filename)
      filenames = []
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
      unless params[:new_files].nil?
        params[:new_files].each do |f|
          if f.size > MarkusConfigurator.markus_config_max_file_size
            flash_message(
              :error,
              t('student.submission.file_too_large',
                file_name: f.original_filename,
                max_size: (MarkusConfigurator.markus_config_max_file_size / 1_000_000.00).round(2))
            )
            return
          elsif f.size == 0
            flash_message(:warning, t('student.submission.empty_file_warning', file_name: f.original_filename))
          end
        end
      end
      @grouping.group.access_repo do |repo|

        assignment_path = Pathname.new(@assignment.repository_folder)
        current_path = assignment_path.join(@path[1..-1]) # remove leading '/' to make relative path

        # Get the revision numbers for the files that we've seen - these
        # values will be the "expected revision numbers" that we'll provide
        # to the transaction to ensure that we don't overwrite a file that's
        # been revised since the user last saw it.
        file_revisions = params[:file_revisions].nil? ? {} : params[:file_revisions]

        # The files that will be deleted
        delete_files = params[:delete_files].nil? ? [] : params[:delete_files]

        # The files that will be added
        new_files = params[:new_files].nil? ? {} : params[:new_files]

        # Create transaction, setting the author.  Timestamp is implicit.
        txn = repo.get_transaction(current_user.user_name)

        log_messages = []
        begin
          if new_files.empty?
            # delete files marked for deletion
            delete_files.each do |filename|
              file_path = assignment_path.join(filename)
              file_path = file_path.to_s
              txn.remove(file_path, file_revisions[filename])
              log_messages.push("Student '#{current_user.user_name}' deleted file '#{file_path}' "\
                                "for assignment '#{@assignment.short_identifier}'.")
            end
          else
            # prepare repo revision for next block
            revision = repo.get_latest_revision
          end

          # Add new files and replace existing files
          new_files.each do |file_object|
            filename = file_object.original_filename
            if filename.nil?
              raise I18n.t('student.submission.invalid_file_name')
            end
            filename = sanitize_file_name(filename)
            file_path = current_path.join(filename)
            file_path_relative = file_path.relative_path_from(assignment_path).to_s
            file_path = file_path.to_s
            # Sometimes the file pointer of file_object is at the end of the file.
            # In order to avoid empty uploaded files, rewind it to be safe.
            file_object.rewind

            # Branch on whether the file is new or a replacement
            if revision.path_exists?(file_path)
              txn.replace(file_path, file_object.read, file_object.content_type, revision.revision_identifier)
              log_messages.push("Student '#{current_user.user_name}' replaced file '#{file_path_relative}' "\
                                "for assignment '#{@assignment.short_identifier}'.")
            else
              filenames << file_path_relative
              txn.add(file_path, file_object.read, file_object.content_type)
              log_messages.push("Student '#{current_user.user_name}' submitted file '#{file_path_relative}' "\
                                "for assignment '#{@assignment.short_identifier}'.")
            end
          end

          # check if only required files are allowed for a submission
          unless filenames.empty? ||
                 required_files.empty? ||
                 !@assignment.only_required_files
            if !(filenames - required_files).empty?
              flash_message(:error, t('assignment.upload_file_requirement'))
              return
            else
              required_files = required_files - filenames
            end
          end
          # finish transaction
          unless txn.has_jobs?
            flash_message(:warning, I18n.t('student.submission.no_action_detected'))
            set_filebrowser_vars(@grouping)
            return
          end
          if repo.commit(txn)
            flash_message(:success, I18n.t('update_files.success'))
            # flush log messages
            m_logger = MarkusLogger.instance
            log_messages.each do |msg|
              m_logger.log(msg)
            end
          else
            flash_message(:error, partial: 'submissions/file_conflicts_list', locals: { conflicts: txn.conflicts })
          end
          # Are we past collection time?
          if current_user.student? && @assignment.submission_rule.can_collect_now?(current_user.section)
            flash_message(:warning,
                          @assignment.submission_rule.class.human_attribute_name(:commit_after_collection_message))
          end
          # can't use redirect_to here. See comment of this action for details.
          set_filebrowser_vars(@grouping)

        rescue  => e
          m_logger = MarkusLogger.instance
          m_logger.log(e.message)
          flash_message(:warning, e.message)
          set_filebrowser_vars(@grouping)
        end
      end
    ensure
      redirect_back(fallback_location: root_path)
    end
  end

  def get_file
    assignment = Assignment.find(params[:assignment_id])
    submission = Submission.find(params[:id])
    grouping = submission.grouping

    # TODO: allow for peer reviewers.
    # current_user.is_reviewer_for?(assignment.pr_assignment, <any result>)
    if @current_user.student? &&
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
          file_contents.force_encoding('UTF-8')
        end

        if SubmissionFile.is_binary?(file_contents)
          # If the file appears to be binary, send it as a download
          render plain: 'not a plaintext file'
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
  # Download all files from all groupings in a .zip file.
  ##
  def download_groupings_files
    assignment = Assignment.find(params[:assignment_id])

    ## create the zip name with the user name to have less chance to delete
    ## a currently downloading file
    short_id = assignment.short_identifier
    zip_name = short_id + '_' + current_user.user_name + '.zip'
    ## check if there is a '/' in the file name to replace by '_'
    zip_path = 'tmp/' + zip_name.tr('/', '_')

    ## delete the old file if it exists
    File.delete(zip_path) if File.exist?(zip_path)

    groupings = Grouping.get_groupings_for_assignment(assignment,
                                                      current_user)

    ## build the zip file
    Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
      groupings.each do |grouping|
        ## retrieve the submitted files
        submission = grouping.current_submission_used
        next unless submission
        files = submission.submission_files

        ## create the grouping directory
        sub_folder = grouping.group.repo_name
        zip_file.mkdir(sub_folder) unless zip_file.find_entry(sub_folder)

        files.each do |file|
          ## retrieve the file and print an error on redirect back if there is
          begin
            file_content = file.retrieve_file
          rescue Exception => e
            flash_message(:error, e.message)
            redirect_back(fallback_location: root_path)
            return
          end

          ## create the file inside the sub folder
          zip_file.get_output_stream(File.join(sub_folder,
                                               file.filename)) do |f|
            f.puts file_content
          end

        end
      end
    end

    ## Send the Zip file
    send_file zip_path, disposition: 'inline', filename: zip_name
  end

  ##
  # Check the status of collection for all groupings
  ##
  def check_collect_status
    assignment = Assignment.find(params[:assignment_id])
    groupings = Grouping.get_groupings_for_assignment(assignment,
                                                      current_user)

    ## check collection is completed for all groupings
    all_groupings_collected = groupings.all?(&:is_collected?)
    render json: { collect_status: all_groupings_collected }
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
          flash_message(:error, t('student.submission.no_revision_available'))
          redirect_back(fallback_location: root_path)
          return
        end
      end

      files = revision.files_at_path(assignment.repository_folder)
      if files.count == 0
        flash_message(:error, t('student.submission.no_files_available'))
        redirect_back(fallback_location: root_path)
        return
      end

      zip_path = "tmp/#{assignment.short_identifier}_#{grouping.group.group_name}_"\
                 "#{revision.revision_identifier}.zip"
      # Open Zip file and fill it with all the files in the repo_folder
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
        downloads_subdirectories('',
                                 assignment.repository_folder,
                                 zip_file, zip_name, repo, revision)
      end

      send_file zip_path, filename: zip_name + '.zip'
    end
  end

  # Given a subdirectory, its path, and an already created zip_file,
  # fill the subdirectory within the zip_file with all of its files.
  # Recursively fills the subdirectory with files and folders within
  # it.
  # Helper method for downloads.
  def downloads_subdirectories(subdirectory, subdirectory_path, zip_file,
                               zip_name, repo, revision)
    files = revision.files_at_path(subdirectory_path)

    files.each do |file|
      begin
        file_contents = repo.download_as_string(file.last)
      rescue
        return
      end

      zip_file.get_output_stream(File.join(zip_name, subdirectory +
          file.first)) do |f|
        f.puts file_contents
      end
    end

    # Now recursively call this function on all sub directories.
    directories = revision.directories_at_path(subdirectory_path)
    directories.each do |new_subdirectory|
      begin
        # Recursively fill this sub-directory
        zip_file.mkdir(zip_name + '/' + subdirectory +
                           new_subdirectory[0]) unless
            zip_file.find_entry(zip_name + '/' + subdirectory +
                                    new_subdirectory[0])
        downloads_subdirectories(subdirectory + new_subdirectory[0] +
                                     '/',
                                 directories[new_subdirectory[0]].path +
                                     new_subdirectory[0] + '/',
                                 zip_file, zip_name, repo, revision)
      end
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
    groupings = assignment.groupings.find(params[:groupings])
    release = params[:release_results]

    begin
      changed = assignment.is_peer_review? ?
          set_pr_release_on_results(groupings, release) :
          set_release_on_results(groupings, release)

      if changed > 0
        assignment.update_results_stats

        # These flashes don't get rendered. Find another way to display?
        flash_now(:success, I18n.t('results.successfully_changed',
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

    entries = revision.tree_at_path(full_path)
                      .select { |_, obj| obj.is_a? Repository::RevisionFile }.map do |file_name, file_obj|
      data = get_file_info(file_name, file_obj, grouping.assignment.id, revision.revision_identifier, path, grouping.id)
      next if data.nil?
      data[:key] = path.blank? ? data[:raw_name] : File.join(path, data[:raw_name])
      data[:modified] = data[:last_revised_date]
      data[:size] = 1 # Dummy value
      data
    end.compact
    entries
  end
end
