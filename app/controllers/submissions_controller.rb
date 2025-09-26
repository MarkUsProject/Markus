require 'json'

class SubmissionsController < ApplicationController
  include SubmissionsHelper
  include RepositoryHelper
  before_action { authorize! }

  authorize :from_codeviewer, through: :from_codeviewer_param
  authorize :view_token, through: :view_token_param

  PERMITTED_IFRAME_SRC = ([:self] + %w[https://www.youtube.com https://drive.google.com https://docs.google.com]).freeze
  content_security_policy only: [:repo_browser, :file_manager] do |p|
    # required because heic2any uses libheif which calls
    # eval (javascript) and creates an image as a blob.
    # TODO: remove this when possible
    p.script_src :self, "'strict-dynamic'", "'unsafe-eval'"
    p.img_src :self, :blob
    p.frame_src(*PERMITTED_IFRAME_SRC)
  end

  content_security_policy_report_only only: :html_content

  def index
    respond_to do |format|
      format.json do
        assignment = Assignment.find(params[:assignment_id])
        render json: {
          groupings: assignment.current_submission_data(current_role),
          sections: current_course.sections.pluck(:id, :name).to_h
        }
      end
    end
  end

  def repo_browser
    # TODO: move this to a new groupings controller
    @assignment = Assignment.find_by(id: params[:assignment_id])
    @grouping = @assignment.groupings.find(params[:grouping_id])
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
        if @revision.nil? && ((params[:revision_identifier] &&
            params[:revision_identifier] == revision.revision_identifier.to_s) ||
            (params[:revision_timestamp] &&
              Time.zone.parse(params[:revision_timestamp]).in_time_zone >= revision.server_timestamp))
          @revision = revision
        end
      end
      # find another relevant revision to display if @revision.nil?
      # 1) the latest assignment revision, or 2) the first repo revision
      @revision ||= assignment_revisions[0] || all_revisions[-1]
    end
    render layout: 'assignment_content'
  end

  def revisions
    assignment = Assignment.find_by(id: params[:assignment_id])
    grouping = assignment.groupings.find(params[:grouping_id])
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
    unless allowed_to?(:see_hidden?, @assignment)
      render 'shared/http_status',
             formats: [:html],
             locals: {
               code: '404',
               message: HttpStatusHelper::ERROR_CODE['message']['404']
             },
             status: :not_found,
             layout: false
      return
    end
    @grouping = current_role.accepted_grouping_for(@assignment.id)
    if @grouping.nil?
      head :bad_request
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
    if current_role.student?
      grouping = current_role.accepted_grouping_for(assignment)
    else
      grouping = assignment.groupings.find(params[:grouping_id])
    end
    entries = []
    grouping.access_repo do |repo|
      if current_role.student? || params[:revision_identifier].blank?
        revision = repo.get_latest_revision
      else
        revision = repo.get_revision(params[:revision_identifier])
      end
      entries = get_all_file_data(revision, grouping, '')
    end

    response = {
      entries: entries,
      only_required_files: assignment.only_required_files,
      required_files: assignment.assignment_files.pluck(:filename).sort,
      max_file_size: assignment.course.max_file_size / 1_000_000,
      number_of_missing_files: grouping.missing_assignment_files(@revision).length
    }

    render json: response
  end

  def manually_collect_and_begin_grading
    assignment = Assignment.find_by(id: params[:assignment_id])
    @grouping = assignment.groupings.find(params[:grouping_id])

    unless @grouping.current_submission_used.nil?
      released = @grouping.current_submission_used.results.exists?(released_to_students: true)

      if released
        flash_message(:error, I18n.t('submissions.collect.could_not_collect_released'))
        return redirect_to repo_browser_course_assignment_submissions_path(current_course, assignment,
                                                                           grouping_id: @grouping.id)
      end
    end

    @revision_identifier = params[:current_revision_identifier]
    apply_late_penalty = if params[:apply_late_penalty].nil?
                           false
                         else
                           params[:apply_late_penalty]
                         end
    retain_existing_grading = if params[:retain_existing_grading].nil?
                                false
                              else
                                params[:retain_existing_grading]
                              end

    SubmissionsJob.perform_now([@grouping],
                               apply_late_penalty: apply_late_penalty,
                               revision_identifier: @revision_identifier,
                               retain_existing_grading: retain_existing_grading)

    submission = @grouping.reload.current_submission_used
    redirect_to edit_course_result_path(course_id: current_course.id, id: submission.get_latest_result.id)
  end

  def uncollect_all_submissions
    assignment = Assignment.includes(:groupings).find(params[:assignment_id])
    @current_job = UncollectSubmissions.perform_later(assignment)
    session[:job_id] = @current_job.job_id

    respond_to do |format|
      format.js { render 'shared/_poll_job' }
    end
  end

  def collect_submissions
    if !params.key?(:groupings) || params[:groupings].empty?
      flash_now(:error, t('groups.select_a_group'))
      head :bad_request
      return
    end
    collect_current = params[:collect_current] == 'true'
    apply_late_penalty = params[:apply_late_penalty] == 'true'
    retain_existing_grading = params[:retain_existing_grading] == 'true'
    assignment = Assignment.includes(:groupings).find(params[:assignment_id])
    groupings = assignment.groupings.find(params[:groupings])
    collectable = []
    some_before_due = false
    some_released = Grouping.joins(current_submission_used: :results)
                            .where('results.released_to_students': true)
                            .where(id: groupings)
                            .ids.to_set
    collection_dates = assignment.all_grouping_collection_dates
    is_scanned_exam = assignment.scanned_exam?
    groupings.each do |grouping|
      unless is_scanned_exam || collect_current
        collect_now = collection_dates[grouping.id] <= Time.current
        some_before_due = true unless collect_now
        next unless collect_now
      end
      next if params[:override] != 'true' && grouping.is_collected?
      next if some_released.include?(grouping.id)

      collectable << grouping
    end
    unless collectable.empty?
      current_job = SubmissionsJob.perform_later(collectable,
                                                 enqueuing_user: @current_user,
                                                 collection_dates: collection_dates.transform_keys(&:to_s),
                                                 collect_current: collect_current,
                                                 apply_late_penalty: apply_late_penalty,
                                                 notify_socket: true,
                                                 retain_existing_grading: retain_existing_grading)
      CollectSubmissionsChannel.broadcast_to(@current_user, ActiveJob::Status.get(current_job).to_h)
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
    head :ok
  end

  def run_tests
    if !params.key?(:groupings) || params[:groupings].empty?
      flash_now(:error, t('groups.select_a_group'))
      head :bad_request
      return
    end
    assignment = Assignment.includes(:test_groups, groupings: :current_submission_used).find(params[:assignment_id])

    # If no test groups can be run by instructors, flash appropriate message and return early
    test_group_categories = assignment.test_groups.pluck(:autotest_settings).pluck('category')
    instructor_runnable = test_group_categories.any? { |category| category.include? 'instructor' }
    unless instructor_runnable
      flash_now(:info, I18n.t('automated_tests.no_instructor_runnable_tests'))
      return
    end

    groupings = assignment.groupings.find(params[:groupings])
    # .where.not(current_submission_used: nil) potentially makes find fail with RecordNotFound
    group_ids = groupings.filter_map do |g|
      next unless g.has_non_empty_submission?

      submission = g.current_submission_used
      unless flash_allowance(:error, allowance_to(:run_tests?, current_role, context: { submission: submission })).value
        head :bad_request
        return
      end
      g.group_id
    end
    success = ''
    error = ''
    begin
      if !group_ids.empty?
        if flash_allowance(:error, allowance_to(:run_tests?, current_role, context: { assignment: assignment })).value
          AutotestRunJob.perform_later(request.protocol + request.host_with_port,
                                       current_role.id,
                                       assignment.id,
                                       group_ids,
                                       user: current_user)
          success = I18n.t('automated_tests.autotest_run_job.status.in_progress')
        end
      else
        error = I18n.t('automated_tests.need_submission')
      end
    rescue StandardError => e
      error = e.message
    end
    if success.present?
      flash_message(:success, success)
    end
    if error.present?
      flash_message(:error, error)
    end
    render json: { success: success, error: error }
  end

  # The table of submissions for an assignment and related actions and links.
  def browse
    @assignment = Assignment.find(params[:assignment_id])
    self.class.layout 'assignment_content'

    return if current_role.ta?
    return if @assignment.scanned_exam

    if @assignment.past_all_collection_dates?
      flash_now(:success, t('submissions.grading_can_begin'))
      return
    end

    if @assignment.section_due_dates_type
      section_due_dates = {}
      now = Time.current
      current_course.sections.find_each do |section|
        collection_time = @assignment.submission_rule
                                     .calculate_collection_time(section)
        collection_time = now if now >= collection_time
        if section_due_dates[collection_time].nil?
          section_due_dates[collection_time] = []
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
    raise t('student.submission.external_submit_only') if current_role.student? && !@assignment.allow_web_submits

    @path = params[:path].presence || '/'

    if current_role.student?
      @grouping = current_role.accepted_grouping_for(assignment_id)
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

    # The new url that will be added
    new_url = params[:new_url] || ''

    unless delete_folders.empty? && new_folders.empty?
      authorize! to: :manage_subdirectories?
    end

    if delete_files.empty? && new_files.empty? && new_folders.empty? && delete_folders.empty? && new_url.empty?
      flash_message(:warning, I18n.t('student.submission.no_action_detected'))
    else
      messages = []
      path = FileHelper.checked_join(@grouping.assignment.repository_folder, @path.gsub(%r{^/}, ''))
      if path.nil?
        raise I18n.t('errors.invalid_path')
      end
      path = Pathname.new(path)
      @grouping.access_repo do |repo|
        # Create transaction, setting the author.  Timestamp is implicit.
        txn = repo.get_transaction(current_user.user_name)
        should_commit = true

        if current_role.student? && @grouping.assignment.only_required_files
          required_files = @grouping.assignment.assignment_files.pluck(:filename)
                                    .map { |name| File.join(@grouping.assignment.repository_folder, name) }
        else
          required_files = nil
        end

        if new_url.present?
          url_filename = params[:url_text]
          raise I18n.t('submissions.urls_disabled') unless @assignment.url_submit
          raise I18n.t('submissions.invalid_url', item: new_url) unless is_valid_url?(new_url)
          raise I18n.t('submissions.no_url_name', url: new_url) if url_filename.blank?
          url_file = Tempfile.new
          url_file.write(new_url)
          url_file.rewind
          url_filename = FileHelper.sanitize_file_name(url_filename)
          new_url_file = ActionDispatch::Http::UploadedFile.new(filename: "#{url_filename}.markusurl",
                                                                tempfile: url_file,
                                                                type: 'text/url')
          success, msgs = add_file(new_url_file, current_role, repo,
                                   path: path, txn: txn, check_size: true, required_files: required_files)
          should_commit &&= success
          messages.concat msgs
        end

        upload_files_helper(new_folders, new_files, unzip: unzip) do |f|
          if f.is_a?(String) # is a directory
            authorize! to: :manage_subdirectories? # ensure user is authorized for directories in zip files
            success, msgs = add_folder(f, current_role, repo, path: path, txn: txn, required_files: required_files)
          else
            content_type = Marcel::MimeType.for Pathname.new(f)
            file_extension = File.extname(f.original_filename).downcase
            expected_mime_type = Marcel::MimeType.for extension: file_extension

            if content_type != expected_mime_type && content_type != 'application/octet-stream'
              flash_message(:warning, I18n.t('student.submission.file_extension_mismatch', extension: file_extension))
            end
            success, msgs = add_file(f, current_role, repo,
                                     path: path, txn: txn, check_size: true, required_files: required_files)
          end
          should_commit &&= success
          messages.concat msgs
        end
        if delete_files.present?
          success, msgs = remove_files(delete_files, current_role, repo, path: path, txn: txn)
          should_commit &&= success
          messages.concat msgs
        end
        if delete_folders.present?
          success, msgs = remove_folders(delete_folders, current_role, repo, path: path, txn: txn)
          should_commit &&= success
          messages.concat msgs
        end
        if should_commit
          commit_success, commit_msg = commit_transaction(repo, txn)
          flash_message(:success, I18n.t('flash.actions.update_files.success')) if commit_success
          messages << commit_msg
          head :ok
        else
          head :unprocessable_content
        end
      end
      flash_repository_messages messages, @grouping.course
      set_filebrowser_vars(@grouping)
      flash_file_manager_messages
    end
  rescue StandardError => e
    flash_message(:error, e.message)
    head :bad_request
  end

  def download_file
    if params[:download_zip_button]
      download_file_zip
      return
    end
    file = select_file
    if file.nil?
      return head :not_found
    end

    nbconvert_enabled = Rails.application.config.nbconvert_enabled
    rmd_convert_enabled = Rails.application.config.rmd_convert_enabled
    if params[:show_in_browser] == 'true' &&
      ((file.is_pynb? && nbconvert_enabled) || (file.is_rmd? && rmd_convert_enabled))
      redirect_to html_content_course_assignment_submissions_url(current_course,
                                                                 record.grouping.assignment,
                                                                 select_file_id: params[:select_file_id])
      return
    end

    begin
      if params[:include_annotations] == 'true' && !file.is_supported_image?
        file_contents = file.retrieve_file(include_annotations: true)
      else
        file_contents = file.retrieve_file
      end
    rescue StandardError => e
      flash_message(:error, e.message)
      head :internal_server_error
      return
    end

    max_content_size = params[:max_content_size].blank? ? -1 : params[:max_content_size].to_i
    if max_content_size != -1 && file_contents.size > max_content_size
      head :content_too_large
      return
    end

    filename = file.filename
    # Display the file in the page if it is an image/pdf, and download button
    # was not explicitly pressed
    if file.is_supported_image? && !params[:show_in_browser].nil?
      send_data file_contents, type: 'image', disposition: 'inline',
                               filename: filename
    else
      send_data_download file_contents, filename: filename
    end
  end

  def download_file_zip
    submission = record
    if submission.revision_identifier.nil?
      render plain: t('submissions.no_files_available')
      return
    end

    grouping = submission.grouping
    assignment = grouping.assignment
    revision_identifier = submission.revision_identifier
    repo_folder = assignment.repository_folder
    zip_name = "#{repo_folder}-#{grouping.group.repo_name}"

    zip_path = if params[:include_annotations] == 'true'
                 "tmp/#{assignment.short_identifier}_" \
                   "#{grouping.group.group_name}_r#{revision_identifier}_ann.zip"
               else
                 "tmp/#{assignment.short_identifier}_" \
                   "#{grouping.group.group_name}_r#{revision_identifier}.zip"
               end

    files = submission.submission_files
    Zip::File.open(zip_path, create: true) do |zip_file|
      grouping.access_repo do |repo|
        revision = repo.get_revision(revision_identifier)
        repo.send_tree_to_zip(assignment.repository_folder, zip_file, revision) do |file|
          submission_file = files.find_by(filename: file.name, path: file.path)
          submission_file&.retrieve_file(
            include_annotations: params[:include_annotations] == 'true' && !submission_file.is_supported_image?
          )
        end
      end
    end
    # Send the Zip file
    send_file zip_path, disposition: 'inline',
                        filename: zip_name + '.zip'
  end

  def download
    preview = params[:preview] == 'true'
    nbconvert_enabled = Rails.application.config.nbconvert_enabled
    rmd_convert_enabled = Rails.application.config.rmd_convert_enabled
    file_type = FileHelper.get_file_type(params[:file_name])
    if ((file_type == 'jupyter-notebook' && nbconvert_enabled) \
     || (file_type == 'rmarkdown' && rmd_convert_enabled)) && preview
      redirect_to action: :html_content,
                  course_id: current_course.id,
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
      rescue StandardError => e
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
    data = assignment.current_submission_data(current_role)

    # This hash matches what is displayed by the RawSubmissionTable react component.
    # Ensure that changes to what is displayed in that table are reflected here as well.
    header = {
      group_name: t('activerecord.models.group.one'),
      section: t('activerecord.models.section', count: 1),
      start_time: t('activerecord.attributes.assignment.start_time'),
      submission_time: t('submissions.commit_date'),
      grace_credits_used: t('submissions.grace_credits_used'),
      marking_state: t('activerecord.attributes.result.marking_state'),
      final_grade: t('results.total_mark'),
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

  def html_content
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

      path = FileHelper.checked_join(assignment.repository_folder, params[:path] || '/')
      if path.nil?
        flash_message(:error, I18n.t('errors.invalid_path'))
      else
        file_contents = grouping.access_repo do |repo|
          if revision_identifier.nil?
            revision = repo.get_latest_revision
          else
            revision = repo.get_revision(revision_identifier)
          end
          file = revision.files_at_path(path)[params[:file_name]]
          repo.download_as_string(file)
        end
      end
      filename = params[:file_name]
    end

    @file_type = FileHelper.get_file_type(filename)
    if path.nil?
      @html_content = ''
    else
      sanitized_filename = ActiveStorage::Filename.new("#{filename}.#{revision_identifier}").sanitized
      unique_path = File.join(grouping.group.repo_name, path, sanitized_filename)
      if @file_type == 'rmarkdown'
        @html_content = rmd_to_html(file_contents, unique_path)
      else
        @html_content = notebook_to_html(file_contents, unique_path, @file_type)
      end
    end
    render layout: 'html_content'
  end

  ##
  # Prepare all files from groupings with id in +params[:groupings]+ to be downloaded in a .zip file.
  ##
  def zip_groupings_files
    assignment = Assignment.find(params[:assignment_id])

    course = Course.find(params[:course_id])

    groupings = assignment.groupings.where(id: params[:groupings]&.map(&:to_i))

    zip_path = zipped_grouping_file_name(assignment)

    if current_role.ta?
      groupings = groupings.joins(:ta_memberships).where('memberships.role_id': current_role.id)
    end

    @current_job = DownloadSubmissionsJob.perform_later(groupings.ids, zip_path.to_s, assignment.id, course.id,
                                                        print: params[:print] == 'true')
    session[:job_id] = @current_job.job_id

    render 'shared/_poll_job'
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
    # TODO: move this to a grouping controller
    assignment = Assignment.find(params[:assignment_id])
    if current_role.student?
      grouping = current_role.accepted_grouping_for(assignment)
    else
      grouping = assignment.groupings.find(params[:grouping_id])
    end
    zip_name = "#{assignment.short_identifier}-#{grouping.group.group_name}"
    grouping.access_repo do |repo|
      if current_role.student? || params[:revision_identifier].nil?
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
      if files.empty?
        flash_message(:error, t('submissions.no_files_available'))
        redirect_back(fallback_location: root_path)
        return
      end

      zip_path = "tmp/#{assignment.short_identifier}_#{grouping.group.group_name}_" \
                 "#{revision.revision_identifier}.zip"
      # Open Zip file and fill it with all the files in the repo_folder
      Zip::File.open(zip_path, create: true) do |zip_file|
        repo.send_tree_to_zip(assignment.repository_folder, zip_file, revision)
      end

      send_file zip_path, filename: zip_name + '.zip'
    end
  end

  # Release or unrelease submissions
  def update_submissions
    assignment = Assignment.find(params[:assignment_id])
    is_review = assignment.is_peer_review?

    if (!is_review && params[:groupings].blank?) || (is_review && params[:peer_reviews].blank?)
      flash_now(:error, t('groups.select_a_group'))
      head :bad_request
      return
    end
    release = params[:release_results] == 'true'

    begin
      changed = if is_review
                  set_pr_release_on_results(params[:peer_reviews], release)
                else
                  begin
                    Result.set_release_on_results(params[:groupings], release)
                  rescue StandardError => e
                    flash_now(:error, e.message)
                    0
                  end
                end
      if changed > 0
        # These flashes don't get rendered. Find another way to display?
        flash_now(:success, I18n.t('submissions.successfully_changed',
                                   changed: changed))
        if release
          MarkusLogger.instance.log(
            'Marks released for assignment ' \
            "'#{assignment.short_identifier}', ID: '" \
            "#{assignment.id}' for #{changed} group(s)."
          )
        else
          MarkusLogger.instance.log(
            'Marks unreleased for assignment ' \
            "'#{assignment.short_identifier}', ID: '" \
            "#{assignment.id}' for #{changed} group(s)."
          )
        end
      end

      head :ok
    end
  end

  # See Assignment.get_repo_checkout_commands for details
  def download_repo_checkout_commands
    assignment = Assignment.find(params[:assignment_id])
    ssh_url = allowed_to?(:view?, with: KeyPairPolicy) && params[:url_type] == 'ssh'
    checkout_commands = assignment.get_repo_checkout_commands(ssh_url: ssh_url)
    send_data checkout_commands.join("\n"),
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
    assignment = Assignment.find(params[:assignment_id])
    is_review = assignment.is_peer_review?

    if (!is_review && params[:groupings].blank?) || (is_review && params[:peer_reviews].blank?)
      flash_now(:error, t('groups.select_a_group'))
      head :bad_request
      return
    end

    if is_review
      results = Result.joins(:peer_reviews).where('peer_reviews.id': params[:peer_reviews])
    else
      results = assignment.current_results.where('groupings.id': params[:groupings])
    end

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

  # Allows student to cancel a remark request.
  def cancel_remark_request
    @submission = record
    @assignment = record.grouping.assignment
    @course = record.course
    record.remark_result.destroy
    record.get_original_result.update(released_to_students: true)

    redirect_to controller: 'results',
                action: 'view_marks',
                course_id: current_course.id,
                id: record.get_original_result.id
  end

  def update_remark_request
    @submission = record
    @assignment = record.grouping.assignment
    @course = record.course
    if @assignment.past_remark_due_date?
      head :bad_request
    else
      record.update(
        remark_request: params[:submission][:remark_request],
        remark_request_timestamp: Time.current
      )
      if params[:save]
        head :ok
      elsif params[:submit]
        unless record.remark_result
          record.make_remark_result
          record.non_pr_results.reload
        end
        record.remark_result.update(marking_state: Result::MARKING_STATES[:incomplete])
        record.get_original_result.update(released_to_students: false)
        render js: 'location.reload();'
      else
        head :bad_request
      end
    end
  end

  private

  def view_token_param
    if !record.nil?
      params[:view_token] || session['view_token']&.[](record.current_result&.id&.to_s)
    else
      false
    end
  end

  def notebook_to_html(file_contents, unique_path, type)
    return file_contents unless type == 'jupyter-notebook'

    cache_file = Pathname.new('tmp/notebook_html_cache') + "#{unique_path}.html"
    unless File.exist? cache_file
      FileUtils.mkdir_p(cache_file.dirname)
      if type == 'jupyter-notebook'
        args = [
          Rails.application.config.python, '-m', 'nbconvert', '--to', 'html', '--stdin', '--output', cache_file.to_s,
          "--TemplateExporter.extra_template_basedirs=#{Rails.root.join('lib/jupyter-notebook')}",
          '--template', 'markus-html-template'
        ]
      end
      begin
        file_contents = JSON.parse(file_contents)
      rescue JSON::ParserError => e
        return "#{I18n.t('submissions.invalid_jupyter_notebook_content')}: #{e}"
      end
      if file_contents['metadata'].key?('widgets')
        file_contents['metadata'].delete('widgets')
      end
      file_contents = JSON.generate(file_contents)
      _stdout, stderr, status = Open3.capture3(*args, stdin_data: file_contents)
      return "#{I18n.t('submissions.cannot_display')}<br/><br/>#{stderr.lines.last}" unless status.exitstatus.zero?

      # add unique ids to all elements in the DOM
      html = Nokogiri::HTML.parse(File.read(cache_file))
      current_ids = html.xpath('//*[@id]').pluck(:id).to_set # rubocop:disable Rails/PluckId
      html.xpath('//*[not(@id)]').map do |elem|
        unique_id = elem.path
        unique_id += '-next' while current_ids.include? unique_id
        elem.set_attribute(:id, unique_id)
      end
      File.write(cache_file, html.to_html)
    end
    File.read(cache_file)
  end

  def rmd_to_html(file_contents, unique_path)
    cache_file = Pathname.new('tmp/rmd_html_cache').join("#{unique_path}.html")
    unless File.exist? cache_file
      FileUtils.mkdir_p(cache_file.dirname)
      begin
        file_contents.gsub!(/^\s*```{r[^}]*}\s*/m, "```r\n")
        args = [
          'pandoc',
          '-o', Rails.root.join(cache_file).to_s,
          '--to=html',
          '--standalone'
        ]
        _stdout, stderr, status = Open3.capture3(*args, stdin_data: file_contents)
        return "#{I18n.t('submissions.cannot_display')}<br/><br/>#{stderr.lines.last}" unless status.exitstatus.zero?
      rescue StandardError => e
        return "#{I18n.t('submissions.invalid_rmd_content')}: #{e}"
      end
    end
    File.read(cache_file)
  end

  # Return a relative path to a temporary zip file (which may or may not exists).
  # The name of this file is unique by the +assignment+ and current user.
  def zipped_grouping_file_name(assignment)
    # create the zip name with the user name so that we avoid downloading files created by another user
    short_id = assignment.short_identifier
    Pathname.new('tmp') + Pathname.new("#{short_id}_#{current_role.user_name}.zip")
  end

  # Used in update_files and file_manager actions
  def set_filebrowser_vars(grouping)
    grouping.access_repo do |repo|
      @revision = repo.get_latest_revision
      @files = @revision.files_at_path(File.join(grouping.assignment.repository_folder, @path))
    end
  end

  # Generate flash messages to show the status of a group's submitted files.
  # Used in update_files and file_manager actions.
  # Requires @grouping and @assignment variables to be set.
  def flash_file_manager_messages
    if @assignment.is_timed && @grouping.start_time.nil? && @grouping.past_collection_date?
      flash_message(:warning,
                    "#{I18n.t('assignments.timed.past_end_time')} #{I18n.t('submissions.past_collection_time')}")
    elsif @assignment.is_timed && !@grouping.start_time.nil? && !@assignment.grouping_past_due_date?(@grouping)
      flash_message(:notice, I18n.t('assignments.timed.time_until_due_warning', due_date: I18n.l(@grouping.due_date)))
    elsif @grouping.past_collection_date?
      flash_message(:warning,
                    "#{@assignment.submission_rule.class.human_attribute_name(:after_collection_message)} " \
                    "#{I18n.t('submissions.past_collection_time')}")
    elsif @assignment.grouping_past_due_date?(@grouping)
      flash_message(:warning, @assignment.submission_rule.overtime_message(@grouping))
    end

    unless @grouping.is_valid?
      flash_message(:error, t('groups.invalid_group_warning'))
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

    anonymize = current_role.ta? && grouping.assignment.anonymize_groups
    url_submit = grouping.assignment.url_submit

    entries = revision.tree_at_path(full_path).sort do |a, b|
      a[0].count(File::SEPARATOR) <=> b[0].count(File::SEPARATOR) # less nested first
    end
    entries.filter_map do |file_name, file_obj|
      if file_obj.is_a? Repository::RevisionFile
        dirname, basename = File.split(file_name)
        dirname = '' if dirname == '.'
        data = get_file_info(basename, file_obj, grouping.course.id, grouping.assignment.id,
                             revision.revision_identifier, dirname, grouping.id, url_submit: url_submit)
        next if data.nil?
        data[:key] = file_name
        data[:modified] = file_obj.last_modified_date.to_i
        data[:revision_by] = '' if anonymize
        data
      else
        { key: "#{file_name}/" }
      end
    end
  end

  # Include grouping_id param in parent_params so that check_record can ensure that
  # the grouping is in the same course as the current course
  def parent_params
    params[:grouping_id].nil? ? super : [*super, :grouping_id]
  end

  # Returns a boolean on whether the given +url+ is valid.
  # Taken from https://stackoverflow.com/questions/7167895/rails-whats-a-good-way-to-validate-links-urls
  def is_valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  def select_file
    params[:select_file_id] && record.submission_files.find_by(id: params[:select_file_id])
  end

  def from_codeviewer_param
    params[:from_codeviewer] == 'true'
  end
end
