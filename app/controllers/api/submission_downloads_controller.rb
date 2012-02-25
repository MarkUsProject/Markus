module Api
  require 'zip/zip'

  #=== Description
  # Allows for downloading of submission files and their annotations
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class SubmissionDownloadsController < MainApiController

    #=== Description
    # Triggered by a HTTP GET request to /api/submission_downloads(.:format)
    # Downloads a SubmissionFile, possibly with annotations.
    # Requires the following parameters:
    #   group_name:   Name of the group that submitten the file
    #   assignment:   Assignment for which the file was submitted
    # Allows the following optional paramenters:
    #   filename:     Name of the file, if absent all files will be downloaded
    #   include_annotations:  If 'true', will include annotations in the file(s)
    #=== Returns
    # The requested file, or a zip file containing all requested files
    def show
      if !has_required_http_params?(params)
        # incomplete/invalid HTTP params
        render 'shared/http_status', :locals => { :code => "422", :message => HttpStatusHelper::ERROR_CODE["message"]["422"] }, :status => 422
        return
      end

      # check if there's a valid submission
      submission = Submission.get_submission_by_group_and_assignment(params[:group_name],
                                                                      params[:assignment])

      if submission.nil?
        # no such submission
        render 'shared/http_status', :locals => { :code => "422", :message => "Submission was not found" }, :status => 422
        return
      end

      # If requested a single file
      if !params[:filename].blank?
        files = [SubmissionFile.find_by_filename_and_submission_id(params[:filename], submission.id)]
        single_file = true
      else
      # otherwise we give them the whole directory of files
        files = SubmissionFile.find_all_by_submission_id(submission.id)
        single_file = false
        FileUtils.remove_file("downloads/submissions.zip", true)
      end

      files.each do |file|
        if file.nil?
          # no such submission file
          render 'shared/http_status', :locals => { :code => "422", :message => "Submission was not found" }, :status => 422
          return
        end

        #Get the file contents
        begin
          if params[:include_annotations] == 'true'
            file_contents = file.retrieve_file(true)
          else
            file_contents = file.retrieve_file
          end
        rescue Exception => e
            # could not retrieve file
            render 'shared/http_status', :locals => { :code => "500", :message => HttpStatusHelper::ERROR_CODE["message"]["500"] }, :status => 500
          return
        end

        #Send the file or make the zip file
        if single_file
          send_data file_contents, :disposition => 'inline', :filename => file.filename
        else
          Zip::ZipFile.open("tmp/submissions.zip", Zip::ZipFile::CREATE) do |zipfile|
            if ! zipfile.find_entry(file.path)
              zipfile.mkdir(file.path)
            end
            zipfile.get_output_stream(file.path + "/" + file.filename) { |f| f.puts file_contents }
          end
        end
      end

      #Send the zip file
      if !single_file
        send_file "tmp/submissions.zip", :disposition => 'inline', :filename => "#{params[:assignment]}_#{params[:group_name]}.zip"
      end
    end

    private

    # Helper method to check for required HTTP parameters
    def has_required_http_params?(param_hash)
      # Note: The blank? method is a Rails extension.
      # Specific keys have to be present, and their values
      # must not be blank.
      if !param_hash[:assignment].blank? &&
      !param_hash[:group_name].blank?
        return true
      else
        return false
      end
    end
  end

end
