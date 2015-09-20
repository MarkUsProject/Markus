module Api
  require 'zip'

  # Allows for downloading of submission files and their annotations
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class SubmissionDownloadsController < MainApiController

    # Returns the requested submission file, or a zip containing all submission
    # files, including all annotations if requested
    # Requires: assignment_id, group_id
    # Optional:
    #  - file_name: Name of the file, if absent all files will be downloaded
    #  - include_annotations: If 'true', will include annotations in the file(s)
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

      submission = Submission.get_submission_by_group_and_assignment(
        group[:group_name], assignment[:short_identifier])
      if submission.nil?
        # No assignment submission by that group
        render 'shared/http_status', locals: {code: '404', message:
          'Submission was not found'}, status: 404
        return
      end

      if params[:filename].present?
        # Find the requested file if filename is set
        files = [SubmissionFile.find_by_filename_and_submission_id(
          params[:filename], submission.id)]
      else
        # Otherwise we get all the files in the submission
        files = SubmissionFile.where(submission_id: submission.id)
      end

      zip_name = "#{assignment[:short_identifier]}_#{group[:group_name]}.zip"

      # If only one file is found, send the file, otherwise loop through and
      # create a zip with all files
      files.each do |file|
        if file.nil?
          # No such file in the submission
          render 'shared/http_status', locals: {code: '422', message:
            'File was not found'}, status: 422
          return
        end

        #Get the file contents
        begin
          if params[:include_annotations] == 'true'
            file_contents = file.retrieve_file(true)
          else
            file_contents = file.retrieve_file
          end
        rescue Exception
            # Could not retrieve file
            render 'shared/http_status', locals: {code: '500', message:
              HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
          return
        end

        if files.length == 1
          # If we only have 1 file being requested, send it
          send_data file_contents, disposition: 'inline', filename: file.filename
        else
          # Otherwise zip up the requested submission files
          Zip::File.open("tmp/#{zip_name}", Zip::File::CREATE) do |zipfile|
            unless zipfile.find_entry(file.path)
              zipfile.mkdir(file.path)
            end
            zipfile.get_output_stream(file.path + '/' + file.filename) { |f|
              f.puts file_contents }
          end
        end
      end

      # Send the zip
      if files.length > 1
        send_file "tmp/#{zip_name}", disposition: 'inline', filename:
          zip_name
      end
    end

  end # end SubmissionDownloadsController
end
