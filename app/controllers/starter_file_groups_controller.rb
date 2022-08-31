# Controller for starter file groups
class StarterFileGroupsController < ApplicationController
  before_action { authorize! }

  respond_to :js

  def create
    assignment = Assignment.find_by(id: params[:assignment_id])
    assignment.starter_file_groups.create(update_params)
  end

  delegate :destroy, to: :record

  def download_file
    starter_file_group = record
    file_path = File.join starter_file_group.path, params[:file_name]
    filename = File.basename params[:file_name]
    if File.exist?(file_path)
      send_file_download file_path, filename: filename
    else
      render plain: t('student.submission.missing_file', file_name: filename)
    end
  end

  def update
    starter_file_group = record
    starter_file_group.update!(update_params)
  rescue ActiveRecord::RecordInvalid => e
    flash_message(:error, e.message)
  end

  def download_files
    starter_file_group = record
    zip_path = starter_file_group.zip_starter_file_files(current_user)
    send_file zip_path, filename: File.basename(zip_path)
  end

  def update_files
    starter_file_group = record
    assignment = starter_file_group.assignment
    unzip = params[:unzip] == 'true'
    new_folders = params[:new_folders] || []
    delete_folders = params[:delete_folders] || []
    delete_files = params[:delete_files] || []
    new_files = params[:new_files] || []

    upload_files_helper(new_folders, new_files, unzip: unzip) do |f|
      if f.is_a?(String) # is a directory
        folder_path = File.join(starter_file_group.path, params[:path].to_s, f)
        FileUtils.mkdir_p(folder_path)
      else
        if f.size > assignment.course.max_file_size
          flash_now(:error, t('student.submission.file_too_large',
                              file_name: f.original_filename,
                              max_size: (assignment.course.max_file_size / 1_000_000.00).round(2)))
          next
        elsif f.size == 0
          flash_now(:warning, t('student.submission.empty_file_warning', file_name: f.original_filename))
        end
        file_path = File.join(starter_file_group.path, params[:path].to_s, f.original_filename)
        file_content = f.read
        File.write(file_path, file_content, mode: 'wb')
      end
    end

    delete_folders.each do |f|
      folder_path = File.join(starter_file_group.path, f)
      FileUtils.rm_rf(folder_path)
    end
    delete_files.each do |f|
      file_path = File.join(starter_file_group.path, f)
      File.delete(file_path)
    end
    if params[:path].blank?
      all_paths = [new_folders, new_files.map(&:original_filename), delete_files, delete_folders].flatten
    else
      all_paths = [params[:path]]
    end
    assignment.assignment_properties.update!(starter_file_updated_at: Time.current) unless all_paths.empty?
    starter_file_group.update_entries
  end

  private

  def update_params
    params.permit(:name)
  end
end
