module Api
  # Api controller for starter file groups
  class StarterFileGroupsController < MainApiController
    def create
      assignment = Assignment.find_by_id(params[:assignment_id])
      if assignment.nil?
        render 'shared/http_status', locals: { code: '404', message: 'Assignment was not found' }, status: 404
        return
      end
      name = params[:name] || I18n.t('assignments.starter_file.new_starter_file_group')
      other_params = params.permit(:entry_rename, :use_rename).to_h.symbolize_keys
      starter_file_group = StarterFileGroup.new(assessment_id: assignment.id, name: name, **other_params)
      if starter_file_group.save
        render 'shared/http_status', locals: { code: '201', message:
            HttpStatusHelper::ERROR_CODE['message']['201'] }, status: 201
      else
        render 'shared/http_status', locals: { code: '500', message:
            starter_file_group.errors.full_messages.first }, status: 500
      end
    end

    def update
      starter_file_group = find_starter_file_group || return
      if starter_file_group.update(params.permit(:name, :entry_rename, :use_rename))
        if starter_file_group.assignment.starter_file_type == 'shuffle' &&
            (starter_file_group.saved_change_to_entry_rename? || starter_file_group.saved_change_to_use_rename?)
          starter_file_group.assignment.groupings.update_all(starter_file_changed: true)
        end
        render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
      else
        render 'shared/http_status', locals: { code: '500', message:
            starter_file_group.errors.full_messages.first }, status: 500
      end
    end

    def destroy
      starter_file_group = find_starter_file_group || return
      if starter_file_group.destroy
        render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
      else
        render 'shared/http_status', locals: { code: '500', message:
            starter_file_group.errors.full_messages.first }, status: 500
      end
    end

    def index
      assignment = Assignment.find_by_id(params[:assignment_id])
      if assignment.nil?
        render 'shared/http_status', locals: { code: '404', message: 'Assignment was not found' }, status: 404
        return
      end
      respond_to do |format|
        format.xml { render xml: assignment.starter_file_groups.to_xml(skip_types: 'true') }
        format.json { render json: assignment.starter_file_groups.to_json }
      end
    end

    def show
      starter_file_group = find_starter_file_group || return
      respond_to do |format|
        format.xml { render xml: starter_file_group.to_xml(skip_types: 'true') }
        format.json { render json: starter_file_group.to_json }
      end
    end

    def create_file
      starter_file_group = find_starter_file_group || return
      if has_missing_params?([:filename, :file_content])
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
      file_path = File.join(starter_file_group.path, params[:filename])
      File.write(file_path, content, mode: 'wb')
      update_entries_and_warn(starter_file_group)
      render 'shared/http_status',
             locals: { code: '201', message: HttpStatusHelper::ERROR_CODE['message']['201'] },
             status: 201
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: 500
    end

    def create_folder
      starter_file_group = find_starter_file_group || return
      if has_missing_params?([:folder_path])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end

      folder_path = File.join(starter_file_group.path, params[:folder_path])
      FileUtils.mkdir_p(folder_path)
      update_entries_and_warn(starter_file_group)
      render 'shared/http_status',
             locals: { code: '201', message: HttpStatusHelper::ERROR_CODE['message']['201'] },
             status: 201
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: 500
    end

    def remove_file
      starter_file_group = find_starter_file_group || return
      if has_missing_params?([:filename])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end
      file_path = File.join(starter_file_group.path, params[:filename])
      File.delete(file_path)
      update_entries_and_warn(starter_file_group)
      render 'shared/http_status',
             locals: { code: '200', message: HttpStatusHelper::ERROR_CODE['message']['200'] },
             status: 200
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: 500
    end

    def remove_folder
      starter_file_group = find_starter_file_group || return
      if has_missing_params?([:folder_path])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end

      folder_path = File.join(starter_file_group.path, params[:folder_path])
      FileUtils.rm_rf(folder_path)
      update_entries_and_warn(starter_file_group)
      render 'shared/http_status',
             locals: { code: '200', message: HttpStatusHelper::ERROR_CODE['message']['200'] },
             status: 200
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: 500
    end

    def download_entries
      starter_file_group = find_starter_file_group || return
      zip_path = starter_file_group.zip_starter_file_files(current_user)
      send_file zip_path, filename: File.basename(zip_path)
    end

    def entries
      starter_file_group = find_starter_file_group || return
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
      starter_file_group.warn_affected_groupings
      starter_file_group.assignment.assignment_properties.update!(starter_file_updated_at: Time.zone.now)
      starter_file_group.update_entries
    end

    def find_starter_file_group
      assignment = Assignment.find_by_id(params[:assignment_id])
      starter_file_group = assignment.starter_file_groups.find_by(id: params[:id])
      if starter_file_group.nil?
        render 'shared/http_status', locals: { code: '404', message: 'Starter file group was not found' }, status: 404
        false
      else
        starter_file_group
      end
    end
  end
end
