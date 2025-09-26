module Api
  # Allows for downloading of submission files and their annotations
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class SubmissionFilesController < MainApiController
    include SubmissionsHelper
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
              HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
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
        FileUtils.rm_f(zip_path)

        Zip::File.open(zip_path, create: true) do |zip_file|
          grouping.access_repo do |repo|
            if params[:collected].present?
              revision_id = submission.revision_identifier
              revision = repo.get_revision(revision_id)
            else
              revision = repo.get_latest_revision
            end
            repo.send_tree_to_zip(assignment.repository_folder, zip_file, revision)
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
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
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
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
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
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
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

    protected

    def implicit_authorization_target
      SubmissionFile
    end
  end
end
