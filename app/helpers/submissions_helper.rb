module SubmissionsHelper
  include RepositoryHelper

  def find_appropriate_grouping(assignment, params)
    if current_role.instructor? || current_role.ta?
      assignment.groupings.find_by(id: params[:grouping_id])
    else
      current_role.accepted_grouping_for(assignment.id)
    end
  end

  def set_pr_release_on_results(peer_review_ids, release)
    Result.transaction do
      results = Result.joins(:peer_reviews).where('peer_reviews.id': peer_review_ids)

      without_complete_result = results.where.not(marking_state: Result::MARKING_STATES[:complete])
      if without_complete_result.present?
        group_names = without_complete_result.joins(:group).pluck(:group_name).join(', ')
        if release
          flash_now(:error, t('submissions.errors.not_complete', group_name: group_names))
        else
          flash_now(:error, t('submissions.errors.not_complete_unrelease', group_name: group_names))
        end
      end

      results.where(marking_state: Result::MARKING_STATES[:complete])
             .update_all(released_to_students: release)
    end
  end

  def get_file_info(file_name, file, course_id, assignment_id, revision_identifier,
                    path, grouping_id, url_submit: false)
    return if Repository.get_class.internal_file_names.include? file_name
    f = {}
    f[:id] = file.object_id
    f[:url] = download_course_assignment_submissions_url(
      course_id: course_id,
      assignment_id: assignment_id,
      revision_identifier: revision_identifier,
      file_name: file_name,
      path: path,
      grouping_id: grouping_id
    )
    f[:raw_name] = file_name
    f[:last_revised_date] = I18n.l(file.last_modified_date)
    f[:last_modified_revision] = revision_identifier
    f[:revision_by] = file.user_id
    f[:submitted_date] = I18n.l(file.submitted_date)
    file_type = FileHelper.get_file_type(file_name)
    f[:type] = file_type == 'markusurl' && !url_submit ? 'unknown' : file_type
    f
  end

  # Helper for the API that uploads a file to this particular +grouping+'s assignment repository.
  # If +only_required_files+ is true, only required files for this grouping's assignment can be uploaded.
  def upload_file(grouping, only_required_files: false)
    if has_missing_params?([:filename, :mime_type, :file_content])
      # incomplete/invalid HTTP params
      render 'shared/http_status', locals: { code: '422', message:
        HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
      return
    end

    path = Pathname.new(grouping.assignment.repository_folder)
    filename = params[:filename]

    if FileHelper.checked_join(path.to_s, filename).nil?
      message = I18n.t('errors.invalid_path')
      render 'shared/http_status', locals: { code: '422', message: message }, status: :unprocessable_content
      return
    end

    # Only allow required files to be uploaded if +only_required_files+ is true
    required_files = grouping.assignment.assignment_files.pluck(:filename)
    if only_required_files && required_files.exclude?(filename)
      message = t('assignments.upload_file_requirement', file_name: params[:filename]) +
        "\n#{Assignment.human_attribute_name(:assignment_files)}: #{required_files.join(', ')}"
      render 'shared/http_status', locals: { code: '422', message: message }, status: :unprocessable_content
      return
    end

    if params[:file_content].respond_to? :read # binary data
      content = params[:file_content].read
    else
      content = params[:file_content]
    end

    tmpfile = Tempfile.new(binmode: true)
    begin
      tmpfile.write(content)
      tmpfile.rewind
      file = ActionDispatch::Http::UploadedFile.new(tempfile: tmpfile,
                                                    filename: params[:filename],
                                                    type: params[:mime_type])
      success, messages = grouping.access_repo do |repo|
        add_file(file, current_role, repo, path: path)
      end
    ensure
      tmpfile.close!
    end
    message_string = messages.map { |type, *msg| "#{type}: #{msg}" }.join("\n")
    if success
      # It worked, render success
      message = "#{HttpStatusHelper::ERROR_CODE['message']['201']}\n\n#{message_string}"
      render 'shared/http_status', locals: { code: '201', message: message }, status: :created
    else
      # Some other error occurred
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{message_string}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: :internal_server_error
    end
  end
end
