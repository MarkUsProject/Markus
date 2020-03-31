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
      assignment = Assignment.find_by_id(params[:assignment_id])
      if assignment.nil?
        # No assignment with that id
        render 'shared/http_status', locals: {code: '404', message:
          'No assignment exists with that id'}, status: 404
        return
      end

      group = Group.find_by_id(params[:group_id])
      if group.nil?
        # No group exists with that id
        render 'shared/http_status', locals: {code: '404', message:
          'No group exists with that id'}, status: 404
        return
      end

      if params[:collected].present?
        submission = group.grouping_for_assignment(assignment.id)&.current_submission_used
        if submission.nil?
          # No assignment submission by that group
          render 'shared/http_status', locals: { code: '404', message:
            'Submission was not found' }, status: 404
          return
        end
      end

      if params[:filename].present?
        path = File.dirname(params[:filename])
        file_name = File.basename(params[:filename])
        path = path == '.' ? '/' : path
        group.access_repo do |repo|
          if params[:collected].present?
            revision_id = submission.revision_identifier
            revision = repo.get_revision(revision_id)
          else
            revision = repo.get_latest_revision
          end
          file = revision.files_at_path(File.join(assignment.repository_folder, path))[file_name]
          if file.nil?
            render 'shared/http_status', locals: { code: '422', message:
              HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
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
        short_id = assignment.short_identifier
        zip_name = Pathname.new(short_id + '_' + current_user.user_name + '.zip')
        zip_path = Pathname.new('tmp') + zip_name

        ## delete the old file if it exists
        File.delete(zip_path) if File.exist?(zip_path)

        Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
          group.access_repo do |repo|
            if params[:collected].present?
              revision_id = submission.revision_identifier
              revision = repo.get_revision(revision_id)
            else
              revision = repo.get_latest_revision
            end
            repo.send_tree_to_zip(assignment.repository_folder, zip_file, zip_name + group.group_name, revision)
          end
        end

        send_file zip_path, disposition: 'inline', filename: zip_name.to_s
      end
    end

    def create
      grouping = Grouping.find_by(group_id: params[:group_id], assessment_id: params[:assignment_id])
      if grouping.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'No group with that id exists for the given assignment' }, status: 404
        return
      end

      if has_missing_params?([:filename, :mime_type, :file_content])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
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
        success, messages = grouping.group.access_repo do |repo|
          path = Pathname.new(grouping.assignment.repository_folder)
          add_files([file], @current_user, repo, path: path)
        end
      ensure
        tmpfile.close!
      end
      message_string = messages.map { |type, *msg| "#{type}: #{msg}" }.join("\n")
      if success
        # It worked, render success
        message = "#{HttpStatusHelper::ERROR_CODE['message']['201']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '201', message: message }, status: 201
      else
        # Some other error occurred
        message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '500', message: message }, status: 500
      end
    end

    def create_folders
      grouping = Grouping.find_by(group_id: params[:group_id], assessment_id: params[:assignment_id])
      if grouping.nil?
        render 'shared/http_status', locals: { code: '404', message:
            'No group with that id exists for the given assignment' }, status: 404
        return
      end

      if has_missing_params?([:folder_path])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end
      success, messages = grouping.group.access_repo do |repo|
        new_folders = Pathname.new(params[:folder_path])
        path = Pathname.new(grouping.assignment.repository_folder)
        add_folders([new_folders], @current_user, repo, path: path)
      end
      message_string = messages.map { |type, *msg| "#{type}: #{msg}" }.join("\n")
      if success
        # It worked, render success
        message = "#{HttpStatusHelper::ERROR_CODE['message']['201']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '201', message: message }, status: 201
      else
        # Some other error occurred
        message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '500', message: message }, status: 500
      end
    end

    def remove_file
      grouping = Grouping.find_by(group_id: params[:group_id], assessment_id: params[:assignment_id])
      if grouping.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'No group with that id exists for the given assignment' }, status: 404
        return
      end

      if has_missing_params?([:filename])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end

      success, messages = grouping.group.access_repo do |repo|
        path = Pathname.new(grouping.assignment.repository_folder)
        remove_files([params[:filename]], @current_user, repo, path: path)
      end

      message_string = messages.map { |type, *msg| "#{type}: #{msg}" }.join("\n")
      if success
        # It worked, render success
        message = "#{HttpStatusHelper::ERROR_CODE['message']['200']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '200', message: message }, status: 200
      else
        # Some other error occurred
        message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '500', message: message }, status: 500
      end
    end

    def remove_folder
      grouping = Grouping.find_by(group_id: params[:group_id], assessment_id: params[:assignment_id])
      if grouping.nil?
        render 'shared/http_status', locals: { code: '404', message:
            'No group with that id exists for the given assignment' }, status: 404
        return
      end

      if has_missing_params?([:folder_path])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end
      success, messages = grouping.group.access_repo do |repo|
        folder = params[:folder_path]
        path = Pathname.new(grouping.assignment.repository_folder)
        remove_folders([folder], @current_user, repo, path: path)
      end
      message_string = messages.map { |type, *msg| "#{type}: #{msg}" }.join("\n")
      if success
        # It worked, render success
        message = "#{HttpStatusHelper::ERROR_CODE['message']['200']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '200', message: message }, status: 200
      else
        # Some other error occurred
        message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{message_string}"
        render 'shared/http_status', locals: { code: '500', message: message }, status: 500
      end
    end
  end
end
