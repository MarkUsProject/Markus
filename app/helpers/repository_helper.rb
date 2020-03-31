module RepositoryHelper
  include SubmissionsHelper

  # Add new files or overwrite existing files in this open +repo+. +files+ should be a list
  # of ActionDispatch::Http::UploadedFile objects, +user+ is the user that is responsible for
  # the repository transaction, +path+ is the relative path from the root of the repository
  # to prepend to each filename.
  #
  # If files should be added as part of an existent transaction, the transaction object can be
  # passed as the +txn+ keyword argument, otherwise a new transaction will be created. If the +txn+
  # argument is not nil, the transaction will be commited before returning, otherwise the transaction
  # object will not be commited and so should be commited later on by the caller.
  #
  # Returns a tuple containing a boolean and an array. If the +txn+ argument was nil, the boolean
  # indicates whether the transaction was completed without errors. If the +txn+ argument was not
  # nil, the boolean indicates whether any errors were encountered which mean the caller should not
  # commit the transaction. The array contains any error or warning messages as arrays of arguments.
  #
  # If +check_size+ is true then check if the file size is greater than Rails.configuration.max_file_size
  # or less than 0 bytes. If +required_files+ is an array of file names, and some of the uploaded files are not
  # in that array, a messages will be returned indicating that non-required files were uploaded.
  def add_files(files, user, repo, path: '/', txn: nil, check_size: true, required_files: nil)
    messages = []

    if txn.nil?
      txn = repo.get_transaction(user.user_name)
      commit_txn = true
    else
      commit_txn = false
    end

    revision = repo.get_latest_revision
    current_path = Pathname.new path
    new_files = []
    files.each do |f|
      if check_size
        if f.size > Rails.configuration.max_file_size
          messages << [:too_large, f.original_filename]
        elsif f.size == 0
          messages << [:too_small, f.original_filename]
        end
      end
      filename = f.original_filename
      if filename.nil?
        messages << [:invalid_filename, f.original_filename]
        return false, messages
      end
      subdir_path, filename = File.split(filename)
      filename = sanitize_file_name(filename)
      file_path = current_path.join(subdir_path).join(filename)
      file_path_relative = file_path.relative_path_from(current_path).to_s
      file_path = file_path.to_s
      # Sometimes the file pointer of file_object is at the end of the file.
      # In order to avoid empty uploaded files, rewind it to be safe.
      f.rewind
      # Branch on whether the file is new or a replacement
      if revision.path_exists?(file_path)
        txn.replace(file_path, f.read, f.content_type, revision.revision_identifier)
      else
        new_files << file_path_relative
        txn.add(file_path, f.read, f.content_type)
      end
    end
    # check if only required files are allowed for a submission
    # required_files = assignment.assignment_files.pluck(:filename)
    if required_files.present? && (new_files - required_files).present?
      messages << [:extra_files, new_files - required_files]
      return false, messages
    end

    if commit_txn
      success, txn_messages = commit_transaction repo, txn
      [success, messages + txn_messages]
    else
      [true, messages]
    end
  end

  # Delete files in this open +repo+. +files+ should be an list of filenames to remove.
  # +user+ is the user that is responsible for the repository transaction, and  +path+ is the relative
  # path from the root of the repository to prepend to each filename.
  #
  # If files should be added as part of an existent transaction, the transaction object can be
  # passed as the +txn+ keyword argument, otherwise a new transaction will be created. If the +txn+
  # argument is not nil, the transaction will be commited before returning, otherwise the transaction
  # object will not be commited and so should be commited later on by the caller.
  #
  # If +keep_folder+ is true, the files will be deleted and .gitkeep file will be added to its parent folder if it
  # is not exists in order to keep the folder.
  # If +keep_folder+ is false, all the files will be deleted and .gitkeep file will not be added.
  #
  # Returns a tuple containing a boolean and an array. If the +txn+ argument was nil, the boolean
  # indicates whether the transaction was completed without errors. If the +txn+ argument was not
  # nil, the boolean indicates whether any errors were encountered which mean the caller should not
  # commit the transaction. The array contains any error or warning messages as arrays of arguments
  # (each of which can be passed directly to flash_message from a controller).
  def remove_files(files, user, repo, path: '/', txn: nil, keep_folder: true)
    messages = []

    if txn.nil?
      txn = repo.get_transaction(user.user_name)
      commit_txn = true
    else
      commit_txn = false
    end

    current_path = Pathname.new path
    current_revision = repo.get_latest_revision.revision_identifier

    files.each do |file_path|
      subdir_path, basename = File.split(file_path)
      basename = sanitize_file_name(basename)
      file_path = current_path.join(subdir_path).join(basename)
      file_path = file_path.to_s
      txn.remove(file_path, current_revision.to_s, keep_folder: keep_folder)
    end

    if commit_txn
      success, txn_messages = commit_transaction repo, txn
      [success, messages + txn_messages]
    else
      [true, messages]
    end
  end

  def add_folders(new_folders, user, repo, path: '/', txn: nil)
    messages = []

    if txn.nil?
      txn = repo.get_transaction(user.user_name)
      commit_txn = true
    else
      commit_txn = false
    end

    current_path = Pathname.new path

    new_folders.each do |folder_path|
      folder_path = current_path.join(folder_path)
      folder_path = folder_path.to_s
      txn.add_path(folder_path)
    end

    if commit_txn
      success, txn_messages = commit_transaction repo, txn
      [success, messages + txn_messages]
    else
      [true, messages]
    end
  end

  def remove_folders(folders, user, repo, path: '/', txn: nil)
    messages = []

    if txn.nil?
      txn = repo.get_transaction(user.user_name)
      commit_txn = true
    else
      commit_txn = false
    end

    current_path = Pathname.new path

    current_revision = repo.get_latest_revision.revision_identifier

    dirs = []
    files = []
    folders.each do |folder_path|
      folder_path = current_path.join(folder_path).to_s
      next if dirs.include? folder_path

      repo.get_revision(current_revision.to_s).tree_at_path(folder_path, with_attrs: false).each do |_, obj|
        path = File.join obj.path, obj.name
        if obj.is_a? Repository::RevisionFile
          files << path
        else
          dirs << path
        end
      end
      dirs = dirs.reverse
      dirs << folder_path
    end
    unless files.empty?
      success, file_messages = remove_files(files, user, repo, path: '', txn: txn, keep_folder: false)
      return [success, file_messages] unless success
    end

    dirs.each do |dir|
      if dir == dirs[-1]
        txn.remove_directory(dir, current_revision.to_s, keep_parent_dir: true)
      else
        txn.remove_directory(dir, current_revision.to_s)
      end
    end
    if commit_txn
      success, txn_messages = commit_transaction repo, txn
      [success, messages + txn_messages]
    else
      [true, messages]
    end
  end

  # Helper method that commits a transaction +txn+ in repo +repo+. Returns a boolean and an array
  # where the boolean indicates whether the transaction was commited successfully and an array
  # containing any error or warning messages.
  #
  # Does not attempt to commit the transaction if there are no jobs present to commit.
  def commit_transaction(repo, txn)
    return [false, [:no_files]] unless txn.has_jobs?
    return [true, []] if repo.commit(txn)

    [false, [:txn_conflicts, txn.conflicts]]
  end

  def flash_repository_messages(messages, suppress: nil)
    suppress ||= {}
    messages.each do |msg, other_info|
      next if suppress[msg]
      case msg
      when :too_large
        max_size = (Rails.configuration.max_file_size / 1_000_000.00).round(2)
        flash_message(:error, I18n.t('student.submission.file_too_large',
                                     file_name: other_info,
                                     max_size: max_size))
      when :too_small
        flash_message(:warning, I18n.t('student.submission.empty_file_warning', file_name: other_info))
      when :invalid_filename
        flash_message(:error, I18n.t('student.submission.invalid_file_name'))
      when :extra_files
        flash_message(:error, I18n.t('assignments.upload_file_requirement'))
      when :no_files
        flash_message(:warning, I18n.t('student.submission.no_action_detected'))
      when :txn_conflicts
        flash_message(:error, partial: 'submissions/file_conflicts_list', locals: { conflicts: other_info })
      end
    end
  end
end
