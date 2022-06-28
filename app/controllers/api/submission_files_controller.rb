module Api
  # Allows for downloading of submission files and their annotations
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class SubmissionFilesController < MainApiController
    include RepositoryHelper
    # Returns the requested submission file, or a zip containing all submission
    # files, including all annotations if requested
    # Requires: assignment_id, group_id
    # Optional:
    #  - collected: If present, the collected revision will be sent, otherwise the
    #               latest revision will be sent instead
    #  - file_name: Name of the file, if absent all files will be downloaded
    def index
      assignment = Assignment.find_by(id: params[:assignment_id])
      group = Group.find_by(id: params[:group_id])
      grouping = group&.grouping_for_assignment(assignment.id)
      if group.nil? || grouping.nil?
        # No group exists with that id
        render 'shared/http_status', locals: { code: '404', message:
          'No group exists with that id' }, status: :not_found
        return
      end

      if params[:collected].present?
        submission = grouping&.current_submission_used
        return page_not_found('Submission was not found') if submission.nil?
      end

      if params[:filename].present?
        path = File.dirname(params[:filename])
        file_name = File.basename(params[:filename])
        path = '/' if path == '.'
        grouping.access_repo do |repo|
          if params[:collected].present?
            revision_id = submission.revision_identifier
            revision = repo.get_revision(revision_id)
          else
            revision = repo.get_latest_revision
          end
          file = revision.files_at_path(File.join(assignment.repository_folder, path))[file_name]
          if file.nil?
            render 'shared/http_status', locals: { code: '422', message:
              HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_entity
            return
          end
          file_contents = repo.download_as_string(file)
          send_data file_contents,
                    disposition: 'inline',
                    filename: file_name
        end
      else
        ## create the zip name with the user name to have less chance to delete
        ## a currently downloading file
        version = params[:collected].present? ? 'collected' : 'latest'
        zip_name = "#{assignment.short_identifier}_#{group.group_name}_#{current_user.user_name}_#{version}.zip"
        zip_path = Pathname.new('tmp') + zip_name

        ## delete the old file if it exists
        File.delete(zip_path) if File.exist?(zip_path)

        Zip::File.open(zip_path, create: true) do |zip_file|
          grouping.access_repo do |repo|
            if params[:collected].present?
              revision_id = submission.revision_identifier
              revision = repo.get_revision(revision_id)
            else
              revision = repo.get_latest_revision
            end
            repo.send_tree_to_zip(assignment.repository_folder, zip_file, zip_name, revision)
          end
        end

        send_file zip_path, disposition: 'inline', filename: zip_name.to_s
      end
    end

    def create
      grouping = Grouping.find_by(group_id: params[:group_id], assessment_id: params[:assignment_id])
      return page_not_found('No group with that id exists for the given assignment') if grouping.nil?

      upload_file(grouping)
    end

    def create_folders
      grouping = Grouping.find_by(group_id: params[:group_id], assessment_id: params[:assignment_id])
      return page_not_found('No group with that id exists for the given assignment') if grouping.nil?

      if has_missing_params?([:folder_path])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_entity
        return
      end
      success, messages = grouping.access_repo do |repo|
        new_folder = Pathname.new(params[:folder_path])
        path = Pathname.new(grouping.assignment.repository_folder)
        add_folder(new_folder, current_role, repo, path: path)
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

    def remove_file
      grouping = Grouping.find_by(group_id: params[:group_id], assessment_id: params[:assignment_id])
      return page_not_found('No group with that id exists for the given assignment') if grouping.nil?

      if has_missing_params?([:filename])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_entity
        return
      end

      success, messages = grouping.access_repo do |repo|
        path = Pathname.new(grouping.assignment.repository_folder)
        remove_files([params[:filename]], current_role, repo, path: path)
      end

      message_string = messages.map { |type, *msg| "#{type}: #{msg}" }.join("\n")
      if success
        # It worked, render success
        message = "#{HttpStatusHelper::ERROR_CODE['message']['200']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '200', message: message }, status: :ok
      else
        # Some other error occurred
        message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '500', message: message }, status: :internal_server_error
      end
    end

    def remove_folder
      grouping = Grouping.find_by(group_id: params[:group_id], assessment_id: params[:assignment_id])
      return page_not_found('No group with that id exists for the given assignment') if grouping.nil?

      if has_missing_params?([:folder_path])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_entity
        return
      end
      success, messages = grouping.access_repo do |repo|
        folder = params[:folder_path]
        path = Pathname.new(grouping.assignment.repository_folder)
        remove_folders([folder], current_role, repo, path: path)
      end
      message_string = messages.map { |type, *msg| "#{type}: #{msg}" }.join("\n")
      if success
        # It worked, render success
        message = "#{HttpStatusHelper::ERROR_CODE['message']['200']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '200', message: message }, status: :ok
      else
        # Some other error occurred
        message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '500', message: message }, status: :internal_server_error
      end
    end

    def submit_file
      student = Student.find_by(user: @real_user, course: @current_course)
      assignment = Assignment.find_by(id: params[:assignment_id], course: @current_course)

      # Disable submission via API if the instructor desires to
      unless assignment.api_submit
        render 'shared/http_status', locals: { code: '403', message:
          'The instructor has disabled submission via the API' }, status: :forbidden
        return
      end

      # Reject submission if the student has pending grouping
      if student.has_pending_groupings_for?(assignment.id)
        render 'shared/http_status', locals: { code: '422', message:
          'You must respond to your group request on MarkUs before you can submit' }, status: :unprocessable_entity
        return
      end

      grouping = if student.has_accepted_grouping_for?(assignment.id)
                   student.accepted_grouping_for(assignment.id)
                 elsif assignment.group_max == 1
                   student.create_group_for_working_alone_student(assignment.id)
                   student.accepted_grouping_for(assignment.id)
                 else
                   student.create_autogenerated_name_group(assignment)
                 end

      upload_file(grouping, only_required_files: assignment.only_required_files)
    end

    protected

    def implicit_authorization_target
      SubmissionFile
    end

    private

    # Helper that uploads a file to this particular +grouping+'s assignment repository.
    # If +only_required_files+ is true, only required files for this grouping's assignment can be uploaded.
    def upload_file(grouping, only_required_files: false)
      if has_missing_params?([:filename, :mime_type, :file_content])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_entity
        return
      end

      # Only allow required files to be uploaded if +only_required_files+ is true
      if only_required_files && grouping.assignment.assignment_files.pluck(:filename).exclude?(params[:filename])
        render 'shared/http_status', locals: { code: '403', message:
          'Only required files can be uploaded' }, status: :forbidden
        return
      end

      if params[:file_content].respond_to? :read # binary data
        content = params[:file_content].read
      else
        content = params[:file_content]
      end

      tmpfile = Tempfile.new
      begin
        tmpfile.write(content)
        tmpfile.rewind
        file = ActionDispatch::Http::UploadedFile.new(tempfile: tmpfile,
                                                      filename: params[:filename],
                                                      type: params[:mime_type])
        success, messages = grouping.access_repo do |repo|
          path = Pathname.new(grouping.assignment.repository_folder)
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
end
