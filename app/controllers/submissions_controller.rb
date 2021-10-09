class SubmissionsController < ApplicationController
  include SubmissionsHelper
  include RepositoryHelper
  before_action { authorize! }

  content_security_policy only: [:repo_browser, :file_manager] do |p|
    # required because heic2any uses libheif which calls
    # eval (javascript) and creates an image as a blob.
    # TODO: remove this when possible
    p.script_src :self, "'strict-dynamic'", "'unsafe-eval'"
    p.img_src :self, :blob
  end

  content_security_policy_report_only only: :notebook_content

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
    @assignment = @grouping.assignment
    @collected_revision = nil
    @revision = nil
    @grouping.access_repo do |repo|
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
              Time.zone.parse(params[:revision_timestamp]).in_time_zone >= revision.server_timestamp)
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
    grouping.access_repo do |repo|
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
    if @grouping.nil?
      head 400
      return
    end

    authorize! @grouping, to: :view_file_manager?

    @path = params[:path] || '/'

    # Some vars need to be set in update_files too, so do this in a
    # helper. See update_files action where this is used as well.
    set_filebrowser_vars(@grouping)
    flash_file_manager_messages

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
    grouping.access_repo do |repo|
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
      assignment_id: @grouping.assessment_id,
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
    is_scanned_exam = assignment.scanned_exam?
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
    if collectable.count > 0
      @current_job = SubmissionsJob.perform_later(collectable,
                                                  collection_dates: collection_dates.transform_keys(&:to_s))
      session[:job_id] = @current_job.job_id
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
    group_ids = groupings.select(&:has_non_empty_submission?).map do |g|
      submission = g.current_submission_used
      unless flash_allowance(:error, allowance_to(:run_tests?, current_user, context: { submission: submission })).value
        head 400
        return
      end
      g.group_id
    end
    success = ''
    error = ''
    begin
      if !group_ids.empty?
        if flash_allowance(:error, allowance_to(:run_tests?, current_user, context: { assignment: assignment })).value
          @current_job = AutotestRunJob.perform_later(request.protocol + request.host_with_port,
                                                      current_user.id,
                                                      assignment.id,
                                                      group_ids)
          session[:job_id] = @current_job.job_id
          success = I18n.t('automated_tests.tests_running', assignment_identifier: assignment.short_identifier)
        end
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

    return if current_user.ta?
    return if @assignment.scanned_exam

    if @assignment.past_all_collection_dates?
      flash_now(:success, t('submissions.grading_can_begin'))
      return
    end

    if @assignment.section_due_dates_type
      section_due_dates = Hash.new
      now = Time.current
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
    unzip = params[:unzip] == 'true'
    @assignment = Assignment.find(assignment_id)
    raise t('student.submission.external_submit_only') if current_user.student? && !@assignment.allow_web_submits

    @path = params[:path].blank? ? '/' : params[:path]

    if current_user.student?
      @grouping = current_user.accepted_grouping_for(assignment_id)
      unless @grouping.is_valid?
        set_filebrowser_vars(@grouping)
        flash_file_manager_messages
        head :bad_request
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
      @grouping.access_repo do |repo|
        # Create transaction, setting the author.  Timestamp is implicit.
        txn = repo.get_transaction(current_user.user_name)
        should_commit = true
        path = Pathname.new(@grouping.assignment.repository_folder).join(@path.gsub(%r{^/}, ''))

        if current_user.student? && @grouping.assignment.only_required_files
          required_files = @grouping.assignment.assignment_files.pluck(:filename)
                                    .map { |name| File.join(@grouping.assignment.repository_folder, name) }
        else
          required_files = nil
        end

        upload_files_helper(new_folders, new_files, unzip: unzip) do |f|
          if f.is_a?(String) # is a directory
            success, msgs = add_folder(f, current_user, repo, path: path, txn: txn)
            should_commit &&= success
            messages = messages.concat msgs
          else
            success, msgs = add_file(f, current_user, repo,
                                     path: path, txn: txn, check_size: true, required_files: required_files)
            should_commit &&= success
            messages.concat msgs
          end
        end
        if delete_files.present?
          success, msgs = remove_files(delete_files, current_user, repo, path: path, txn: txn)
          should_commit &&= success
          messages.concat msgs
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
          head :unprocessable_entity
        end
      end
      flash_repository_messages messages
      set_filebrowser_vars(@grouping)
      flash_file_manager_messages
    end
  rescue StandardError => e
    flash_message(:error, e.message)
    head :bad_request
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
    elsif file.is_pynb?
      render json: { type: 'jupyter-notebook' }
    elsif file.is_rmd?
      render json: { type: 'rmarkdown' }
    else
      grouping.access_repo do |repo|
        revision = repo.get_revision(submission.revision_identifier)
        raw_file = revision.files_at_path(file.path)[file.filename]
        file_type = FileHelper.get_file_type(file.filename)
        if raw_file.nil?
          file_contents = I18n.t('student.submission.missing_file', file_name: file.filename)
          file_type = 'unknown'
        else
          file_contents = repo.download_as_string(raw_file)
          file_contents.encode!('UTF-8', invalid: :replace, undef: :replace, replace: '�')

          if params[:force_text] != 'true' && SubmissionFile.is_binary?(file_contents)
            # If the file appears to be binary, display a warning
            file_contents = I18n.t('submissions.cannot_display')
            file_type = 'binary'
          end
        end
        render json: { content: file_contents.to_json, type: file_type }
      end
    end
  end

  def download
    preview = params[:preview] == 'true'

    if %(jupyter-notebook rmarkdown).include?(FileHelper.get_file_type(params[:file_name])) && preview
      redirect_to action: :notebook_content,
                  assignment_id: params[:assignment_id],
                  grouping_id: params[:grouping_id],
                  revision_identifier: params[:revision_identifier],
                  path: params[:path],
                  file_name: params[:file_name]
      return
    end
    @assignment = Assignment.find(params[:assignment_id])
    # find_appropriate_grouping can be found in SubmissionsHelper
    @grouping = find_appropriate_grouping(@assignment.id, params)

    revision_identifier = params[:revision_identifier]
    path = params[:path] || '/'
    @grouping.access_repo do |repo|
      if revision_identifier.nil?
        @revision = repo.get_latest_revision
      else
        @revision = repo.get_revision(revision_identifier)
      end

      file_contents = nil
      begin
        file = @revision.files_at_path(File.join(@assignment.repository_folder,
                                                 path))[params[:file_name]]
        file_contents = repo.download_as_string(file)
        file_contents = I18n.t('submissions.cannot_display') if preview && SubmissionFile.is_binary?(file_contents)
      rescue ArgumentError
        # Handle UTF8 encoding error
        if file_contents.nil?
          raise
        else
          file_contents.encode!('UTF-8', invalid: :replace, undef: :replace, replace: '�')
        end
      rescue Exception => e
        flash_message(:error, e.message)
        render plain: I18n.t('student.submission.missing_file',
                            file_name: params[:file_name], message: e.message)
        return
      end

      send_data_download file_contents, filename: params[:file_name]
    end
  end

  # Download a csv file containing current submission data for all groupings visible
  # to the current user.
  def download_summary
    assignment = Assignment.find(params[:assignment_id])
    data = assignment.current_submission_data(current_user)

    # This hash matches what is displayed by the RawSubmissionTable react component.
    # Ensure that changes to what is displayed in that table are reflected here as well.
    header = {
      group_name: t('activerecord.models.group.one'),
      section: t('activerecord.models.section', count: 1),
      start_time: t('activerecord.attributes.assignment.start_time'),
      submission_time: t('submissions.commit_date'),
      grace_credits_used: t('submissions.grace_credits_used'),
      marking_state: t('activerecord.attributes.result.marking_state'),
      final_grade: t('activerecord.attributes.result.total_mark'),
      tags: t('activerecord.models.tag.other')
    }
    header.delete(:start_time) unless assignment.is_timed

    if header.nil?
      csv_data = ''
    else
      csv_data = MarkusCsv.generate(data, [header.values]) do |data_hash|
        header.keys.map do |h|
          value = data_hash[h]
          value.is_a?(Array) ? value.join(', ') : value
        end
      end
    end

    send_data_download csv_data, filename: "#{assignment.short_identifier}_submissions.csv"
  end

  def notebook_content
    if params[:select_file_id]
      file = SubmissionFile.find(params[:select_file_id])
      file_contents = file.retrieve_file
      grouping = file.submission.grouping
      assignment = grouping.assignment
      path = Pathname.new(file.path).relative_path_from(Pathname.new(assignment.repository_folder)).to_s
      revision_identifier = file.submission.revision_identifier
      filename = file.filename
    else
      assignment = Assignment.find(params[:assignment_id])
      grouping = find_appropriate_grouping(assignment.id, params)
      revision_identifier = params[:revision_identifier]

      path = params[:path] || '/'
      file_contents = grouping.access_repo do |repo|
        if revision_identifier.nil?
          revision = repo.get_latest_revision
        else
          revision = repo.get_revision(revision_identifier)
        end
        file = revision.files_at_path(File.join(assignment.repository_folder, path))[params[:file_name]]
        repo.download_as_string(file)
      end
      filename = params[:file_name]
    end

    file_path = "#{assignment.repository_folder}/#{path}/#{filename}"
    unique_path = "#{grouping.group.repo_name}/#{file_path}.#{revision_identifier}"
    @notebook_type = FileHelper.get_file_type(filename)
    @notebook_content = notebook_to_html(file_contents, unique_path, @notebook_type)
    render layout: 'notebook'
  end

  ##
  # Prepare all files from groupings with id in +params[:groupings]+ to be downloaded in a .zip file.
  ##
  def zip_groupings_files
    assignment = Assignment.find(params[:assignment_id])

    groupings = assignment.groupings.where(id: params[:groupings]&.map(&:to_i))

    zip_path = zipped_grouping_file_name(assignment)

    if current_user.ta?
      groupings = groupings.joins(:ta_memberships).where('memberships.user_id': current_user.id)
    end

    @current_job = DownloadSubmissionsJob.perform_later(groupings.ids, zip_path.to_s, assignment.id)
    session[:job_id] = @current_job.job_id

    render 'shared/_poll_job.js.erb'
  end

  # download a zip file previously prepared by calling the
  # zip_groupings_files method
  def download_zipped_file
    assignment = Assignment.find(params[:assignment_id])
    zip_path = zipped_grouping_file_name(assignment)
    zip_file = File.basename(zip_path)
    begin
      send_file zip_path, disposition: 'inline', filename: zip_file
    rescue ActionController::MissingFile
      flash_message(:error, I18n.t('submissions.download_zipped_file.file_missing', zip_file: zip_file))
      redirect_back(fallback_location: root_path)
    end
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
    grouping.access_repo do |repo|
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
      Zip::File.open(zip_path, create: true) do |zip_file|
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
    end
  end

  # See Assignment.get_repo_checkout_commands for details
  def download_repo_checkout_commands
    assignment = Assignment.find(params[:assignment_id])
    ssh_url = allowed_to?(:view?, with: KeyPairPolicy) && params[:url_type] == 'ssh'
    svn_commands = assignment.get_repo_checkout_commands(ssh_url: ssh_url)
    send_data svn_commands.join("\n"),
              disposition: 'attachment',
              type: 'text/plain',
              filename: "#{assignment.short_identifier}_repo_checkouts"
  end

  # See Assignment.get_repo_list for details
  def download_repo_list
    assignment = Assignment.find(params[:assignment_id])
    send_data assignment.get_repo_list(ssh: allowed_to?(:view?, with: KeyPairPolicy)),
              disposition: 'attachment',
              filename: "#{assignment.short_identifier}_repo_list.csv"
  end

  def set_result_marking_state
    if !params.key?(:groupings) || params[:groupings].empty?
      flash_now(:error, t('groups.select_a_group'))
      head 400
      return
    end
    results = Result.where(id: Grouping.joins(:current_result).where(id: params[:groupings]).select('results.id'))
    errors = Hash.new { |h, k| h[k] = [] }
    results.each do |result|
      unless result.update(marking_state: params[:marking_state])
        errors[result.errors.full_messages.first] << result.submission.grouping.group.group_name
      end
    end
    errors.each do |message, groups|
      flash_now(:error, "#{message}: #{groups.join(', ')}")
    end
    head :ok
  end

  private

  def notebook_to_html(file_contents, unique_path, type)
    cache_file = Pathname.new('tmp/notebook_html_cache') + "#{unique_path}.html"
    unless File.exist? cache_file
      FileUtils.mkdir_p(cache_file.dirname)
      if type == 'jupyter-notebook'
        args = [
          File.join(Settings.python.bin, 'jupyter-nbconvert'), '--to', 'html', '--stdin', '--output', cache_file.to_s
        ]
      else
        args = [Settings.pandoc, '--from', 'markdown', '--to', 'html', '--output', cache_file.to_s]
      end
      _stdout, stderr, status = Open3.capture3(*args, stdin_data: file_contents)
      return "#{I18n.t('submissions.cannot_display')}<br/><br/>#{stderr.lines.last}" unless status.exitstatus.zero?
    end
    File.read(cache_file)
  end

  # Return a relative path to a temporary zip file (which may or may not exists).
  # The name of this file is unique by the +assignment+ and current user.
  def zipped_grouping_file_name(assignment)
    # create the zip name with the user name so that we avoid downloading files created by another user
    short_id = assignment.short_identifier
    Pathname.new('tmp') + Pathname.new(short_id + '_' + current_user.user_name + '.zip')
  end

  # Used in update_files and file_manager actions
  def set_filebrowser_vars(grouping)
    grouping.access_repo do |repo|
      @revision = repo.get_latest_revision
      @files = @revision.files_at_path(File.join(grouping.assignment.repository_folder, @path))
      @missing_assignment_files = grouping.missing_assignment_files(@revision)
    end
  end

  # Generate flash messages to show the status of a group's submitted files.
  # Used in update_files and file_manager actions.
  # Requires @grouping, @assignment, and @missing_assignment_files variables to be set.
  def flash_file_manager_messages
    if @assignment.is_timed && @grouping.start_time.nil? && @grouping.past_collection_date?
      flash_message(:warning,
                    I18n.t('assignments.timed.past_end_time') + ' ' + I18n.t('submissions.past_collection_time'))
    elsif @assignment.is_timed && !@grouping.start_time.nil? && !@assignment.grouping_past_due_date?(@grouping)
      flash_message(:notice, I18n.t('assignments.timed.time_until_due_warning', due_date: I18n.l(@grouping.due_date)))
    elsif @grouping.past_collection_date?
      flash_message(:warning,
                    @assignment.submission_rule.class.human_attribute_name(:after_collection_message) + ' ' +
                      I18n.t('submissions.past_collection_time'))
    elsif @assignment.grouping_past_due_date?(@grouping)
      flash_message(:warning, @assignment.submission_rule.overtime_message(@grouping))
    end

    if !@grouping.is_valid?
      flash_message(:error, t('groups.invalid_group_warning'))
    elsif !@missing_assignment_files.blank?
      flash_message(:warning,
                    partial: 'submissions/missing_assignment_file_toggle_list',
                    locals: { missing_assignment_files: @missing_assignment_files })
    end

    if @assignment.allow_web_submits && @assignment.vcs_submit
      flash_message(:notice, t('submissions.student.version_control_warning'))
    end
  end

  # Recursively return data for all files in a submission.
  # Based on Submission#populate_with_submission_files.
  def get_all_file_data(revision, grouping, path)
    full_path = File.join(grouping.assignment.repository_folder, path)
    return [] unless revision.path_exists?(full_path)

    anonymize = current_user.ta? && grouping.assignment.anonymize_groups

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
        data[:modified] = file_obj.last_modified_date.to_i
        data[:revision_by] = '' if anonymize
        data
      else
        { key: "#{file_name}/" }
      end
    end.compact
  end
end
