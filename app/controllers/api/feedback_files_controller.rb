module Api
  # Allows for pushing and downloading of Feedback Files
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class FeedbackFilesController < MainApiController
    # Define default fields for index method
    DEFAULT_FIELDS = [:id, :filename].freeze

    # Returns a list of Feedback Files associated with a group's assignment submission
    # Requires: assignment_id, group_id
    # Optional: filter, fields
    def index
      submission = Submission.get_submission_by_group_id_and_assignment_id(
        params[:group_id], params[:assignment_id]
      )

      collection = submission.feedback_files

      feedback_files = get_collection(collection) || return

      respond_to do |format|
        format.xml do
          render xml: feedback_files.to_xml(only: DEFAULT_FIELDS, root: 'feedback_files', skip_types: 'true')
        end
        format.json { render json: feedback_files.to_json(only: DEFAULT_FIELDS) }
      end
    rescue ActiveRecord::RecordNotFound => e
      # Could not find submission
      render 'shared/http_status', locals: { code: '404', message:
        e }, status: :not_found
    end

    # Sends the contents of the specified Feedback File
    # Requires: id
    def show
      feedback_file = record

      # Everything went fine; send file_content
      send_data feedback_file.file_content,
                type: feedback_file.mime_type,
                filename: feedback_file.filename,
                disposition: 'inline'
    rescue ActiveRecord::RecordNotFound => e
      # Could not find submission or feedback file
      render 'shared/http_status', locals: { code: '404', message:
        e }, status: :not_found
    end

    # Creates a new feedback file for a group's latest assignment submission
    # Requires:
    #  - assignment_id
    #  - group_id
    #  - filename: Name of the file to be uploaded
    #  - mime_type: Mime type of feedback file
    #  - file_content: Contents of the feedback file to be uploaded
    def create
      if has_missing_params?([:filename, :mime_type, :file_content])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
        return
      end

      submission = Submission.get_submission_by_group_id_and_assignment_id(
        params[:group_id], params[:assignment_id]
      )

      # Render error if there's an existing feedback file with that filename
      feedback_file = submission.feedback_files.find_by(filename: params[:filename])
      unless feedback_file.nil?
        render 'shared/http_status', locals: { code: '409', message:
          'A Feedback File with that filename already exists' }, status: :conflict
        return
      end

      # Try creating the Feedback file
      if params[:file_content].respond_to? :read # binary data
        content = params[:file_content].read
      else
        content = params[:file_content]
      end
      if content.size > submission.course.max_file_size
        size_diff = content.size - submission.course.max_file_size
        render 'shared/http_status',
               locals: { code: '413',
                         message: I18n.t('oversize_feedback_file',
                                         file_size: ActiveSupport::NumberHelper.number_to_human_size(size_diff),
                                         max_file_size: submission.course.max_file_size / 1_000_000) },
               status: :content_too_large
        return
      end
      if submission.feedback_files.create(filename: params[:filename],
                                          mime_type: params[:mime_type],
                                          file_content: content)
                   .valid?
        # It worked, render success
        render 'shared/http_status', locals: { code: '201', message:
          HttpStatusHelper::ERROR_CODE['message']['201'] }, status: :created
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
      end
    end

    # Deletes a Feedback File instance
    # Requires: assignment_id, group_id, id
    def destroy
      feedback_file = record

      if feedback_file.destroy
        # Successfully deleted the Feedback file; render success
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
      end
    rescue ActiveRecord::RecordNotFound => e
      # Could not find submission or feedback file
      render 'shared/http_status', locals: { code: '404', message:
        e }, status: :not_found
    end

    # Updates a Feedback File instance
    # Requires: id
    # Optional:
    #  - filename: New name for the file
    #  - file_content: New contents of the feedback file file
    def update
      feedback_file = record

      # Render error if the filename is used by another
      # Feedback File for that submission
      existing_file = feedback_file.submission.feedback_files.find_by(filename: params[:filename])
      if !existing_file.nil? && existing_file.id != params[:id].to_i
        render 'shared/http_status', locals: { code: '409', message:
          'A Feedback File with that filename already exists' }, status: :conflict
        return
      end

      # Update filename if provided
      feedback_file.filename = params[:filename] unless params[:filename].nil?

      if params[:file_content].respond_to? :read # binary data
        content = params[:file_content].read
      else
        content = params[:file_content]
      end

      if feedback_file.save && feedback_file.update_file_content(content)
        # Everything went fine; report success
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
      else
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
      end
    rescue ActiveRecord::RecordNotFound => e
      # Could not find submission or feedback file
      render 'shared/http_status', locals: { code: '404', message:
        e }, status: :not_found
    end
  end
end
