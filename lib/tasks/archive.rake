namespace :markus do
  # Copy directory +src+ to +dest+. If +rev+ is true, instead
  # copy +dest+ to +src+. If +remove_dest+ is true, remove +dest+
  # before copying if it exists.
  def archive_copy(src, dest, rev: false, remove_dest: true)
    dest, src = [src, dest] if rev
    return unless Dir.exist?(src)

    FileUtils.rm_rf(dest) if remove_dest
    FileUtils.cp_r(src, dest)
  end

  # Copy all stateful MarkUs files to +archive_dir+. If +rev+ is
  # true, copy all files from +archive_dir+ to the locations specified
  # by the current MarkUs configuration.
  def copy_archive_files(archive_dir, rev: false)
    # copy repo permission file
    permission_file = archive_dir + 'permission_file'
    archive_copy(Repository::PERMISSION_FILE, permission_file.to_s, rev: rev)
    # copy log files
    log_dir = File.dirname(File.join(::Rails.root, Settings.logging.log_file))
    log_files_dir = archive_dir + 'log_files'
    archive_copy(log_dir, log_files_dir, rev: rev)
    # copy error files
    error_dir = File.dirname(File.join(::Rails.root, Settings.logging.error_file))
    error_files_dir = archive_dir + 'error_dir'
    archive_copy(error_dir, error_files_dir, rev: rev)
    # copy scanned exams
    scanned_exams_dir = archive_dir + 'scanned_exams'
    archive_copy(Settings.scanned_exams.path, scanned_exams_dir, rev: rev)
    # copy starter files
    starter_files_dir = archive_dir + 'starter_files'
    archive_copy(Settings.starter_file.storage, starter_files_dir, rev: rev)
    # copy autotest client dir
    autotest_dir = archive_dir + 'autotest_client'
    archive_copy(Settings.autotest.client_dir, autotest_dir, rev: rev)
    # copy repositories
    repos_dir = archive_dir + 'repos'
    if Settings.repository.type == 'git'
      archive_copy(File.join(Settings.repository.storage, 'bare'), repos_dir, rev: rev)
    elsif Settings.repository.type == 'svn'
      archive_copy(Settings.repository.storage, repos_dir, rev: rev)
    else
      puts "Cannot archive #{Settings.repository.type} type repositories"
    end
  end

  # Copy all stateful MarkUs files to +archive_dir+
  task :archive, [:archive_file] => :environment do |_task, args|
    archive_dir = Pathname.new("#{::Rails.root}/tmp/archive")
    FileUtils.rm_rf(archive_dir)
    FileUtils.mkdir_p(archive_dir)
    puts 'Copying files on disk'
    copy_archive_files(archive_dir)
    zip_file = File.expand_path(args[:archive_file])
    puts "Archiving all repositories and files to #{zip_file}"
    FileUtils.rm_f(zip_file)
    zip_cmd = ['tar', '-czvf', zip_file.to_s, '.']
    Open3.popen3(*zip_cmd, chdir: archive_dir)
  end

  # Copy all stateful MarkUs files from +archive_dir+
  task :unarchive, [:archive_file] => :environment do |_task, args|
    archive_dir = Pathname.new("#{::Rails.root}/tmp/archive")
    FileUtils.rm_rf(archive_dir)
    zip_file = args[:archive_file]
    puts "Unarchiving file #{zip_file}"
    zip_cmd = ['tar', '-xzvf', zip_file.to_s, '-C', archive_dir.to_s]
    Open3.popen3(*zip_cmd)
    puts 'Copying archived files to the app'
    copy_archive_files(archive_dir, rev: true)
  end
end
