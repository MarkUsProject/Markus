class StarterCodeGroupsController < ApplicationController

  respond_to :js

  # TODO: authorize! for all routes

  def create
    starter_code_group = StarterCodeGroup.new(create_params)
    if starter_code_group.save
      assignment = Assignment.find(params[:assessment_id])
      assignment.assignment_properties.update!(starter_code_updated_at: Time.zone.now)
    end
  end

  def destroy
    assignment = Assignment.find_by(id: params[:assignment_id])
    starter_code_group = assignment&.starter_code_groups&.find_by(id: params[:id])
    if starter_code_group.nil?
      # TODO flash error message
    else
      # TODO: add an authorize! check here
      affected_groupings = Grouping.joins(starter_code_entries: :starter_code_group)
                                   .where('starter_code_groups.id': starter_code_group.id)
      if starter_code_group.destroy
        affected_groupings.update_all(starter_code_changed: true)
      end
    end
  end

  def download_file
    assignment = Assignment.find_by(id: params[:assignment_id])
    starter_code_group = assignment&.starter_code_groups&.find_by(id: params[:id])
    if starter_code_group.nil?
      # TODO flash error message
    else
      # TODO: add an authorize! check here
      file_path = File.join starter_code_group.path, params[:file_name]
      filename = File.basename params[:file_name]
      if File.exist?(file_path)
        send_file_download file_path, filename: filename
      else
        render plain: t('student.submission.missing_file', file_name: filename)
      end
    end
  end

  def update
    assignment = Assignment.find_by(id: params[:assignment_id])
    starter_code_group = assignment.starter_code_groups.find_by(id: params[:id])
    starter_code_group.update!(update_params) # TODO: flash error message
  end

  def download_files
    assignment = Assignment.find(params[:assignment_id])
    starter_code_group = assignment.starter_code_groups.find_by(id: params[:id])
    zip_path = starter_code_group.zip_starter_code_files(current_user)
    send_file zip_path, filename: File.basename(zip_path)
  end

  def update_files
    assignment = Assignment.find(params[:assignment_id])
    starter_code_group = assignment&.starter_code_groups&.find_by(id: params[:id])
    unzip = params[:unzip] == 'true'
    if starter_code_group.nil?
      # TODO flash error message
    else
      new_folders = params[:new_folders] || []
      delete_folders = params[:delete_folders] || []
      delete_files = params[:delete_files] || []
      new_files = params[:new_files] || []

      if unzip
        zdirs, zfiles = new_files.map do |f|
          next unless File.extname(f.path).casecmp?('.zip')
          unzip_uploaded_file(f.path)
        end.compact.transpose.map(&:flatten)
        new_files.reject! { |f| File.extname(f.path).casecmp?('.zip') }
        new_folders.push(*zdirs)
        new_files.push(*zfiles)
      end

      new_folders.each do |f|
        folder_path = File.join(starter_code_group.path, f)
        FileUtils.mkdir_p(folder_path)
      end
      delete_folders.each do |f|
        folder_path = File.join(starter_code_group.path, f)
        FileUtils.rm_rf(folder_path)
      end
      new_files.each do |f|
        if f.size > Rails.configuration.max_file_size
          flash_now(:error, t('student.submission.file_too_large',
                              file_name: f.original_filename,
                              max_size: (Rails.configuration.max_file_size / 1_000_000.00).round(2)))
          next
        elsif f.size == 0
          flash_now(:warning, t('student.submission.empty_file_warning', file_name: f.original_filename))
        end
        file_path = File.join(starter_code_group.path, params[:path], f.original_filename)
        file_content = f.read
        File.write(file_path, file_content, mode: 'wb')
      end
      delete_files.each do |f|
        file_path = File.join(starter_code_group.path, f)
        File.delete(file_path)
      end
      if params[:path].blank?
        all_paths = [new_folders,
                     new_files.map(&:original_filename),
                     delete_files,
                     delete_folders.map(&:original_filename)].flatten
      else
        all_paths = [params[:path]]
      end
      clean_paths = all_paths.map { |p| p.split(File::Separator).first }
      # mark all groupings with starter code that was changed as changed
      Grouping.joins(starter_code_entries: :starter_code_group)
              .where('starter_code_entries.path': clean_paths)
              .where('starter_code_groups.id': starter_code_group)
              .update_all(starter_code_changed: true)
      assignment.assignment_properties.update!(starter_code_updated_at: Time.zone.now) unless all_paths.empty?
      starter_code_group.update_entries
    end
  end

  private

  def create_params
    group_params = params.permit(:name, :assessment_id, :is_default, :entry_rename, :use_rename)
    %w[is_default use_rename].each do |bool_attr|
      group_params[bool_attr] = group_params[bool_attr] == 'true' if group_params.key?(bool_attr)
    end
    group_params
  end
  def update_params
    params.permit(:name)
  end
end
