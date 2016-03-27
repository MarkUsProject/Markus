module Api

  # Allows for pushing and downloading of Feedback Files
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class FeedbackFilesController < MainApiController
    # Define default fields for index method
    @@default_fields = [:id, :filename]

    # Returns a list of Feedback Files associated with a group's assignment submission
    # Requires: assignment_id, group_id
    # Optional: filter, fields
    def index
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      collection = submission.feedback_files

      feedback_files = get_collection(FeedbackFile, collection)
      fields = fields_to_render(@@default_fields)

      respond_to do |format|
        format.xml{render xml: feedback_files.to_xml(only: fields, root:
          'feedback_files', skip_types: 'true')}
        format.json{render json: feedback_files.to_json(only: fields)}
      end
    end

    # Sends the contents of the specified Feedback File
    # Requires: assignment_id, group_id, id
    def show
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      feedback_file = submission.feedback_files.find_by_id(params[:id])

      # Render error if the Feedback file does not exist
      if feedback_file.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Feedback file was not found'}, status: 404
        return
      end

      # Everything went fine; send file_content
      send_data feedback_file.file_content, disposition: 'inline',
                                          filename: feedback_file.filename
    end

    # Creates a new feedback file for a group's latest assignment submission
    # Requires:
    #  - assignment_id
    #  - group_id
    #  - filename: Name of the file to be uploaded
    #  - file_content: Contents of the feedback file to be uploaded
    def create
      if has_missing_params?([:filename, :file_content])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: {code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422']}, status: 422
        return
      end

      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      # Render error if there's an existing feedback file with that filename
      feedback_file = submission.feedback_files.find_by_filename(params[:filename])
      unless feedback_file.nil?
        render 'shared/http_status', locals: {code: '409', message:
          'A Feedback File with that filename already exists'}, status: 409
        return
      end

      # Try creating the Feedback file
      if submission.feedback_files.create(filename: params[:filename],
         file_content: params[:file_content])
        # It worked, render success
        render 'shared/http_status', locals: {code: '201', message:
          HttpStatusHelper::ERROR_CODE['message']['201']}, status: 201
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
    end

    # Deletes a Feedback File instance
    # Requires: assignment_id, group_id, id
    def destroy
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      feedback_file = submission.feedback_files.find_by_id(params[:id])

      # Render error if the Feedback File does not exist
      if feedback_file.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Feedback file was not found'}, status: 404
        return
      end

      if feedback_file.destroy
        # Successfully deleted the Feedback file; render success
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200']}, status: 200
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
    end

    # Updates a Feedback File instance
    # Requires: assignment_id, group_id, id
    # Optional:
    #  - filename: New name for the file
    #  - file_content: New contents of the feedback file file
    def update
      # get_submission renders appropriate error if the submission isn't found
      submission = get_submission(params[:assignment_id], params[:group_id])
      return if submission.nil?

      feedback_file = submission.feedback_files.find_by_id(params[:id])

      # Render error if the Feedback file does not exist
      if feedback_file.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Feedback file was not found'}, status: 404
        return
      end

      # Render error if the filename is used by another
      # Feedback File for that submission
      existing_file = submission.feedback_files.find_by_filename(params[:filename])
      if !existing_file.nil? && existing_file.id != params[:id].to_i
        render 'shared/http_status', locals: {code: '409', message:
          'A Feedback File with that filename already exists'}, status: 409
        return
      end

      # Update filename if provided
      feedback_file.filename = params[:filename] if !params[:filename].nil?

      if feedback_file.save && feedback_file.update_file_content(params[:file_content])
        # Everything went fine; report success
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200']}, status: 200
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
      end
    end

    # Given assignment and group id's, returns the submission if found, or nil
    # otherwise. Also renders appropriate responses on error.
    def get_submission(assignment_id, group_id)
      assignment = Assignment.find_by_id(assignment_id)
      if assignment.nil?
        # No assignment with that id
        render 'shared/http_status', locals: {code: '404', message:
          'No assignment exists with that id'}, status: 404
        return nil
      end

      group = Group.find_by_id(group_id)
      if group.nil?
        # No group exists with that id
        render 'shared/http_status', locals: {code: '404', message:
          'No group exists with that id'}, status: 404
        return nil
      end

      submission = Submission.get_submission_by_group_and_assignment(
        group[:group_name], assignment[:short_identifier])
      if submission.nil?
        # No assignment submission by that group
        render 'shared/http_status', locals: {code: '404', message:
          'Submission was not found'}, status: 404
      end

      submission
    end

  end # end FeedbackFilesController
end
