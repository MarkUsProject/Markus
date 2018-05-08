require 'zip'

class SubmissionsController < ApplicationController
  include SubmissionsHelper

  before_filter :authorize_only_for_admin,
                except: [:server_time,
                         :populate_file_manager_react,
                         :browse,
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
  before_filter :authorize_for_ta_and_admin,
                only: [:browse,
                       :manually_collect_and_begin_grading,
                       :repo_browser,
                       :download_groupings_files,
                       :check_collect_status,
                       :update_submissions,
                       :populate_submissions_table]
  before_filter :authorize_for_student,
                only: [:file_manager,
                       :update_files,
                       :populate_file_manager_react,
                       :populate_peer_submissions_table]
  before_filter :authorize_for_user, only: [:download, :downloads, :get_file]


  def repo_browser
    @grouping = Grouping.find(params[:id])
    @path = params[:path] || File::SEPARATOR
    @collected_revision = nil
    repo = @grouping.group.repo
    collected_submission = @grouping.current_submission_used

    # generate a history of relevant revisions (i.e. only related to the assignment) with date and identifier
    assignment_path = File.join(@grouping.assignment.repository_folder, @path)
    assignment_revisions = []
    all_revisions = repo.get_all_revisions
    all_revisions.each do |revision|
      # store the collected revision
      if @collected_revision.nil? && collected_submission &&
           collected_submission.revision_identifier == revision.revision_identifier.to_s
        @collected_revision = revision
      end
      # store the assignment-relevant revisions
      next if !revision.path_exists?(assignment_path) || !revision.changes_at_path?(assignment_path)
      assignment_revisions << revision
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
    assignment_revisions = all_revisions if assignment_revisions.empty?
    @revision = assignment_revisions[0] if @revision.nil? # latest relevant revision
    @revisions_history = assignment_revisions.map { |revision| { id: revision.revision_identifier,
                                                                 id_ui: revision.revision_identifier_ui,
                                                                 date: revision.timestamp} }

    respond_to do |format|
      format.html
      format.json do
        previous_path = File.split(@path).first
        render json: get_repo_browser_table_info(@grouping.assignment, @revision, @revision.revision_identifier, @path,
                                                 previous_path, @grouping.id)
      end
    end

    repo.close
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

    user_group = @grouping.group
    @path = params[:path] || '/'

    # Some vars need to be set in update_files too, so do this in a
    # helper. See update_files action where this is used as well.
    set_filebrowser_vars(user_group, @assignment)

    # generate flash messages
    if @assignment.submission_rule.can_collect_now?(@grouping.inviter.section)
      flash_message(:warning, @assignment.submission_rule.after_collection_message)
    elsif @assignment.grouping_past_due_date?(@grouping)
      flash_message(:warning, @assignment.submission_rule.overtime_message(@grouping))
    end

    if !@grouping.is_valid?
      flash_message(:error, t(:invalid_group_warning))
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

  def populate_file_manager_react
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = current_user.accepted_grouping_for(@assignment.id)
    user_group = @grouping.group
    revision_identifier = params[:revision_identifier]
    @path = params[:path] || '/'
    @previous_path = File.split(@path).first

    repo = user_group.repo
    if revision_identifier.nil?
      @revision = repo.get_latest_revision
      revision_identifier = @revision.revision_identifier
    else
      @revision = repo.get_revision(revision_identifier)
    end
    exit_directory = get_exit_directory(@previous_path, @grouping.id,
                                        revision_identifier, @revision,
                                        @assignment.repository_folder,
                                        'file_manager')
    full_path = File.join(@assignment.repository_folder, @path)
    if @revision.path_exists?(full_path)
      files = @revision.files_at_path(full_path)
      files_info = get_files_info(files, @assignment.id, revision_identifier, @path,
                                  @grouping.id)

      directories = @revision.directories_at_path(full_path)
      directories_info = get_directories_info(directories, revision_identifier,
                                              @path, @grouping.id, 'file_manager')
      render json: exit_directory + files_info + directories_info
    else
      render json: exit_directory
    end
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
      flash_now(:error, t('results.must_select_a_group_to_collect'))
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
      success = I18n.t('collect_submissions.collection_job_started_for_groups',
                       assignment_identifier: assignment.short_identifier)
    end
    if partition[1].count > 0
      error = I18n.t('collect_submissions.could_not_collect_some',
                     assignment_identifier: assignment.short_identifier)
    end
    flash_now(:success, success) unless success.empty?
    flash_now(:error, error) unless error.empty?

    render 'shared/_poll_job.js.erb'
  end

  def run_tests
    if !params.has_key?(:groupings) || params[:groupings].empty?
      flash_now(:error, t('results.must_select_a_group'))
      head 400
      return
    end
    assignment = Assignment.includes(:groupings).find(params[:assignment_id])
    groupings = assignment.groupings.find(params[:groupings])
    partition = groupings.partition &:has_submission?
    if partition[0].count > 0
      success = I18n.t('automated_tests.tests_running',
                       assignment_identifier: assignment.short_identifier)
      error = ''
      partition[0].each do |g|
        begin
          AutomatedTestsClientHelper.request_a_test_run(
            request.protocol + request.host_with_port,
            g.id,
            current_user,
            g.current_submission_used.id)
        rescue => e
          error += "#{g.group.group_name}: #{e.message}. "
        end
      end
    end
    if partition[1].count > 0
      flash_now(:error, I18n.t('automated_tests.need_submission'))
    end
    render json: { success: success, error: error }
  end

  # The table of submissions for an assignment and related actions and links.
  def browse
    @assignment = Assignment.find(params[:assignment_id])
    @groupings = Grouping.get_groupings_for_assignment(@assignment,
                                                       current_user)
    @sections = Section.order(:name)
    @tas = @assignment.ta_memberships.includes(grouping: [:tas]).uniq.pluck(:user_name)

    @available_sections = Hash.new
    if @assignment.submission_rule.can_collect_now?
      @available_sections[t('groups.unassigned_students')] = 0
    end
    if Section.all.size > 0
      @section_column = "{
        id: 'section',
        content: '#{Section.model_name.human}',
        sortable: true
      },"
      Section.all.each do |section|
        if @assignment.submission_rule.can_collect_now?(section)
          @available_sections[section.name] = section.id
        end
      end
    else
      @section_column = ''
    end

    if @assignment.submission_rule.type == 'GracePeriodSubmissionRule'
      @grace_credit_column = "{
        id: 'grace_credits_used',
        content: '#{t(:'browse_submissions.grace_credits_used')}',
        sortable: true,
        compare: compare_numeric_values,
        searchable: false
      },"
    else
      @grace_credit_column = ''
    end

    if @assignment.past_all_collection_dates?
      flash_now(:notice, t('browse_submissions.grading_can_begin'))
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
            flash_now(:notice, t('browse_submissions.grading_can_begin_for_sections',
                                 sections: sections))
          else
            flash_now(:notice, t('browse_submissions.grading_can_begin_after_for_sections',
                                 time: l(collection_time),
                                 sections: sections))
          end
        end
      else
        collection_time = @assignment.submission_rule.calculate_collection_time
        flash_now(:notice, t('browse_submissions.grading_can_begin_after',
                             time: l(collection_time)))
      end
    end
    render layout: 'assignment_content'
  end

  def populate_submissions_table
    assignment = Assignment.find(params[:assignment_id])
    groupings = Grouping.includes(:current_result,
                                  :tas,
                                  :accepted_students
    )
                        .get_groupings_for_assignment(assignment,
                                                      current_user)

    render json: get_submissions_table_info(assignment, groupings)
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
      unless @assignment.allow_web_submits
        raise t('student.submission.external_submit_only')
      end

      required_files = AssignmentFile.where(assignment_id: @assignment).pluck(:filename)
      filenames = []
      @path = params[:path] || '/'
      @grouping = current_user.accepted_grouping_for(assignment_id)
      unless @grouping.is_valid?
        set_filebrowser_vars(@grouping.group, @assignment)
        return
      end
      unless params[:new_files].nil?
        params[:new_files].each do |f|
          if f.size > MarkusConfigurator.markus_config_max_file_size
            max_size_MB = (MarkusConfigurator.markus_config_max_file_size / 1000000.00).round(2)
            error_message = "Error occurred while uplading file \"#{ f.original_filename }\"" \
               ": The size of the uploaded file exceeds the maximum of #{ max_size_MB.to_s } MB."
            flash_message(:error, error_message)
            return
          elsif f.size == 0
            flash_message(:warning, t('student.submission.empty_file_warning', file_name: f.original_filename))
          end
        end
      end
      @grouping.group.access_repo do |repo|

        assignment_path = Pathname.new(@assignment.repository_folder)
        current_path = assignment_path.join(@path[1..-1]) # remove trailing '/' or join won't join

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
              file_path = current_path.join(filename)
              file_path_relative = file_path.relative_path_from(assignment_path).to_s
              file_path = file_path.to_s
              txn.remove(file_path, file_revisions[filename])
              log_messages.push("Student '#{current_user.user_name}' deleted file '#{file_path_relative}' "\
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
            set_filebrowser_vars(@grouping.group, @assignment)
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
          if @assignment.submission_rule.can_collect_now?(current_user.section)
            flash_message(:warning, @assignment.submission_rule.commit_after_collection_message)
          end
          # can't use redirect_to here. See comment of this action for details.
          set_filebrowser_vars(@grouping.group, @assignment)

        rescue  => e
          m_logger = MarkusLogger.instance
          m_logger.log(e.message)
          flash_message(:warning, e.message)
          set_filebrowser_vars(@grouping.group, @assignment)
        end
      end
    ensure
      redirect_to action: :file_manager
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
      redirect_to :back
      return
    end

    file = SubmissionFile.find(params[:submission_file_id])
    if file.is_supported_image?
      render json: { type: 'image' }
    elsif file.is_pdf?
      render json: { type: 'pdf' }
    else
      path = params[:path] || '/'
      grouping.group.access_repo do |repo|
        revision = repo.get_revision(submission.revision_identifier)

        begin
          raw_file = revision.files_at_path(File.join(assignment.repository_folder,
                                                  path))[file.filename]
          file_contents = repo.download_as_string(raw_file)
        rescue Exception => e
          render text: I18n.t('student.submission.missing_file',
                              file_name: file.filename, message: e.message)
          next  # exit the block
        end

        if SubmissionFile.is_binary?(file_contents)
          # If the file appears to be binary, send it as a download
          render text: 'not a plaintext file'
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
        render text: I18n.t('student.submission.missing_file',
                            file_name: params[:file_name], message: e.message)
        return
      end

      if SubmissionFile.is_binary?(file_contents)
        # If the file appears to be binary, send it as a download
        send_data file_contents,
                  disposition: 'attachment',
                  filename: params[:file_name]
      else
        # Otherwise, sanitize it for HTML and blast it out to the screen
        sanitized_contents = ERB::Util.html_escape(file_contents)
        render text: sanitized_contents, layout: 'sanitized_html'
      end
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
            redirect_to :back
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
    revision_identifier = params[:revision_identifier]
    if revision_identifier && revision_identifier == '0'
      render text: t('student.submission.no_revision_available')
      return
    end

    @assignment = Assignment.find(params[:assignment_id])
    @grouping = find_appropriate_grouping(@assignment.id, params)
    repo_folder = @assignment.repository_folder
    full_path = File.join(repo_folder, params[:path] || '/')
    zip_name = "#{repo_folder}-#{@grouping.group.repo_name}"
    @grouping.group.access_repo do |repo|
      @revision = if revision_identifier.nil?
                    repo.get_latest_revision
                  else
                    repo.get_revision(revision_identifier)
                  end
      zip_path = "tmp/#{@assignment.short_identifier}_" +
          "#{@grouping.group.group_name}_r#{@revision.revision_identifier}.zip"

      no_files = false

      # Open Zip file and fill it with all the files in the repo_folder
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|

        no_files = downloads_subdirectories('',
                                            full_path,
                                            zip_file, zip_name, repo)
      end

      if no_files != true
        # Send the Zip file
        send_file zip_path, disposition: 'inline', filename: zip_name + '.zip'
      end

    end
  end

  # Given a subdirectory, its path, and an already created zip_file,
  # fill the subdirectory within the zip_file with all of its files.
  # Recursively fills the subdirectory with files and folders within
  # it.
  # Helper method for downloads.
  def downloads_subdirectories(subdirectory, subdirectory_path, zip_file,
                               zip_name, repo)
    files = @revision.files_at_path(subdirectory_path)
    # In order to recursively download all files, find the sub-directories
    directories = @revision.directories_at_path(subdirectory_path)

    if files.count == 0
      if subdirectory == ''
        render text: t('student.submission.no_files_available')
        return true
      end
      # No files in subdirectory
      return
    end

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
                                 zip_file, zip_name, repo)
      end
    end
  end

  # Release or unrelease submissions
  def update_submissions
    if !params.has_key?(:groupings) || params[:groupings].empty?
      flash_now(:error, t('results.must_select_a_group'))
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
    render text: l(Time.zone.now)
  end

  private

  # Used in update_files and file_manager actions
  def set_filebrowser_vars(user_group, assignment)
    user_group.access_repo do |repo|
      @revision = repo.get_latest_revision
      @files = @revision.files_at_path(File.join(@assignment.repository_folder,
                                                 @path))
      @missing_assignment_files = []
      assignment.assignment_files.each do |assignment_file|
        unless @revision.path_exists?(File.join(assignment.repository_folder,
                                                assignment_file.filename))
          @missing_assignment_files.push(assignment_file)
        end
      end
    end
  end
end
