module Api
  # Api controller for starter file groups
  class StarterFileGroupsController < MainApiController
    def create
      assignment = Assignment.find_by(id: params[:assignment_id])
      other_params = params.permit(:entry_rename, :use_rename, :name).to_h.symbolize_keys
      starter_file_group = StarterFileGroup.new(assessment_id: assignment.id, **other_params)
      if starter_file_group.save
        render 'shared/http_status', locals: { code: '201', message:
            HttpStatusHelper::ERROR_CODE['message']['201'] }, status: :created
      else
        render 'shared/http_status', locals: { code: '500', message:
            starter_file_group.errors.full_messages.first }, status: :internal_server_error
      end
    end

    def update
      starter_file_group = record
      if starter_file_group.update(params.permit(:name, :entry_rename, :use_rename))
        if starter_file_group.assignment.starter_file_type == 'shuffle' &&
            (starter_file_group.saved_change_to_entry_rename? || starter_file_group.saved_change_to_use_rename?)
          starter_file_group.assignment.groupings.update_all(starter_file_changed: true)
        end
        render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
      else
        render 'shared/http_status', locals: { code: '500', message:
            starter_file_group.errors.full_messages.first }, status: :internal_server_error
      end
    end

    def destroy
      starter_file_group = record
      if starter_file_group.destroy
        render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
      else
        render 'shared/http_status', locals: { code: '500', message:
            starter_file_group.errors.full_messages.first }, status: :internal_server_error
      end
    end

    def index
      assignment = Assignment.find_by(id: params[:assignment_id])
      respond_to do |format|
        format.xml { render xml: assignment.starter_file_groups.to_xml(skip_types: 'true') }
        format.json { render json: assignment.starter_file_groups.to_json }
      end
    end

    def show
      starter_file_group = record
      respond_to do |format|
        format.xml { render xml: starter_file_group.to_xml(skip_types: 'true') }
        format.json { render json: starter_file_group.to_json }
      end
    end

    def create_file
      starter_file_group = record
      if has_missing_params?([:filename, :file_content])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
        return
      end

      if params[:file_content].respond_to? :read # binary data
        content = params[:file_content].read
      else
        content = params[:file_content]
      end
      file_path = FileHelper.checked_join(starter_file_group.path, params[:filename])
      if file_path.nil?
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
      else
        File.write(file_path, content, mode: 'wb')
        update_entries_and_warn(starter_file_group)
        render 'shared/http_status',
               locals: { code: '201', message: HttpStatusHelper::ERROR_CODE['message']['201'] },
               status: :created
      end
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: :internal_server_error
    end

    def create_folder
      starter_file_group = record
      if has_missing_params?([:folder_path])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
        return
      end

      folder_path = FileHelper.checked_join(starter_file_group.path, params[:folder_path])
      if folder_path.nil?
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
      else
        FileUtils.mkdir_p(folder_path)
        update_entries_and_warn(starter_file_group)
        render 'shared/http_status',
               locals: { code: '201', message: HttpStatusHelper::ERROR_CODE['message']['201'] },
               status: :created
      end
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: :internal_server_error
    end

    def remove_file
      starter_file_group = record
      if has_missing_params?([:filename])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
        return
      end
      file_path = FileHelper.checked_join(starter_file_group.path, params[:filename])
      if file_path.nil?
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
      else
        File.delete(file_path)
        update_entries_and_warn(starter_file_group)
        render 'shared/http_status',
               locals: { code: '200', message: HttpStatusHelper::ERROR_CODE['message']['200'] },
               status: :ok
      end
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: :internal_server_error
    end

    def remove_folder
      starter_file_group = record
      if has_missing_params?([:folder_path])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
        return
      end

      folder_path = FileHelper.checked_join(starter_file_group.path, params[:folder_path])
      if folder_path.nil?
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
      else
        FileUtils.rm_rf(folder_path)
        update_entries_and_warn(starter_file_group)
        render 'shared/http_status',
               locals: { code: '200', message: HttpStatusHelper::ERROR_CODE['message']['200'] },
               status: :ok
      end
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: :internal_server_error
    end

    def download_entries
      starter_file_group = record
      zip_path = starter_file_group.zip_starter_file_files(current_role)
      send_file zip_path, filename: File.basename(zip_path)
    end

    def entries
      starter_file_group = record
      respond_to do |format|
        paths = starter_file_group.files_and_dirs
        format.xml { render xml: paths.to_xml(root: 'paths', skip_types: 'true') }
        format.json { render json: paths.to_json }
      end
    end

    private

    # Update starter file entries for +starter_file_group+ and set the starter_file_changed
    # attribute to true for all groupings affected by the change.
    def update_entries_and_warn(starter_file_group)
      starter_file_group.assignment.assignment_properties.update!(starter_file_updated_at: Time.current)
      starter_file_group.update_entries
    end
  end
end
