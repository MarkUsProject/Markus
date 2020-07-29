module Api
  # Api controller for starter code groups
  class StarterCodeGroupsController < MainApiController
    def create
      assignment = Assignment.find_by_id(params[:assignment_id])
      if assignment.nil?
        render 'shared/http_status', locals: { code: '404', message: 'Assignment was not found' }, status: 404
        return
      end
      name = I18n.t('assignments.starter_code.new_starter_code_group')
      starter_code_group = StarterCodeGroup.new(assessment_id: assignment.id, name: name)
      if starter_code_group.save
        render 'shared/http_status', locals: { code: '201', message:
            HttpStatusHelper::ERROR_CODE['message']['201'] }, status: 201
      else
        render 'shared/http_status', locals: { code: '500', message:
            starter_code_group.errors.full_messages.first }, status: 500
      end
    end

    def update
      starter_code_group = find_starter_code_group || return
      if starter_code_group.update(params.permit(:name, :entry_rename, :use_rename))
        if starter_code_group.assignment.starter_code_type == 'shuffle' &&
            (starter_code_group.saved_change_to_entry_rename? || starter_code_group.saved_change_to_use_rename?)
          starter_code_group.assignment.groupings.update_all(starter_code_changed: true)
        end
        render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
      else
        render 'shared/http_status', locals: { code: '500', message:
            starter_code_group.errors.full_messages.first }, status: 500
      end
    end

    def destroy
      starter_code_group = find_starter_code_group || return
      if starter_code_group.destroy
        render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
      else
        render 'shared/http_status', locals: { code: '500', message:
            starter_code_group.errors.full_messages.first }, status: 500
      end
    end

    def index
      assignment = Assignment.find_by_id(params[:assignment_id])
      if assignment.nil?
        render 'shared/http_status', locals: { code: '404', message: 'Assignment was not found' }, status: 404
        return
      end
      respond_to do |format|
        format.xml { render xml: assignment.starter_code_groups.to_xml(root: 'starter_code_group', skip_types: 'true') }
        format.json { render json: assignment.starter_code_groups.to_json }
      end
    end

    def show
      starter_code_group = find_starter_code_group || return
      respond_to do |format|
        format.xml { render xml: starter_code_group.to_xml(root: 'starter_code_group', skip_types: 'true') }
        format.json { render json: starter_code_group.to_json }
      end
    end

    def create_file
      starter_code_group = find_starter_code_group || return
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
      file_path = File.join(starter_code_group.path, params[:filename])
      File.write(file_path, content, mode: 'wb')
      update_entries_and_warn(starter_code_group, params[:filename])
      render 'shared/http_status',
             locals: { code: '201', message: HttpStatusHelper::ERROR_CODE['message']['201'] },
             status: 201
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: 500
    end

    def create_folder
      starter_code_group = find_starter_code_group || return
      if has_missing_params?([:folder_path])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end

      folder_path = File.join(starter_code_group.path, params[:folder_path])
      FileUtils.mkdir_p(folder_path)
      update_entries_and_warn(starter_code_group, params[:folder_path])
      render 'shared/http_status',
             locals: { code: '201', message: HttpStatusHelper::ERROR_CODE['message']['201'] },
             status: 201
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: 500
    end

    def remove_file
      starter_code_group = find_starter_code_group || return
      if has_missing_params?([:filename])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end
      file_path = File.join(starter_code_group.path, params[:filename])
      File.delete(file_path)
      update_entries_and_warn(starter_code_group, params[:filename])
      render 'shared/http_status',
             locals: { code: '200', message: HttpStatusHelper::ERROR_CODE['message']['200'] },
             status: 200
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: 500
    end

    def remove_folder
      starter_code_group = find_starter_code_group || return
      if has_missing_params?([:folder_path])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end

      folder_path = File.join(starter_code_group.path, params[:folder_path])
      FileUtils.rm_rf(folder_path)
      update_entries_and_warn(starter_code_group, params[:folder_path])
      render 'shared/http_status',
             locals: { code: '200', message: HttpStatusHelper::ERROR_CODE['message']['200'] },
             status: 200
    rescue StandardError => e
      message = "#{HttpStatusHelper::ERROR_CODE['message']['500']}\n\n#{e.message}"
      render 'shared/http_status', locals: { code: '500', message: message }, status: 500
    end

    def download_entries
      starter_code_group = find_starter_code_group || return
      zip_path = starter_code_group.zip_starter_code_files(current_user)
      send_file zip_path, filename: File.basename(zip_path)
    end

    def entries
      starter_code_group = find_starter_code_group || return
      respond_to do |format|
        paths = starter_code_group.files_and_dirs
        format.xml { render xml: paths.to_xml(root: 'paths', skip_types: 'true') }
        format.json { render json: paths.to_json }
      end
    end

    private

    def update_entries_and_warn(starter_code_group, path)
      Grouping.joins(starter_code_entries: :starter_code_group)
              .where('starter_code_entries.path': path.split(File::Separator).reject(&:blank?).first)
              .where('starter_code_groups.id': starter_code_group)
              .update_all(starter_code_changed: true)
      starter_code_group.assignment.assignment_properties.update!(starter_code_updated_at: Time.zone.now)
      starter_code_group.update_entries
    end

    def find_starter_code_group
      assignment = Assignment.find_by_id(params[:assignment_id])
      starter_code_group = assignment.starter_code_groups.find_by(id: params[:id])
      if starter_code_group.nil?
        render 'shared/http_status', locals: { code: '404', message: 'Starter code group was not found' }, status: 404
        false
      else
        starter_code_group
      end
    end
  end
end
